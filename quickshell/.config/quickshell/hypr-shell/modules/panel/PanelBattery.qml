import QtQuick
import Quickshell.Services.UPower
import qs.theme
import qs.services
import qs.components

// Battery for the left strip: the percentage over a thin bar; opens the Battery tab of the control center.
Item {
    id: root

    property string screenName: ""

    readonly property var battery: UPower.displayDevice
    readonly property real level: battery.percentage > 1 ? battery.percentage / 100 : battery.percentage
    readonly property bool charging: battery.state === UPowerDeviceState.Charging
    readonly property bool low: level < 0.15 && !charging
    readonly property bool active: PanelState.isOpen("control") && PanelState.controlFocus === "battery"
    readonly property color tone: low ? Theme.danger : (charging || active ? Theme.accent : Theme.text)

    implicitWidth: 32
    implicitHeight: 34
    visible: battery.isPresent

    Column {
        anchors.centerIn: parent
        spacing: 3

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(root.level * 100)
            color: root.tone
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 20
            height: 3
            radius: 1.5
            color: Theme.panelTrack

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.level))
                height: parent.height
                radius: parent.radius
                color: root.low ? Theme.danger : Theme.accent
                Behavior on width { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
            }
        }
    }

    PanelTrigger {
        anchors { fill: parent; margins: -2 }
        kind: "control"
        focusId: "battery"
        vertical: true
        screenName: root.screenName
    }
}
