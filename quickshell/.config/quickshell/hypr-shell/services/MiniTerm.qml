pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// State and control of the mini terminal window (see bin/hs-miniterm).
Singleton {
    id: root

    // none: no window, idle: shell prompt only, busy: a foreground process is running
    property string state: "none"
    property bool focused: false

    readonly property bool exists: state !== "none"
    readonly property bool busy: state === "busy"
    readonly property string tool: Quickshell.env("HOME") + "/.local/bin/hs-miniterm"

    function show(x, y, w, h) {
        Quickshell.execDetached([tool, "show", String(Math.round(x)), String(Math.round(y)), String(Math.round(w)), String(Math.round(h))])
        pollSoon.restart()
    }

    function hide() {
        Quickshell.execDetached([tool, "hide"])
    }

    function close() {
        if (busy) return
        Quickshell.execDetached([tool, "close"])
        pollSoon.restart()
    }

    Process {
        id: poll
        command: [root.tool, "state"]
        stdout: StdioCollector {
            onStreamFinished: root.state = text.trim() === "" ? "none" : text.trim()
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: if (!poll.running) poll.running = true
    }

    Timer {
        id: pollSoon
        interval: 400
        onTriggered: if (!poll.running) poll.running = true
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activewindow") root.focused = event.data.indexOf("hs-miniterm,") === 0
        }
    }
}
