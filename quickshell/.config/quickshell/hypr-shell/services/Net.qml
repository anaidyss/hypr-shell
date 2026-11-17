pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    readonly property bool wifiOn: Networking.wifiEnabled
    property string ssid: ""

    function refresh() {
        let name = ""
        for (const d of Networking.devices.values) {
            if (d.type !== DeviceType.Wifi) continue
            for (const n of d.networks.values) {
                if (n.connected) { name = n.name; break }
            }
        }
        ssid = name
    }

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled
    }

    Instantiator {
        model: Networking.devices
        onObjectAdded: root.refresh()
        onObjectRemoved: root.refresh()
        delegate: QtObject {
            required property var modelData
            property Instantiator networks: Instantiator {
                model: modelData.networks
                onObjectAdded: root.refresh()
                onObjectRemoved: root.refresh()
                delegate: QtObject {
                    required property var modelData
                    property bool connected: modelData.connected
                    onConnectedChanged: root.refresh()
                }
            }
        }
    }

    Component.onCompleted: refresh()
}
