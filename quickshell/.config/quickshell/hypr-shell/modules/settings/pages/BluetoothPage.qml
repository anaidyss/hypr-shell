import QtQuick
import Quickshell.Bluetooth
import qs.theme
import qs.components

SettingsPage {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter

    title: "Bluetooth"

    Text {
        visible: !root.adapter
        text: "No Bluetooth adapter found"
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
    }

    SettingsSection {
        visible: !!root.adapter
        title: "Adapter"

        SettingsSwitch {
            title: "Bluetooth"
            checked: root.adapter ? root.adapter.enabled : false
            onToggled: v => root.adapter.enabled = v
        }
        SettingsSwitch {
            title: "Scan for devices"
            description: "Turn on when you need to connect a new device"
            checked: root.adapter ? root.adapter.discovering : false
            onToggled: v => root.adapter.discovering = v
        }
    }

    component DeviceRow: SettingsListRow {
        id: row

        required property var device

        title: device.name || device.address
        active: device.connected
        subtitle: {
            const parts = []
            if (device.connected) parts.push("Connected")
            else if (device.paired) parts.push("Paired")
            if (device.batteryAvailable) parts.push(Math.round(device.battery * (device.battery > 1 ? 1 : 100)) + " %")
            return parts.join("  ·  ")
        }

        SettingsButton {
            visible: !row.device.paired
            text: row.device.pairing ? "Pairing…" : "Pair"
            primary: true
            onClicked: row.device.pair()
        }
        SettingsButton {
            visible: row.device.paired && !row.device.connected
            text: "Connect"
            primary: true
            onClicked: row.device.connect()
        }
        SettingsButton {
            visible: row.device.connected
            text: "Disconnect"
            onClicked: row.device.disconnect()
        }
        SettingsButton {
            visible: row.device.paired
            text: "Forget"
            danger: true
            onClicked: row.device.forget()
        }
    }

    SettingsSection {
        visible: !!root.adapter && root.adapter.enabled
        title: "Devices"

        Repeater {
            model: root.adapter ? root.adapter.devices : null
            delegate: DeviceRow {
                required property var modelData
                device: modelData
                visible: modelData.paired
            }
        }
    }

    SettingsSection {
        visible: !!root.adapter && root.adapter.enabled && root.adapter.discovering
        title: "Available"

        Repeater {
            model: root.adapter ? root.adapter.devices : null
            delegate: DeviceRow {
                required property var modelData
                device: modelData
                visible: !modelData.paired
            }
        }
    }
}
