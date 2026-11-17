import QtQuick
import Quickshell.Services.Pipewire
import qs.theme
import qs.services

// Volume, optionally the microphone, and brightness as vertical sliders.
Block {
    id: root

    property bool mic: false
    property bool showValues: false

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool ready: sink !== null && sink.audio !== null
    readonly property bool muted: ready && sink.audio.muted
    readonly property bool micReady: source !== null && source.audio !== null
    readonly property bool micMuted: micReady && source.audio.muted
    readonly property int count: mic ? 3 : 2

    PwObjectTracker { objects: [root.sink, root.source] }
    Component.onCompleted: if (visible) Brightness.refresh()
    onVisibleChanged: if (visible) Brightness.refresh()
    Timer { interval: 3000; running: root.visible; repeat: true; onTriggered: Brightness.refresh() }

    Row {
        anchors.fill: parent
        spacing: 0

        VSlider {
            width: parent.width / root.count
            height: parent.height
            enabled: root.ready
            showValue: root.showValues
            icon: root.muted ? "mute" : "volume"
            iconActive: true
            dimIcon: root.muted
            value: root.ready && !root.muted ? Math.min(1, root.sink.audio.volume) : 0
            onMoved: v => { root.sink.audio.muted = false; root.sink.audio.volume = v }
            onIconClicked: root.sink.audio.muted = !root.sink.audio.muted
        }

        VSlider {
            visible: root.mic
            width: visible ? parent.width / root.count : 0
            height: parent.height
            enabled: root.micReady
            showValue: root.showValues
            icon: root.micMuted ? "micOff" : "mic"
            iconActive: true
            dimIcon: root.micMuted
            value: root.micReady && !root.micMuted ? Math.min(1, root.source.audio.volume) : 0
            onMoved: v => { root.source.audio.muted = false; root.source.audio.volume = v }
            onIconClicked: root.source.audio.muted = !root.source.audio.muted
        }

        VSlider {
            width: parent.width / root.count
            height: parent.height
            enabled: Brightness.available
            showValue: root.showValues
            icon: "sun"
            value: Brightness.value
            onMoved: v => Brightness.set(v)
        }
    }
}
