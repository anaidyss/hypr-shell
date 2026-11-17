import QtQuick
import qs.theme

// One of several options; a click moves to the next one.
Item {
    id: root

    property string title
    property string description
    property var options: []
    property string value
    signal picked(string value)

    readonly property int index: {
        for (let i = 0; i < options.length; i++) if (options[i].value === value) return i
        return 0
    }

    width: parent ? parent.width : implicitWidth
    implicitHeight: 52

    Column {
        anchors { left: parent.left; right: button.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
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
        id: button
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: 170
        height: 34
        radius: Theme.radiusSm
        color: area.containsMouse ? Qt.alpha(Theme.text, 0.1) : Theme.tile
        border.width: 1
        border.color: Theme.border
        Behavior on color { ColorAnimation { duration: Theme.durFast } }

        Text {
            anchors.centerIn: parent
            text: root.options.length > 0 ? root.options[root.index].label : ""
            color: Theme.text
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.picked(root.options[(root.index + 1) % root.options.length].value)
        }
    }
}
