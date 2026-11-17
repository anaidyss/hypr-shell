import QtQuick
import qs.theme

Item {
    id: root

    property string title
    property string subtitle
    property bool active: false
    property bool clickable: false
    default property alias actions: actionRow.data
    property alias extra: extraColumn.data
    signal clicked

    width: parent ? parent.width : implicitWidth
    implicitHeight: 52 + extraColumn.height

    Rectangle {
        anchors { fill: parent; leftMargin: -8; rightMargin: -8; topMargin: 2; bottomMargin: 2 }
        radius: Theme.radiusSm
        color: root.active ? Qt.alpha(Theme.accent, 0.12) : (root.clickable && hover.hovered ? Qt.alpha(Theme.text, 0.05) : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    Column {
        anchors { left: parent.left; right: actionRow.left; rightMargin: 12; top: parent.top; topMargin: 9 }
        spacing: 2
        Text {
            width: parent.width
            text: root.title
            color: root.active ? Theme.accent : Theme.text
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
        }
        Text {
            width: parent.width
            visible: root.subtitle !== ""
            text: root.subtitle
            color: Theme.textDim
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
    }

    Row {
        id: actionRow
        anchors { right: parent.right; top: parent.top; topMargin: 10 }
        spacing: 8
    }

    Column {
        id: extraColumn
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 52 }
    }

    HoverHandler { id: hover; enabled: root.clickable; cursorShape: Qt.PointingHandCursor }
    TapHandler { enabled: root.clickable; onTapped: root.clicked() }
}
