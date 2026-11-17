import QtQuick
import qs.theme

Item {
    id: root

    property string title
    property string description
    property bool checked: false
    signal toggled(bool value)

    width: parent ? parent.width : implicitWidth
    implicitHeight: 52

    Column {
        anchors { left: parent.left; right: sw.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 2
        Text {
            width: parent.width
            text: root.title
            color: Theme.text
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
        }
        Text {
            width: parent.width
            visible: root.description !== ""
            text: root.description
            color: Theme.textDim
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
    }

    Rectangle {
        id: sw
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: 42
        height: 24
        radius: 12
        color: root.checked ? Theme.accent : Theme.tile
        border.width: 1
        border.color: root.checked ? "transparent" : Theme.border
        Behavior on color { ColorAnimation { duration: Theme.durFast } }

        Rectangle {
            x: root.checked ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            radius: 9
            color: root.checked ? Theme.accentText : Theme.text
            Behavior on x { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled(!root.checked)
        }
    }
}
