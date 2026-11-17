import QtQuick
import qs.theme

// A one-button switch: icon, name and a short state line. `on` fills it with the accent container.
Surface {
    id: root

    property string icon
    property string label
    property string sub
    property bool on: false
    signal activated()

    implicitWidth: 100
    implicitHeight: 76
    radius: Theme.radiusLg
    color: !enabled ? Theme.panelRaised : (on ? (Theme.solid ? Theme.accentContainer : Qt.alpha(Theme.accent, 0.16))
        : (hover.hovered ? Theme.panelHigh : Theme.panelRaised))
    borderColor: on && !Theme.solid ? Theme.borderActive : Theme.border
    opacity: enabled ? 1 : Theme.disabledOpacity
    Behavior on color { ColorAnimation { duration: Theme.durFast } }

    PanelIcon {
        x: Theme.padTile
        y: Theme.padTile
        name: root.icon
        size: 20
        color: root.on ? Theme.accent : (hover.hovered ? Theme.text : Theme.textDim)
    }

    Column {
        x: Theme.padTile
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.padTile
        width: parent.width - 2 * Theme.padTile
        spacing: 2

        Text {
            width: parent.width
            text: root.label
            color: Theme.text
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
        }
        Text {
            width: parent.width
            visible: root.sub !== ""
            text: root.sub
            color: Theme.textDim
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
        }
    }

    HoverHandler { id: hover; enabled: root.enabled; cursorShape: Qt.PointingHandCursor }
    TapHandler { enabled: root.enabled; onTapped: root.activated() }
}
