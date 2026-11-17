import QtQuick
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import qs.theme
import qs.services
import qs.components

// Battery, Wi-Fi, Bluetooth and volume.
Block {
    id: root

    glass: true

    title: "Status"
    icon: "pulse"

    readonly property var battery: UPower.displayDevice
    readonly property real level: battery.percentage > 1 ? battery.percentage / 100 : battery.percentage
    readonly property bool charging: battery.state === UPowerDeviceState.Charging
    readonly property bool low: level < 0.15 && !charging
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var linked: Bluetooth.devices.values.filter(d => d.connected)

    PwObjectTracker { objects: [root.sink] }
    Component.onCompleted: Net.refresh()
    Timer { interval: 10000; running: true; repeat: true; onTriggered: Net.refresh() }

    function fmt(seconds) {
        const h = Math.floor(seconds / 3600), m = Math.floor((seconds % 3600) / 60)
        return h > 0 ? h + " h " + m + " min" : m + " min"
    }

    readonly property string batteryNote: {
        if (!battery.isPresent) return "No battery"
        if (charging) return battery.timeToFull > 0 ? "Charging · " + fmt(battery.timeToFull) : "Charging"
        if (battery.state === UPowerDeviceState.FullyCharged) return "Fully charged"
        return battery.timeToEmpty > 0 ? fmt(battery.timeToEmpty) + " left" : "On battery"
    }

    Row {
        height: 38
        spacing: 12

        PanelIcon { anchors.verticalCenter: parent.verticalCenter; name: root.charging ? "bolt" : "battery"; size: 30; color: root.low ? Theme.danger : Theme.accent }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.level * 100) + "%"
            color: root.low ? Theme.danger : Theme.text
            font { family: Theme.fontUi; pixelSize: 34; weight: Theme.wHeavy }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 268 - 30 - 12 - 70 - 24
            text: root.batteryNote
            color: Theme.text
            opacity: 0.75
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
    }

    Rectangle {
        y: 54
        width: parent.width
        height: 6
        radius: 3
        color: Theme.lockPill

        Rectangle {
            width: parent.width * Math.max(0.02, Math.min(1, root.level))
            height: parent.height
            radius: 3
            color: root.low ? Theme.danger : Theme.accent
        }
    }

    Row {
        y: parent.height - 20
        width: parent.width
        height: 20
        Chip { width: 118; icon: "wifi"; on: Net.wifiOn; label: Net.wifiOn ? (Net.ssid !== "" ? Net.ssid : "No network") : "Off" }
        Chip {
            width: 78
            icon: "bluetooth"
            on: root.adapter !== null && root.adapter.enabled
            label: root.adapter === null || !root.adapter.enabled ? "Off" : (root.linked.length > 0 ? root.linked[0].name : "On")
        }
        Chip {
            width: 72
            icon: root.sink && root.sink.audio && root.sink.audio.muted ? "mute" : "volume"
            on: root.sink !== null && root.sink.audio !== null && !root.sink.audio.muted
            label: !root.sink || !root.sink.audio ? "—" : (root.sink.audio.muted ? "Muted" : Math.round(root.sink.audio.volume * 100) + "%")
        }
    }
}
