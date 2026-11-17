import QtQuick
import Quickshell.Networking
import qs.theme
import qs.components

SettingsPage {
    title: "Network"

    SettingsSection {
        title: "Wireless"

        SettingsSwitch {
            title: "Wi-Fi"
            description: Networking.wifiHardwareEnabled ? "" : "Disabled by hardware switch"
            checked: Networking.wifiEnabled
            onToggled: v => Networking.wifiEnabled = v
        }
    }

    Repeater {
        model: Networking.devices
        delegate: Loader {
            required property var modelData
            width: parent.width
            active: modelData.type === DeviceType.Wifi && Networking.wifiEnabled
            sourceComponent: WifiDeviceSection { device: modelData }
        }
    }
}
