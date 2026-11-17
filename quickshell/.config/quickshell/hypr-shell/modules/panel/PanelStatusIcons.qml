import QtQuick
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import qs.theme
import qs.services
import qs.components

// Wi-Fi, Bluetooth, volume and battery, each opening its own branch; a row on the bar or a column on the left strip.
Grid {
    id: root

    property bool vertical: false
    property real iconSize: 18
    property string screenName: ""

    readonly property var battery: UPower.displayDevice
    readonly property real level: battery.percentage > 1 ? battery.percentage / 100 : battery.percentage
    readonly property bool charging: battery.state === UPowerDeviceState.Charging
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var btAdapter: Bluetooth.defaultAdapter

    columns: vertical ? 1 : 5
    spacing: vertical ? 10 : 12
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter

    PwObjectTracker { objects: [root.sink] }

    component StatusIcon: Item {
        id: cell

        property string focusId: ""
        property string icon: ""
        property bool on: true
        property bool danger: false

        width: root.iconSize
        height: root.iconSize
        readonly property bool active: cell.focusId !== "" && PanelState.isOpen("control") && PanelState.controlFocus === cell.focusId

        PanelIcon {
            anchors.centerIn: parent
            name: cell.icon
            size: root.iconSize
            color: cell.active ? Theme.accent : (cell.danger ? Theme.danger : (cell.on ? Theme.textDim : Qt.alpha(Theme.textDim, 0.35)))
        }
        PanelTrigger {
            anchors { fill: parent; margins: -8 }
            kind: "control"
            focusId: cell.focusId
            vertical: root.vertical
            screenName: root.screenName
        }
    }

    StatusIcon { focusId: "wifi"; icon: "wifi"; on: Net.wifiOn }
    StatusIcon { focusId: "bluetooth"; icon: "bluetooth"; on: root.btAdapter ? root.btAdapter.enabled : false }
    StatusIcon { focusId: "sound"; icon: root.sink && root.sink.audio && root.sink.audio.muted ? "mute" : "volume"; on: true }
    StatusIcon { focusId: "battery"; icon: root.charging ? "bolt" : "battery"; on: true; danger: root.level < 0.15 && !root.charging }

    Text {
        visible: !root.vertical
        text: Math.round(root.level * 100)
        color: root.level < 0.15 && !root.charging ? Theme.danger : Theme.textDim
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
    }
}
