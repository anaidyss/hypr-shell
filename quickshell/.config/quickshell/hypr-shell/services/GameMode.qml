pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Game mode: one switch that turns off blur, animations, shadows and gaps, selects the performance power profile,
// silences notifications and keeps the screen awake. Whatever was set before is saved and put back when it is turned off.
Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/hypr-shell"
    readonly property bool on: data.on

    // What is applied right now, for the checklist.
    readonly property var parts: [
        { icon: "layers", label: "Blur and shadows off" },
        { icon: "pulse", label: "Animations off" },
        { icon: "box", label: "Gaps off" },
        { icon: "bolt", label: "Performance power profile" },
        { icon: "bellOff", label: "Do not disturb" },
        { icon: "monitor", label: "Screen stays awake" }
    ]

    // Called once at shell start so that the saved state is read, a restart while the mode is on re-applies it
    // and the IPC target exists.
    function start() { store.reload() }

        function toggle() { if (on) disable(); else enable() }

    function enable() {
        if (on || capture.running) return
        capture.running = true
    }

    function disable() {
        if (!on) return
        let prev = {}
        try { prev = JSON.parse(data.prev) } catch (e) {}
        const gi = parseInt(prev.gi || "4")
        const go = (prev.go || "6 2 6 2").split(" ").map(n => parseInt(n))
        hypr('function() hl.config({ animations = { enabled = ' + (prev.anim !== false) + ' }, decoration = { blur = { enabled = '
            + (prev.blur !== false) + ' }, shadow = { enabled = ' + (prev.shadow !== false) + ' } }, general = { gaps_in = ' + gi
            + ', gaps_out = { top = ' + go[0] + ', right = ' + go[1] + ', bottom = ' + go[2] + ', left = ' + go[3] + ' } } }) end')
        if (prev.profile) Quickshell.execDetached(["powerprofilesctl", "set", prev.profile])
        Toasts.dnd = prev.dnd === true
        data.on = false
        store.writeAdapter()
    }

    function hypr(code) { Quickshell.execDetached(["hyprctl", "dispatch", code]) }

    function apply() {
        hypr('function() hl.config({ animations = { enabled = false }, decoration = { blur = { enabled = false }, shadow = { enabled = false } }, '
            + 'general = { gaps_in = 0, gaps_out = 0 } }) end')
        Quickshell.execDetached(["powerprofilesctl", "set", "performance"])
        Toasts.dnd = true
    }

    // Reads what the compositor and the power daemon currently have, so that it can be restored.
    Process {
        id: capture
        command: ["sh", "-c", "a=$(hyprctl -j getoption animations:enabled | jq .bool); b=$(hyprctl -j getoption decoration:blur:enabled | jq .bool); "
            + "s=$(hyprctl -j getoption decoration:shadow:enabled | jq .bool); gi=$(hyprctl -j getoption general:gaps_in | jq -r .css | cut -d' ' -f1); "
            + "go=$(hyprctl -j getoption general:gaps_out | jq -r .css); p=$(powerprofilesctl get 2>/dev/null); "
            + "printf '{\"anim\":%s,\"blur\":%s,\"shadow\":%s,\"gi\":\"%s\",\"go\":\"%s\",\"profile\":\"%s\"}' \"$a\" \"$b\" \"$s\" \"$gi\" \"$go\" \"$p\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let prev = {}
                try { prev = JSON.parse(text) } catch (e) {}
                prev.dnd = Toasts.dnd
                data.prev = JSON.stringify(prev)
                data.on = true
                store.writeAdapter()
                root.apply()
            }
        }
    }

    // Keeps the screen from idling while the mode is on. Named so a stale one left by a crashed shell can be found.
    Process {
        id: inhibit
        running: root.on
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=hypr-shell-game-mode", "--why=Game mode", "--mode=block", "sleep", "infinity"]
    }

    Process {
        id: cleanup
        command: ["pkill", "-f", "who=hypr-shell-game-mode"]
    }

    IpcHandler {
        target: "gamemode"
        function toggle(): void { root.toggle() }
        function enable(): void { root.enable() }
        function disable(): void { root.disable() }
        function state(): string { return root.on ? "on" : "off" }
    }

    FileView {
        id: store
        path: root.stateDir + "/gamemode.json"
        printErrors: false
        adapter: JsonAdapter {
            id: data
            property bool on: false
            property string prev: "{}"
        }
        onLoadFailed: cleanup.running = true
        onLoaded: {
            // A shell restart while the mode was on: the compositor may have been restarted too, so apply it again.
            if (data.on) root.apply()
            else cleanup.running = true
        }
    }
}
