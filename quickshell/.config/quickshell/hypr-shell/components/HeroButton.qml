import QtQuick
import qs.theme

// A small button inside a big block.
Rectangle {
    id: btn

    property string text
    signal clicked

    width: lbl.implicitWidth + 20
    height: 24
    radius: Theme.radiusSm
    color: hov.hovered ? Theme.panelHigh : Theme.panelPill
    border.width: 1
    border.color: Theme.border
    Behavior on color { ColorAnimation { duration: Theme.durFast } }

    Text {
        id: lbl
        anchors.centerIn: parent
        text: btn.text
        color: Theme.text
        font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
    }
    HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: btn.clicked() }
}
