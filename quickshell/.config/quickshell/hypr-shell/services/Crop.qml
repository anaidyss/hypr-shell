pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// State of the wallpaper crop overlay: the image to wedge and the monitor it is shown on.
Singleton {
    id: root

    property bool active: false
    property string monitor: ""
    property string path: ""
    property int srcW: 0
    property int srcH: 0

    signal snapshotRequested(string path)

    function open(p, w, h) {
        if (active) return
        const m = Hyprland.focusedMonitor
        path = p
        srcW = Math.max(1, w)
        srcH = Math.max(1, h)
        monitor = m ? m.name : ""
        active = true
    }

    function close() {
        active = false
        path = ""
    }

    IpcHandler {
        target: "crop"
        function open(p: string, w: string, h: string): void { root.open(p, parseInt(w), parseInt(h)) }
        function close(): void { root.close() }
        function snapshot(path: string): void { root.snapshotRequested(path) }
    }
}
