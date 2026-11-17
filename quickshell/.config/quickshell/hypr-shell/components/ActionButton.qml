import QtQuick
import qs.theme

// A button with an optional icon and a label. `primary` fills it with the selected container, `active` with the
// accent container too (a toggled state); disabled buttons dim and ignore the pointer.
Item {
    id: root

    property string icon
    property string text
    property bool primary: false
    property bool active: false
    // Destructive action: label and icon in the danger color.
    property bool danger: false
    signal clicked()

    readonly property bool hot: primary || active

    implicitWidth: row.implicitWidth + 24
    implicitHeight: 32
    opacity: enabled ? 1 : Theme.disabledOpacity

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm
        color: root.hot ? Theme.accentContainer : (hover.hovered && root.enabled ? Theme.panelHigh : Theme.panelPill)
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        PanelIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            name: root.icon
            size: 16
            color: root.danger ? Theme.danger : root.hot ? Theme.text : Theme.textDim
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.text !== ""
            text: root.text
            color: root.danger ? Theme.danger : root.hot || hover.hovered ? Theme.text : Theme.textDim
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
        }
    }

    HoverHandler { id: hover; enabled: root.enabled; cursorShape: Qt.PointingHandCursor }
    TapHandler { enabled: root.enabled; onTapped: root.clicked() }
}
