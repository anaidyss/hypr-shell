pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.theme

// State of the Stealth Cast overlay: picks what to stream (window / region / screen) and which
// regions to black out, then drives the headless OBS instance through hs-stealthcast.
Singleton {
    id: root

    property bool active: false
    property bool streaming: false
    property string monitor: ""

    property string sourceMode: "screen"
    property var regions: []
    property var pendingWindow: null
    property string castError: ""

    // Captured from the focused monitor when the overlay opens, so regions and the scene use the
    // same physical coordinates even if focus moves later.
    property real mScale: 1
    property int mW: 1920
    property int mH: 1080

    signal snapshotRequested(string path)

    function open() {
        if (active) return
        const m = Hyprland.focusedMonitor
        if (!m) return
        monitor = m.name
        mScale = m.lastIpcObject && m.lastIpcObject.scale ? m.lastIpcObject.scale : 1
        mW = m.lastIpcObject ? m.lastIpcObject.width : 1920
        mH = m.lastIpcObject ? m.lastIpcObject.height : 1080
        regions = []
        sourceMode = "screen"
        active = true
        PanelState.close()
        Toasts.dismiss()
    }

    function close() {
        active = false
        monitor = ""
    }

    // Region coordinates arrive in logical pixels; the overlay scales them to physical ones
    // before handing them to OBS, whose canvas is physical.
    function addRegion(x, y, w, h) {
        regions = regions.concat([{
            id: "b" + regions.length,
            kind: "blackout",
            x: Math.round(x * mScale), y: Math.round(y * mScale),
            w: Math.round(w * mScale), h: Math.round(h * mScale)
        }])
    }

    function clearRegions() { regions = [] }

    function setMode(name) { sourceMode = name }

    function buildScene() {
        sceneProc.command = ["hs-stealthcast", "scene", JSON.stringify({ screen: { w: mW, h: mH }, regions: regions })]
        sceneProc.running = true
    }

    function commit() {
        buildScene()
    }

    function start() { startProc.command = ["hs-stealthcast", "start"]; startProc.running = true }
    function stop() { stopProc.command = ["hs-stealthcast", "stop"]; stopProc.running = true }
    function status() { statusProc.command = ["hs-stealthcast", "status"]; statusProc.running = true }
    function ping() { pingProc.command = ["hs-stealthcast", "ping"]; pingProc.running = true }

    Process {
        id: sceneProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.indexOf('"ok": true') >= 0) root.start()
                else root.castError = text
            }
        }
    }

    Process {
        id: startProc
        stdout: StdioCollector {
            onStreamFinished: { root.streaming = text.indexOf('"active": true') >= 0 }
        }
    }

    Process {
        id: stopProc
        stdout: StdioCollector {
            onStreamFinished: { root.streaming = false }
        }
    }

    Process {
        id: statusProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.indexOf('"active": false') >= 0) root.streaming = false
                else if (text.indexOf('"active": true') >= 0) root.streaming = true
            }
        }
    }

    Process {
        id: pingProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.castError = text.indexOf('"ok": false') >= 0 ? text : ""
            }
        }
    }

    IpcHandler {
        target: "stealthcast"
        function open(): void { root.open() }
        function close(): void { root.close() }
        function start(): void { root.commit() }
        function stop(): void { root.stop() }
        function mode(name: string): void { root.setMode(name) }
        function region(x: int, y: int, w: int, h: int): void { root.addRegion(x, y, w, h) }
        function clear(): void { root.clearRegions() }
        function ping(): void { root.status() }
        function snapshot(path: string): void { root.snapshotRequested(path) }
    }
}
