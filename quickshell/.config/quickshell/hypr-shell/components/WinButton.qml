import QtQuick
import qs.theme

// A compact action button of the window menus: optional icon and a label; `active` marks the current choice.
Item {
    id: root

    property string icon
    property string label
    property bool active: false
    property bool enabled2: true
    signal clicked()

    implicitWidth: 80
    implicitHeight: 36
    opacity: enabled2 ? 1 : Theme.disabledOpacity

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm
        color: root.active ? Theme.accentContainer : (hover.hovered && root.enabled2 ? Theme.panelHigh : Theme.panelPill)
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    Row {
        anchors.centerIn: parent
        spacing: 6

        PanelIcon {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: 16
            color: root.active ? Theme.text : Theme.textDim
        }
        Text {
            visible: root.label !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.active ? Theme.text : Theme.textDim
            font { family: Theme.fontUi; pixelSize: 12; weight: root.active ? Theme.wStrong : Theme.wBold }
        }
    }

    HoverHandler { id: hover; cursorShape: root.enabled2 ? Qt.PointingHandCursor : Qt.ArrowCursor }
    TapHandler { enabled: root.enabled2; onTapped: root.clicked() }
}
