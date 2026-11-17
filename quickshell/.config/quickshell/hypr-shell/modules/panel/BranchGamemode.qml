import QtQuick
import qs.theme
import qs.services
import qs.components

// Game mode menu: one big switch and a checklist of what it does.
Item {
    id: root

    readonly property real pad: 12

    implicitWidth: 320
    implicitHeight: col.height + 2 * pad

    Column {
        id: col
        x: root.pad
        y: root.pad
        width: root.width - 2 * root.pad
        spacing: Theme.gapBlock

        Item {
            width: parent.width
            height: 88

            Surface {
                id: card
                anchors.fill: parent
                radius: Theme.radiusLg
                color: GameMode.on ? Theme.accentContainer : (hover.hovered ? Theme.panelHigh : Theme.panelRaised)
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
            }

            PanelIcon {
                x: Theme.padBlock
                anchors.verticalCenter: parent.verticalCenter
                name: "gamepad"
                size: 30
                color: GameMode.on ? Theme.accent : Theme.textDim
            }
            Column {
                x: Theme.padBlock + 30 + 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: "Game mode"
                    color: Theme.text
                    font { family: Theme.fontUi; pixelSize: 18; weight: Theme.wStrong }
                }
                Text {
                    text: GameMode.on ? "On" : "Off"
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                }
            }

            Rectangle {
                anchors { right: parent.right; rightMargin: Theme.padBlock; verticalCenter: parent.verticalCenter }
                width: 44
                height: 24
                radius: 12
                color: GameMode.on ? Theme.accent : Theme.panelTrackHigh
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
                Rectangle {
                    y: 4
                    x: GameMode.on ? parent.width - width - 4 : 4
                    width: 16
                    height: 16
                    radius: 8
                    color: GameMode.on ? Theme.accentText : Theme.text
                    Behavior on x { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
                }
            }

            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: GameMode.toggle() }
        }

        Block {
            width: parent.width
            height: 54 + list.height
            title: GameMode.on ? "Active" : "When on"
            icon: "gamepad"
            tone: Theme.secondaryContainer

            Column {
                id: list
                width: parent.width
                spacing: 8
                Repeater {
                    model: GameMode.parts
                    Chip {
                        required property var modelData
                        width: list.width
                        icon: GameMode.on ? "check" : modelData.icon
                        label: modelData.label
                        on: GameMode.on
                    }
                }
            }
        }
    }
}
