import QtQuick
import qs.theme
import qs.components

Item {
    id: root

    property string icon
    property bool active: false
    property real iconSize: 18
    signal clicked()

    implicitWidth: 34
    implicitHeight: 34
    opacity: enabled ? 1 : 0.35

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm
        color: root.active ? Qt.alpha(Theme.accent, 0.18) : (area.containsMouse && root.enabled ? Theme.panelHigh : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    PanelIcon {
        anchors.centerIn: parent
        name: root.icon
        size: root.iconSize
        color: root.active ? Theme.accent : (area.containsMouse && root.enabled ? Theme.text : Theme.textDim)
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.enabled) root.clicked()
    }
}
