import QtQuick
import Quickshell.Services.Pipewire
import qs.theme
import qs.components

SettingsPage {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    title: "Sound"

    PwObjectTracker { objects: Pipewire.nodes.values }

    function nodeName(n) { return n.nickname || n.description || n.name }

    component DeviceList: Repeater {
        id: list
        property bool sinks: true
        model: Pipewire.nodes
        delegate: SettingsListRow {
            required property var modelData
            readonly property bool match: !modelData.isStream && modelData.audio !== null && modelData.isSink === list.sinks

            visible: match
            height: match ? implicitHeight : 0
            title: root.nodeName(modelData)
            clickable: true
            active: list.sinks ? Pipewire.defaultAudioSink === modelData : Pipewire.defaultAudioSource === modelData
            subtitle: active ? "In use" : ""
            onClicked: {
                if (list.sinks) Pipewire.preferredDefaultAudioSink = modelData
                else Pipewire.preferredDefaultAudioSource = modelData
            }
        }
    }

    SettingsSection {
        title: "Output"

        SettingsSlider {
            id: outVol
            visible: !!root.sink && !!root.sink.audio
            title: "Volume"
            from: 0; to: 1.5; stepSize: 0.01; displayScale: 100; suffix: " %"
            value: root.sink && root.sink.audio ? root.sink.audio.volume : 0
            onMoved: v => root.sink.audio.volume = v
        }
        SettingsSwitch {
            visible: !!root.sink && !!root.sink.audio
            title: "Muted"
            checked: root.sink && root.sink.audio ? root.sink.audio.muted : false
            onToggled: v => root.sink.audio.muted = v
        }
        DeviceList { sinks: true }
    }

    SettingsSection {
        title: "Input"

        SettingsSlider {
            visible: !!root.source && !!root.source.audio
            title: "Microphone volume"
            from: 0; to: 1.5; stepSize: 0.01; displayScale: 100; suffix: " %"
            value: root.source && root.source.audio ? root.source.audio.volume : 0
            onMoved: v => root.source.audio.volume = v
        }
        SettingsSwitch {
            visible: !!root.source && !!root.source.audio
            title: "Microphone muted"
            checked: root.source && root.source.audio ? root.source.audio.muted : false
            onToggled: v => root.source.audio.muted = v
        }
        DeviceList { sinks: false }
    }
}
