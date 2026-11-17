pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// Color picker and paint mode: pick a color from the screen (hyprpicker), keep a history of picked colors, and
// paint a picked color onto a part of the interface (a role of the theme, see Theme.overrides). Every change
// can be undone at once.
Singleton {
    id: root

    readonly property var roles: [
        { id: "accent", label: "Accent", hint: "Sliders, icons, current day" },
        { id: "frame", label: "Frame", hint: "The screen frame and the strip" },
        { id: "card", label: "Cards", hint: "Blocks with a caption" },
        { id: "tile", label: "Tiles", hint: "Tiles inside blocks" },
        { id: "pill", label: "Pills", hint: "Groups on the strip" },
        { id: "selected", label: "Selected", hint: "The current tab" },
        { id: "text", label: "Text", hint: "Text and icons" }
    ]

    property string current: ""
    property var history: []
    property bool picking: false
    // Paint mode: the next click on a part of the shell applies `current` to it.
    property bool painting: false
    // The role under the pointer in paint mode (set by PaintLayer), for the HUD.
    property string hoverRole: ""
    property string flash: ""

    // Scripting and testing aid: asks the paint layers to treat (x, y) as the pointer position.
    signal probeRequested(real x, real y)

    // Each entry is one undoable change: [{ role, prev }].
    property var undoStack: []
    readonly property bool canUndo: undoStack.length > 0
    readonly property bool hasOverrides: roles.some(r => valueOf(r.id) !== "")

    function valueOf(role) { return Theme.cfg.overrides[role] }

    function labelOf(role) {
        const r = roles.find(x => x.id === role)
        return r ? r.label : ""
    }

    function rgb(hex) {
        if (!/^#[0-9a-f]{6}$/i.test(hex)) return ""
        return "rgb(" + parseInt(hex.slice(1, 3), 16) + ", " + parseInt(hex.slice(3, 5), 16) + ", " + parseInt(hex.slice(5, 7), 16) + ")"
    }

    function copy(text) {
        Quickshell.execDetached(["wl-copy", text])
        flash = text
        flashTimer.restart()
    }

    Timer { id: flashTimer; interval: 1500; onTriggered: root.flash = "" }

    function select(hex) {
        current = hex
        history = [hex].concat(history.filter(h => h !== hex)).slice(0, 14)
        store.setText(JSON.stringify({ history: history }))
    }

    function apply(role, hex) {
        const c = hex || current
        if (c === "" || valueOf(role) === c) return
        undoStack = undoStack.concat([[{ role: role, prev: valueOf(role) }]])
        Theme.set("overrides", role, c)
    }

    function clear(role) {
        if (valueOf(role) === "") return
        undoStack = undoStack.concat([[{ role: role, prev: valueOf(role) }]])
        Theme.set("overrides", role, "")
    }

    function resetAll() {
        const changes = roles.filter(r => valueOf(r.id) !== "").map(r => ({ role: r.id, prev: valueOf(r.id) }))
        if (changes.length === 0) return
        undoStack = undoStack.concat([changes])
        for (const c of changes) Theme.set("overrides", c.role, "")
    }

    function undo() {
        if (undoStack.length === 0) return
        const last = undoStack[undoStack.length - 1]
        undoStack = undoStack.slice(0, -1)
        for (const c of last) Theme.set("overrides", c.role, c.prev)
    }

    function startPaint(hex) {
        if (hex) select(hex)
        if (current !== "") painting = true
    }

    function stopPaint() {
        painting = false
        hoverRole = ""
    }

    function pick() {
        if (picking) return
        picking = true
        pickProc.running = true
    }

    Process {
        id: pickProc
        command: ["hyprpicker", "-f", "hex", "-l", "-q"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.picking = false
                const m = text.match(/#[0-9a-fA-F]{6}/)
                if (m) {
                    root.select(m[0].toLowerCase())
                    root.painting = true
                }
            }
        }
    }

    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.local/state/hypr-shell/picker.json"
        printErrors: false
        onLoaded: {
            try { root.history = JSON.parse(text()).history || [] } catch (e) {}
            if (root.current === "" && root.history.length > 0) root.current = root.history[0]
        }
    }

    IpcHandler {
        target: "picker"
        function pick(): void { root.pick() }
        function paint(hex: string): void { root.startPaint(hex) }
        function apply(role: string): void { root.apply(role, "") }
        function clear(role: string): void { root.clear(role) }
        function probe(x: int, y: int): string {
            root.probeRequested(x, y)
            return root.hoverRole
        }
        function done(): void { root.stopPaint() }
        function undo(): void { root.undo() }
        function reset(): void { root.resetAll() }
    }
}
