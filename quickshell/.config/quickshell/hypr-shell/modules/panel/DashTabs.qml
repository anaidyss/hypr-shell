import QtQuick
import qs.theme
import qs.components

// Tab strip of the dashboard: icon + label, an accent underline that slides, a thin line below.
Item {
    id: root

    property var model: []
    default property alias trailing: trail.data
    property int current: 0
    signal picked(int index)

    implicitHeight: 40

    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: Theme.border
    }

    Row {
        id: trail
        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter; verticalCenterOffset: -1 }
    }

    Row {
        id: row
        anchors { left: parent.left; top: parent.top }
        height: parent.height - 1
        spacing: 6

        Repeater {
            id: rep
            model: root.model

            Item {
                id: tab
                required property var modelData
                required property int index
                readonly property bool active: index === root.current

                width: label.implicitWidth + 16 + 6 + 28
                height: row.height

                PanelIcon {
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    name: tab.modelData.icon
                    size: 16
                    color: tab.active && !Theme.solid ? Theme.accent : (tab.active || hover.hovered ? Theme.text : Theme.textDim)
                }

                Rectangle {
                    readonly property int count: tab.modelData.badge || 0
                    x: 14 + 16 - 6
                    y: tab.height / 2 - 19
                    width: Math.max(16, badgeText.implicitWidth + 8)
                    height: 16
                    radius: 8
                    color: Theme.accent
                    scale: count > 0 ? 1 : 0
                    Behavior on scale { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: parent.count > 99 ? "99+" : parent.count
                        color: Theme.accentText
                        font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy }
                    }
                }

                Text {
                    id: label
                    x: 14 + 16 + 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: tab.modelData.label
                    color: tab.active ? Theme.text : (hover.hovered ? Theme.text : Theme.textDim)
                    font { family: Theme.fontUi; pixelSize: 14; weight: tab.active ? Theme.wStrong : Theme.wBold }
                }

                HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.picked(tab.index) }
            }
        }
    }

    // Glass: a thin accent underline slides under the tab. Solid: a tinted container pill slides behind it.
    Rectangle {
        readonly property Item target: rep.count > root.current ? rep.itemAt(root.current) : null
        readonly property string paintRole: Theme.solid ? "selected" : "accent"
        z: -1
        x: row.x + (target ? target.x + (Theme.solid ? 4 : 14) : 0)
        width: target ? target.width - (Theme.solid ? 8 : 28) : 0
        y: Theme.solid ? 4 : parent.height - 2
        height: Theme.solid ? parent.height - 9 : 2
        radius: Theme.solid ? Theme.radiusSm : 1
        color: Theme.solid ? Theme.accentContainer : Theme.accent
        Behavior on x { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
        Behavior on width { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
    }
}
