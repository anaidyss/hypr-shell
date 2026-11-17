import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.components

Item {
    id: root

    implicitWidth: 210
    implicitHeight: 240

    readonly property var actions: [
        { icon: "lock", label: "Lock", cmd: ["hs-lock"] },
        { icon: "logout", label: "Log out", cmd: ["sh", "-c", "loginctl terminate-session \"$XDG_SESSION_ID\""] },
        { icon: "moon", label: "Sleep", cmd: ["systemctl", "suspend"] },
        { icon: "restart", label: "Restart", cmd: ["systemctl", "reboot"] },
        { icon: "power", label: "Shut down", cmd: ["systemctl", "poweroff"], danger: true }
    ]

    Rectangle {
        anchors { fill: parent; margins: 10 }
        radius: Theme.radiusLg
        color: Theme.panelRaised
    }

    Column {
        anchors { fill: parent; leftMargin: 18; rightMargin: 18; topMargin: 18 }
        spacing: 2

        Repeater {
            model: root.actions

            Item {
                id: row
                required property var modelData

                width: parent.width
                height: 38

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusSm
                    color: area.containsMouse ? Theme.panelHigh : "transparent"
                }
                PanelIcon {
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    size: 18
                    name: row.modelData.icon
                    color: row.modelData.danger ? Theme.danger : Theme.textDim
                }
                Text {
                    x: 40
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.label
                    color: row.modelData.danger ? Theme.danger : Theme.text
                    font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        PanelState.dismiss("session")
                        Quickshell.execDetached(row.modelData.cmd)
                    }
                }
            }
        }
    }
}
