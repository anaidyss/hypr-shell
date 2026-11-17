pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property bool shown: false
    property string kind: "volume"
    property real value: 0
    property bool muted: false

    readonly property var sink: Pipewire.defaultAudioSink
    property bool ready: false

    function show(kind, value, muted) {
        if (kind === "volume" && (PanelState.isOpen("control") || PanelState.isOpen("dashboard"))) return
        root.kind = kind
        root.value = value
        root.muted = muted
        shown = true
        hideTimer.restart()
    }

    PwObjectTracker { objects: [root.sink] }

    onSinkChanged: {
        ready = false
        readyTimer.restart()
    }

    Connections {
        target: root.sink && root.sink.audio ? root.sink.audio : null
        ignoreUnknownSignals: true
        function onVolumeChanged() { if (root.ready) root.show("volume", root.sink.audio.volume, root.sink.audio.muted) }
        function onMutedChanged() { if (root.ready) root.show("volume", root.sink.audio.volume, root.sink.audio.muted) }
    }

    Timer { id: readyTimer; interval: 1500; onTriggered: root.ready = true }
    Timer { id: hideTimer; interval: 1600; onTriggered: root.shown = false }

    Process {
        id: brightnessProc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",")
                if (f.length >= 4) root.show("brightness", parseInt(f[3]) / 100, false)
            }
        }
    }

    IpcHandler {
        target: "osd"
        function brightness(): void { brightnessProc.running = true }
    }
}
