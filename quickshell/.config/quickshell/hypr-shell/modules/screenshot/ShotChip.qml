import QtQuick
import qs.theme
import qs.components

// A small drop-down trigger: optional icon, text and a caret.
Item {
    id: root

    property string icon: ""
    property string text: ""
    property bool open: false
    signal clicked()

    implicitWidth: row.width + 20
    implicitHeight: 34
    opacity: enabled ? 1 : 0.4

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm
        color: root.open ? Qt.alpha(Theme.accent, 0.18) : (area.containsMouse && root.enabled ? Theme.panelHigh : Theme.panelRaised)
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7

        PanelIcon {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: 15
            color: root.open ? Theme.accent : Theme.textDim
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.open ? Theme.accent : Theme.text
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
        }

        PanelIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: "chevronDown"
            size: 13
            rotation: root.open ? 180 : 0
            color: root.open ? Theme.accent : Theme.textDim
            Behavior on rotation { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.enabled) root.clicked()
    }
}
