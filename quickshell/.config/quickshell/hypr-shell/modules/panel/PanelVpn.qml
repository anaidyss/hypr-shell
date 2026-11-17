import QtQuick
import qs.theme
import qs.services
import qs.components

// VPN for the left strip: a shield over the ping to the active node; opens the VPN tab of the control center.
Item {
    id: root

    property string screenName: ""

    readonly property var ping: Vpn.ping[Vpn.active] || null
    readonly property bool lost: ping !== null && ping.ms < 0
    readonly property bool bad: lost || (ping !== null && (ping.loss > 10 || ping.ms > 150))
    readonly property bool active: PanelState.isOpen("control") && PanelState.controlFocus === "vpn"
    readonly property color tone: !Vpn.up ? Theme.textOff : (bad ? Theme.danger : (active ? Theme.accent : Theme.text))

    implicitWidth: 32
    implicitHeight: 56

    Binding { target: Vpn; property: "ambient"; value: true }

    PanelIcon {
        anchors { top: parent.top; topMargin: 6; horizontalCenter: parent.horizontalCenter }
        name: Vpn.up ? "shieldCheck" : "shield"
        size: 24
        color: root.tone
    }
    Text {
        anchors { bottom: parent.bottom; bottomMargin: 4; horizontalCenter: parent.horizontalCenter }
        visible: Vpn.up && root.ping !== null
        text: root.lost ? "lost" : Math.round(root.ping ? root.ping.ms : 0)
        color: root.tone
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
    }

    PanelTrigger {
        anchors { fill: parent; margins: -2 }
        kind: "control"
        focusId: "vpn"
        vertical: true
        screenName: root.screenName
    }
}
