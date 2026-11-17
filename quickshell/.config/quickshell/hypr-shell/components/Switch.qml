import QtQuick
import qs.theme

// A compact on/off pill for branch headers.
Item {
    id: root

    property bool checked: false
    signal toggled(bool value)

    width: 42
    height: 24

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: root.checked ? Theme.accent : Theme.panelTrack
        border.width: 1
        border.color: root.checked ? "transparent" : Theme.border
        Behavior on color { ColorAnimation { duration: Theme.durFast } }

        Rectangle {
            x: root.checked ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 18; height: 18; radius: 9
            color: root.checked ? Theme.accentText : Theme.text
            Behavior on x { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
