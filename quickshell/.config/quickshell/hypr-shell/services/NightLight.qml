pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.theme

// Night light: warms the whole screen with a Hyprland screen shader (no extra tool needed). Hyprland drops runtime
// options on a config reload, so the shader is applied again after `configreloaded`.
// Schedule: manual only, fixed hours, or from sunset to sunrise (taken from the weather service). On the sunset
// schedule the light fades in over ten minutes at sunset and fades out the same way at sunrise: the screen shader is
// rewritten every ten seconds with a temperature that moves a few dozen kelvin per step, which nobody notices.
Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/hypr-shell"
    // The shader file alternates between two names: a new path is a changed option, so Hyprland surely reloads it.
    property bool flip: false
    readonly property string shaderPath: stateDir + (flip ? "/nightlight-b.frag" : "/nightlight.frag")

    // Stored in nightlight.json. `schedule` is "manual", "hours" or "sun".
    readonly property bool on: cfg.on
    readonly property int kelvin: cfg.kelvin
    readonly property string schedule: cfg.schedule
    readonly property int fromMinute: cfg.fromMinute
    readonly property int toMinute: cfg.toMinute
    property bool loaded: false

    readonly property int minKelvin: 2500
    readonly property int maxKelvin: 6500
    // Fade of the scheduled switch: how far the screen is warmed, 0 untouched to 1 at the chosen temperature.
    property int rampMs: 10 * 60 * 1000
    property real level: 1
    property real rampFrom: 1
    property real rampTo: 1
    property double rampStart: 0
    readonly property bool ramping: rampTimer.running
    // The temperature on the screen right now (6500 K is a neutral screen).
    readonly property int shownKelvin: Math.round(maxKelvin + (kelvin - maxKelvin) * level)
    readonly property string warmth: kelvin < 3200 ? "Candle" : (kelvin < 4200 ? "Warm" : (kelvin < 5400 ? "Soft" : "Mild"))

    function start() { settings.reload() }

    function clock(minute) {
        const h = Math.floor(minute / 60) % 24, m = minute % 60
        return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
    }

    function parseClock(s) {
        const m = /^(\d{1,2}):(\d{2})/.exec(s || "")
        return m ? (+m[1]) * 60 + (+m[2]) : -1
    }

    // Tanner Helland's blackbody approximation, as multipliers 0..1.
    function tint(k) {
        const t = k / 100
        let r = t <= 66 ? 255 : 329.698727446 * Math.pow(t - 60, -0.1332047592)
        let g = t <= 66 ? 99.4708025861 * Math.log(t) - 161.1195681661 : 288.1221695283 * Math.pow(t - 60, -0.0755148492)
        let b = t >= 66 ? 255 : (t <= 19 ? 0 : 138.5177312231 * Math.log(t - 10) - 305.0447927307)
        const c = v => Math.max(0, Math.min(255, v)) / 255
        return [c(r), c(g), c(b)]
    }

    function shader() {
        const [r, g, b] = tint(shownKelvin)
        return "#version 300 es\nprecision highp float;\nin vec2 v_texcoord;\nuniform sampler2D tex;\nlayout(location = 0) out vec4 fragColor;\n"
            + "void main() {\n    vec4 c = texture(tex, v_texcoord);\n    fragColor = vec4(c.rgb * vec3(" + r.toFixed(4) + ", " + g.toFixed(4) + ", " + b.toFixed(4) + "), c.a);\n}\n"
    }

    function apply() {
        if (!loaded) return
        if (on) {
            flip = !flip
            Quickshell.execDetached(["sh", "-c", "printf %s \"$0\" > \"$1\"", shader(), shaderPath])
            applyTimer.restart()
        } else {
            Quickshell.execDetached(["hyprctl", "dispatch", "function() hl.config({ decoration = { screen_shader = \"\" } }) end"])
        }
    }

    // A manual or fixed-hours switch is instant; only the sunset schedule fades (see fadeTo).
    function setOn(v) {
        rampTimer.stop()
        level = 1
        if (on === v) return
        cfg.on = v
        save()
        apply()
    }

    // Fades from `from` to `to` (0..1) at the pace of a full fade over rampMs; `on` stays true until a fade-out ends.
    function fadeTo(to, from) {
        if (!on) { cfg.on = true; save() }
        rampFrom = from
        rampTo = to
        rampStart = Date.now()
        level = from
        rampTimer.restart()
        apply()
    }

    function rampStep() {
        const span = Math.abs(rampTo - rampFrom) * rampMs
        const f = span <= 0 ? 1 : Math.min(1, (Date.now() - rampStart) / span)
        level = rampFrom + (rampTo - rampFrom) * f
        if (f >= 1) {
            rampTimer.stop()
            rampMs = 10 * 60 * 1000
            if (rampTo <= 0) { cfg.on = false; save(); level = 1 }
        }
        apply()
    }

    function setKelvin(k) {
        cfg.kelvin = Math.max(minKelvin, Math.min(maxKelvin, Math.round(k / 100) * 100))
        save()
        if (on) apply()
    }

    function setSchedule(s) {
        cfg.schedule = s
        lastInside = -1
        save()
        tick()
    }

    function setFrom(m) { cfg.fromMinute = (m + 1440) % 1440; save(); lastInside = -1; tick() }
    function setTo(m) { cfg.toMinute = (m + 1440) % 1440; save(); lastInside = -1; tick() }

    // Window of the schedule in minutes of the day, or null when manual or unknown.
    function window() {
        if (schedule === "hours") return [fromMinute, toMinute]
        if (schedule === "sun") {
            Weather.ensure()
            const d = Weather.has && Weather.data ? Weather.data : null
            const rise = d ? parseClock(d.sunrise) : -1
            const set = d ? parseClock(d.sunset) : -1
            return rise >= 0 && set >= 0 ? [set, rise] : null
        }
        return null
    }

    property int lastInside: -1

    // Only the edges of the window switch the light, so a manual change stays until the next edge.
    function tick() {
        const w = window()
        if (!w) return
        const now = new Date()
        const m = now.getHours() * 60 + now.getMinutes()
        const inside = w[0] <= w[1] ? (m >= w[0] && m < w[1]) : (m >= w[0] || m < w[1])
        if (lastInside === (inside ? 1 : 0)) return
        const first = lastInside < 0
        lastInside = inside ? 1 : 0
        if (schedule !== "sun") { setOn(inside); return }

        // Sunset schedule: minutes since the edge decide where in the fade we are (a restart in the middle of it
        // carries on from there, a restart long after it jumps to the end).
        const since = (m - (inside ? w[0] : w[1]) + 1440) % 1440
        const done = since >= rampMs / 60000
        if (done) { setOn(inside); return }
        const frac = since / (rampMs / 60000)
        if (inside) fadeTo(1, first || !on ? frac : Math.max(level, frac))
        else if (on) fadeTo(0, first ? 1 - frac : Math.min(level, 1 - frac))
    }

    function save() { if (loaded) saveTimer.restart() }

    Timer { id: saveTimer; interval: 300; onTriggered: settings.writeAdapter() }
    Timer { id: rampTimer; interval: Math.max(1000, Math.min(10000, root.rampMs / 60)); repeat: true; onTriggered: root.rampStep() }
    Timer { id: applyTimer; interval: 60; onTriggered: root.setShader() }
    Timer { interval: 30000; running: root.loaded && root.schedule !== "manual"; repeat: true; onTriggered: root.tick() }

    function setShader() {
        Quickshell.execDetached(["hyprctl", "dispatch", "function() hl.config({ decoration = { screen_shader = \"" + shaderPath + "\" } }) end"])
    }

    IpcHandler {
        target: "nightlight"
        function toggle(): void { root.setOn(!root.on) }
        function on(): void { root.setOn(true) }
        function off(): void { root.setOn(false) }
        function temperature(kelvin: int): void { root.setKelvin(kelvin) }
        function schedule(mode: string): void { root.setSchedule(mode) }
        // Starts a fade by hand (for scripts and tests); `seconds` <= 0 means the usual ten minutes.
        function fade(enable: bool, seconds: int): void {
            root.rampMs = seconds > 0 ? seconds * 1000 : 10 * 60 * 1000
            if (enable) root.fadeTo(1, 0)
            else if (root.on) root.fadeTo(0, root.level)
        }
        function state(): string { return (root.on ? "on" : "off") + " level " + root.level.toFixed(2) + " shown " + root.shownKelvin + " K" + (root.ramping ? " ramping" : "") }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded" && root.on) reapply.restart()
        }
    }
    Timer { id: reapply; interval: 700; onTriggered: root.apply() }

    FileView {
        id: settings
        path: root.stateDir + "/nightlight.json"
        printErrors: false
        onLoaded: { root.loaded = true; root.tick(); if (!root.ramping) root.apply() }
        onLoadFailed: { root.loaded = true; root.tick() }
        adapter: JsonAdapter {
            id: cfg
            property bool on: false
            property int kelvin: 3800
            property string schedule: "manual"
            property int fromMinute: 21 * 60
            property int toMinute: 6 * 60 + 30
        }
    }
}
