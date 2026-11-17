import QtQuick
import qs.theme
import qs.services

// Keyboard layout code for the left strip; a click switches to the next layout.
Item {
    id: root

    implicitWidth: 32
    implicitHeight: 24
    visible: Keyboard.code !== ""

    Text {
        anchors.centerIn: parent
        text: Keyboard.code
        color: hover.hovered ? Theme.text : Theme.textDim
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wHeavy; letterSpacing: 0.6 }
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: Keyboard.next() }
}
