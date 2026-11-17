import QtQuick
import qs.theme

Rectangle {
    id: root

    property string text
    property bool primary: false
    property bool danger: false
    signal clicked

    implicitWidth: label.implicitWidth + 28
    implicitHeight: 32
    radius: Theme.radiusSm
    color: primary ? Theme.accent : Qt.alpha(Theme.text, area.containsMouse ? 0.12 : 0.06)
    border.width: primary ? 0 : 1
    border.color: Theme.border
    Behavior on color { ColorAnimation { duration: Theme.durFast } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.primary ? Theme.accentText : (root.danger ? Theme.danger : Theme.text)
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
