import QtQuick
import Quickshell.Networking
import qs.theme

SettingsSection {
    id: root

    required property var device

    title: "Networks · " + device.name

    Binding { target: root.device; property: "scannerEnabled"; value: true }

    Repeater {
        model: root.device.networks
        delegate: WifiNetworkRow {
            required property var modelData
            network: modelData
            visible: modelData.known
        }
    }
    Repeater {
        model: root.device.networks
        delegate: WifiNetworkRow {
            required property var modelData
            network: modelData
            visible: !modelData.known
        }
    }
}
