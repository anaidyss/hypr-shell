pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Countdown, stopwatch and pomodoro. All three keep absolute timestamps in ~/.local/state/hypr-shell/timer.json, so they
// keep running while the menu is closed and across shell restarts. The service ticks once a second in the background and
// ten times a second while the menu is on screen (`watch`).
Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/hypr-shell"
    readonly property string alarmSound: "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"

    property bool started: false
    property bool watch: false
    property real now: Date.now()
    // Set when something ran out; cleared by `ack()` (opening the menu) or by starting again.
    property bool finished: false
    property string finishedText: ""

    // Stored values
    readonly property string mode: cfg.mode
    readonly property real cdTotal: cfg.cdTotal
    readonly property bool cdRunning: cfg.cdEnd > 0
    readonly property real cdRemaining: cfg.cdEnd > 0 ? Math.max(0, cfg.cdEnd - now) : cfg.cdLeft
    readonly property bool swRunning: cfg.swStart > 0
    readonly property real swElapsed: cfg.swStart > 0 ? cfg.swAcc + Math.max(0, now - cfg.swStart) : cfg.swAcc
    readonly property string pmPhase: cfg.pmPhase
    readonly property int pmRound: cfg.pmRound
    readonly property bool pmRunning: cfg.pmEnd > 0
    readonly property real pmTotal: cfg.pmTotal
    readonly property real pmRemaining: cfg.pmEnd > 0 ? Math.max(0, cfg.pmEnd - now) : cfg.pmLeft
    readonly property int pmFocus: cfg.pmFocus
    readonly property int pmBreak: cfg.pmBreak
    readonly property int pmLong: cfg.pmLong

    readonly property bool running: cdRunning || swRunning || pmRunning

    // Text for a badge on the strip: the nearest running countdown or pomodoro, else the stopwatch.
    readonly property string remainingText: {
        const left = []
        if (cdRunning) left.push(cdRemaining)
        if (pmRunning) left.push(pmRemaining)
        if (left.length > 0) return fmt(Math.min.apply(null, left))
        return swRunning ? fmt(swElapsed, true) : ""
    }

    function fmt(ms, floor) {
        const s = floor ? Math.floor(ms / 1000) : Math.ceil(ms / 1000)
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), sec = s % 60
        const two = v => (v < 10 ? "0" : "") + v
        return h > 0 ? h + ":" + two(m) + ":" + two(sec) : m + ":" + two(sec)
    }

    function start() { file.reload() }
    function ack() { finished = false }
    function setMode(m) { cfg.mode = m; save() }

    function phaseMs(phase) {
        return (phase === "focus" ? pmFocus : (phase === "long" ? pmLong : pmBreak)) * 60000
    }

    // ---- countdown
    function cdToggle() {
        now = Date.now()
        finished = false
        if (cfg.cdEnd > 0) {
            cfg.cdLeft = Math.max(0, cfg.cdEnd - now)
            cfg.cdEnd = 0
        } else {
            if (cfg.cdLeft <= 0) cfg.cdLeft = cfg.cdTotal
            cfg.cdEnd = now + cfg.cdLeft
        }
        save()
    }

    function cdSet(ms) {
        now = Date.now()
        cfg.cdTotal = Math.max(1000, ms)
        if (cfg.cdEnd > 0) cfg.cdEnd = now + cfg.cdTotal
        else cfg.cdLeft = cfg.cdTotal
        finished = false
        save()
    }

    function cdAdd(ms) {
        now = Date.now()
        cfg.cdTotal = Math.max(1000, cfg.cdTotal + ms)
        if (cfg.cdEnd > 0) cfg.cdEnd += ms
        else cfg.cdLeft = Math.max(0, cfg.cdLeft + ms)
        save()
    }

    function cdReset() {
        cfg.cdEnd = 0
        cfg.cdLeft = cfg.cdTotal
        finished = false
        save()
    }

    // ---- stopwatch
    function swToggle() {
        now = Date.now()
        if (cfg.swStart > 0) {
            cfg.swAcc += now - cfg.swStart
            cfg.swStart = 0
        } else {
            cfg.swStart = now
        }
        save()
    }

    function swReset() {
        cfg.swAcc = 0
        cfg.swStart = 0
        save()
    }

    // ---- pomodoro
    function pmToggle() {
        now = Date.now()
        finished = false
        if (cfg.pmEnd > 0) {
            cfg.pmLeft = Math.max(0, cfg.pmEnd - now)
            cfg.pmEnd = 0
        } else {
            if (cfg.pmLeft <= 0) cfg.pmLeft = cfg.pmTotal
            cfg.pmEnd = now + cfg.pmLeft
        }
        save()
    }

    function pmEnter(phase, run) {
        now = Date.now()
        cfg.pmPhase = phase
        cfg.pmTotal = phaseMs(phase)
        cfg.pmLeft = cfg.pmTotal
        cfg.pmEnd = run ? now + cfg.pmTotal : 0
    }

    function pmNextPhase() {
        if (cfg.pmPhase !== "focus") return "focus"
        return (cfg.pmRound + 1) % 4 === 0 ? "long" : "break"
    }

    // Skips to the next phase (counting a focus phase as done) and keeps running if it was.
    function pmSkip() {
        const next = pmNextPhase()
        if (cfg.pmPhase === "focus") cfg.pmRound += 1
        pmEnter(next, cfg.pmEnd > 0)
        save()
    }

    function pmReset() {
        cfg.pmRound = 0
        pmEnter("focus", false)
        finished = false
        save()
    }

    function pmSetLength(which, minutes) {
        const v = Math.max(1, Math.min(180, minutes))
        if (which === "focus") cfg.pmFocus = v
        else if (which === "break") cfg.pmBreak = v
        else cfg.pmLong = v
        if (cfg.pmEnd === 0 && cfg.pmPhase === (which === "break" ? "break" : which)) pmEnter(cfg.pmPhase, false)
        save()
    }

    // ---- ticking
    function notify(title, body) {
        finished = true
        finishedText = title
        Quickshell.execDetached(["notify-send", "-a", "Timer", title, body])
        Quickshell.execDetached(["sh", "-c", "pw-play '" + alarmSound + "' 2>/dev/null || canberra-gtk-play -i alarm-clock-elapsed 2>/dev/null"])
    }

    function tick() {
        now = Date.now()
        if (cfg.cdEnd > 0 && now >= cfg.cdEnd) {
            cfg.cdEnd = 0
            cfg.cdLeft = 0
            notify("Timer finished", fmt(cfg.cdTotal) + " countdown")
            save()
        }
        if (cfg.pmEnd > 0 && now >= cfg.pmEnd) {
            const was = cfg.pmPhase
            const next = pmNextPhase()
            if (was === "focus") cfg.pmRound += 1
            pmEnter(next, true)
            notify(was === "focus" ? "Focus done" : "Break over",
                was === "focus" ? (next === "long" ? "Time for a long break, " + pmLong + " min" : "Take a break, " + pmBreak + " min") : "Back to focus, " + pmFocus + " min")
            save()
        }
    }

    function save() { if (started) saveTimer.restart() }

    Timer { id: saveTimer; interval: 300; onTriggered: file.writeAdapter() }
    Timer {
        interval: root.watch ? 100 : 1000
        running: root.started && (root.watch || root.running)
        repeat: true
        triggeredOnStart: true
        onTriggered: root.tick()
    }

    IpcHandler {
        target: "timer"
        // Starts the countdown with the given length in minutes (a fraction works: 0.5 is thirty seconds).
        function start(minutes: real): void {
            cfg.mode = "countdown"
            root.cdSet(minutes * 60000)
            if (cfg.cdEnd === 0) root.cdToggle()
        }
        function toggle(): void { if (cfg.mode === "stopwatch") root.swToggle(); else if (cfg.mode === "pomodoro") root.pmToggle(); else root.cdToggle() }
        function mode(name: string): void { root.setMode(name) }
        function reset(): void { root.cdReset(); root.swReset(); root.pmReset() }
        function state(): string { return JSON.stringify({ mode: cfg.mode, running: root.running, text: root.remainingText, finished: root.finished }) }
    }

    FileView {
        id: file
        path: root.stateDir + "/timer.json"
        printErrors: false
        onLoaded: { root.started = true; root.tick() }
        onLoadFailed: { root.started = true }
        adapter: JsonAdapter {
            id: cfg
            property string mode: "countdown"
            property real cdTotal: 300000
            property real cdLeft: 300000
            property real cdEnd: 0
            property real swAcc: 0
            property real swStart: 0
            property string pmPhase: "focus"
            property int pmRound: 0
            property int pmFocus: 25
            property int pmBreak: 5
            property int pmLong: 15
            property real pmTotal: 1500000
            property real pmLeft: 1500000
            property real pmEnd: 0
        }
    }
}
