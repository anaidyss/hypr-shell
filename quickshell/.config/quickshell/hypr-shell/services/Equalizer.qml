pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// The 10-band equalizer. The audio side is a PipeWire filter-chain smart filter (node `hs_eq`, config in
// pipewire/.config/pipewire/filter-chain.conf.d/hs-eq.conf, run by filter-chain.service); this service keeps the
// gains, presets and the on/off state, and pushes them to the node with pw-cli. Off means every gain at 0 dB,
// which the biquads pass through unchanged.
Singleton {
    id: root

    readonly property string nodeName: "hs_eq"
    readonly property var freqs: ["32", "64", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    readonly property real range: 12

    // Gains in dB per band; the preamp is the 11th value, applied before the bands.
    readonly property var presets: [
        { name: "Flat",       pre: 0,  gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] },
        { name: "Bass boost", pre: -5, gains: [6, 5, 4, 2, 0, 0, 0, 0, 0, 0] },
        { name: "V-shape",    pre: -4, gains: [5, 4, 2, 0, -2, -2, 0, 2, 4, 5] },
        { name: "Treble",     pre: -4, gains: [0, 0, 0, 0, 0, 1, 2, 4, 5, 6] },
        { name: "Vocal",      pre: -3, gains: [-2, -2, -1, 0, 2, 4, 4, 3, 1, 0] },
        { name: "Rock",       pre: -4, gains: [4, 3, 2, 0, -1, -1, 1, 3, 4, 4] },
        { name: "Electronic", pre: -4, gains: [5, 4, 1, 0, -2, 1, 0, 2, 4, 5] },
        { name: "Acoustic",   pre: -2, gains: [3, 2, 1, 1, 2, 2, 3, 3, 2, 1] },
        { name: "Laptop",     pre: -5, gains: [0, 3, 5, 3, 0, -1, 0, 1, 2, 1] },
        { name: "Night",      pre: 0,  gains: [-4, -3, -2, 0, 0, 0, 0, -1, -3, -5] }
    ]

    readonly property var gains: Array.from(cfg.gains)
    readonly property real preamp: cfg.preamp
    readonly property bool enabled: cfg.enabled
    readonly property string preset: cfg.preset

    // The filter node is there when filter-chain.service runs with our config.
    readonly property var node: {
        for (const n of Pipewire.nodes.values) if (n.name === nodeName) return n
        return null
    }
    readonly property bool available: node !== null
    onAvailableChanged: if (available) push.schedule()

    function presetIndex() {
        for (let i = 0; i < presets.length; i++) if (presets[i].name === preset) return i
        return -1
    }

    function setGain(band, db) {
        const g = Array.from(cfg.gains)
        g[band] = Math.round(Math.max(-range, Math.min(range, db)) * 2) / 2
        if (g[band] === cfg.gains[band]) return
        cfg.gains = g
        cfg.preset = ""
        if (!cfg.enabled) cfg.enabled = true
        push.schedule()
    }

    function setPreamp(db) {
        const v = Math.round(Math.max(-range, Math.min(range, db)) * 2) / 2
        if (v === cfg.preamp) return
        cfg.preamp = v
        cfg.preset = ""
        push.schedule()
    }

    function applyPreset(i) {
        const p = presets[(i + presets.length) % presets.length]
        cfg.gains = p.gains.slice()
        cfg.preamp = p.pre
        cfg.preset = p.name
        cfg.enabled = true
        push.schedule()
    }

    function stepPreset(d) {
        const i = presetIndex()
        applyPreset(i < 0 ? (d > 0 ? 0 : presets.length - 1) : i + d)
    }

    function setEnabled(on) {
        if (cfg.enabled === on) return
        cfg.enabled = on
        push.schedule()
    }

    function reset() { applyPreset(0) }

    // pw-cli is one process at a time; changes made while it runs are sent right after it ends.
    QtObject {
        id: push
        property bool again: false

        function schedule() { debounce.restart() }

        function send() {
            if (!root.available) return
            if (proc.running) { again = true; return }
            const on = cfg.enabled
            const parts = ['"pre:Gain"', (on ? cfg.preamp : 0).toFixed(1)]
            for (let i = 0; i < 10; i++) parts.push('"b' + (i + 1) + ':Gain"', (on ? cfg.gains[i] : 0).toFixed(1))
            proc.command = ["pw-cli", "set-param", root.nodeName, "Props", "{ params = [ " + parts.join(" ") + " ] }"]
            proc.running = true
        }
    }

    Timer { id: debounce; interval: 40; onTriggered: push.send() }
    Timer { id: saveTimer; interval: 400; onTriggered: store.writeAdapter() }

    Process {
        id: proc
        onExited: if (push.again) { push.again = false; push.send() }
    }

    IpcHandler {
        target: "equalizer"
        function toggle(): void { root.setEnabled(!root.enabled) }
        function preset(name: string): void {
            for (let i = 0; i < root.presets.length; i++)
                if (root.presets[i].name.toLowerCase() === name.toLowerCase()) { root.applyPreset(i); return }
        }
        function state(): string { return (root.enabled ? "on" : "off") + " " + (root.preset || "custom") }
    }

    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.local/state/hypr-shell/equalizer.json"
        printErrors: false
        watchChanges: false
        onAdapterUpdated: saveTimer.restart()
        adapter: JsonAdapter {
            id: cfg
            property bool enabled: false
            property real preamp: 0
            property list<real> gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            property string preset: "Flat"
        }
        onLoaded: push.schedule()
    }
}
