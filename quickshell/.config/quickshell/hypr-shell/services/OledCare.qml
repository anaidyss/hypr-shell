pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.theme

// Care for the OLED panel: the strip drifts by a pixel or two, dims after a while without input and, if asked,
// fades out after a long idle. Values live in theme.json (`oled` group) and are edited in BranchOled.
Singleton {
    id: root

    readonly property int shift: Theme.cfg.oled.shift
    readonly property int dimAfter: Theme.cfg.oled.dimAfter
    readonly property real dimLevel: Theme.cfg.oled.dimLevel
    readonly property int hideAfter: Theme.cfg.oled.hideAfter

    // Idle states come from the compositor (ext-idle-notify), so nothing is polled.
    readonly property bool idleDim: dimMonitor.isIdle
    readonly property bool idleHide: hideMonitor.isIdle
    // A short demonstration of the dimmed state from the settings branch.
    property bool previewing: false

    readonly property bool hidden: idleHide && hideAfter > 0
    readonly property bool dimmed: previewing || (idleDim && dimAfter > 0)
    readonly property string status: hidden ? "Faded out" : (dimmed ? "Dimmed" : "Normal")

    // Opacity of the whole strip and the factor for the frame glow.
    property real stripOpacity: hidden ? 0 : (dimmed ? dimLevel : 1)
    property real glowFactor: hidden ? 0 : (dimmed ? dimLevel * dimLevel : 1)
    Behavior on stripOpacity { NumberAnimation { duration: 2500; easing.type: Easing.InOutQuad } }
    Behavior on glowFactor { NumberAnimation { duration: 2500; easing.type: Easing.InOutQuad } }

    // Drift: a slow walk round the points of a square, scaled by `shift`; whole pixels, glided between.
    property int step: 0
    readonly property var walk: [[0, 0], [1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0], [-1, -1], [0, -1], [1, -1]]
    property real shiftX: shift * walk[step % walk.length][0]
    property real shiftY: shift * walk[step % walk.length][1]
    Behavior on shiftX { NumberAnimation { duration: 6000; easing.type: Easing.InOutQuad } }
    Behavior on shiftY { NumberAnimation { duration: 6000; easing.type: Easing.InOutQuad } }

    Timer {
        interval: 240000
        running: root.shift > 0
        repeat: true
        onTriggered: root.step++
    }

    Timer { id: previewTimer; interval: 8000; onTriggered: root.previewing = false }

    function preview() {
        previewing = true
        previewTimer.restart()
    }

    // For tests and scripts: `qs ipc call oled preview|nudge|state`.
    IpcHandler {
        target: "oled"
        function preview(): void { root.preview() }
        function nudge(): void { root.step++ }
        function state(): string { return root.status + " shift " + root.shiftX + "," + root.shiftY + " strip " + root.stripOpacity.toFixed(2) }
    }

    IdleMonitor {
        id: dimMonitor
        enabled: root.dimAfter > 0
        timeout: Math.max(1, root.dimAfter * 60)
        respectInhibitors: false
    }

    IdleMonitor {
        id: hideMonitor
        enabled: root.hideAfter > 0
        timeout: Math.max(1, root.hideAfter * 60)
        respectInhibitors: false
    }
}
