import QtQuick
import qs.theme

// A square icon-only button (30 × 30): pill at rest, high on hover, accent container when `active`.
// `danger` paints the icon in the danger color for destructive actions.
Item {
    id: root

    property string icon
    property bool active: false
    property bool danger: false
    property real radius: Theme.radiusSm
    property real iconSize: 16
    signal clicked()

    width: 30
    height: 30
    opacity: enabled ? 1 : Theme.disabledOpacity

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.active ? Theme.accentContainer : (hover.hovered && root.enabled ? Theme.panelHigh : Theme.panelPill)
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }
    PanelIcon {
        anchors.centerIn: parent
        name: root.icon
        size: root.iconSize
        color: root.danger ? Theme.danger : (root.active || hover.hovered ? Theme.text : Theme.textDim)
    }
    // A MouseArea, not a TapHandler: it takes the press, so a clickable card under the button does not fire too.
    MouseArea {
        id: hover
        readonly property bool hovered: containsMouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
