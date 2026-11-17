import QtQuick
import qs.theme
import qs.services

Item {
    id: root

    property string icon
    property string kind: ""
    property string menuId: ""
    property bool clickOpens: true
    property bool vertical: true
    property bool highlight: false
    property real iconSize: 20
    property string screenName: ""
    signal clicked()

    readonly property bool active: kind !== "" && PanelState.isOpen(kind) && (menuId === "" || PanelState.menuId === menuId)

    implicitWidth: 40
    implicitHeight: 40

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMd
        color: root.active || root.highlight ? Qt.alpha(Theme.accent, 0.16) : (trigger.hovered ? Theme.panelHigh : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    PanelIcon {
        anchors.centerIn: parent
        name: root.icon
        size: root.iconSize
        color: root.active || root.highlight ? Theme.accent : (trigger.hovered ? Theme.text : Theme.textDim)
    }

    PanelTrigger {
        id: trigger
        anchors.fill: parent
        kind: root.kind
        menuId: root.menuId
        clickOpens: root.clickOpens
        vertical: root.vertical
        screenName: root.screenName
        onClicked: root.clicked()
    }
}
