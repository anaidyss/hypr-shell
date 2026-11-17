import QtQuick
import qs.theme

// A small square button with an icon (minus, plus).
Item {
    id: btn

    property string icon
    signal clicked()

    width: 28
    height: 28

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm
        color: hover.hovered ? Theme.panelHigh : Theme.panelPill
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }
    PanelIcon { anchors.centerIn: parent; name: btn.icon; size: 14; color: hover.hovered ? Theme.text : Theme.textDim }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: btn.clicked() }
}
