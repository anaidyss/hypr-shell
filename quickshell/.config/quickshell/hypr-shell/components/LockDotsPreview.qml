import QtQuick
import qs.theme

// Lock screen password marks: four shapes to pick from and the password field with seven marks at the chosen size.
Item {
    id: root

    readonly property string current: Theme.cfg.lock.dotShape
    readonly property real size: Theme.cfg.lock.dotSize
    readonly property var shapes: [
        { value: "square", label: "Square" },
        { value: "circle", label: "Circle" },
        { value: "bar", label: "Bar" },
        { value: "diamond", label: "Diamond" }
    ]
    readonly property real gap: 14

    width: parent ? parent.width : implicitWidth
    implicitHeight: 4 + 84 + 14 + 52 + 12

    Row {
        id: tiles
        y: 4
        spacing: root.gap

        Repeater {
            model: root.shapes

            Surface {
                id: tile
                required property var modelData
                readonly property bool selected: root.current === modelData.value

                width: (root.width - 3 * root.gap) / 4
                height: 84
                radius: Theme.radiusMd
                color: hover.hovered ? Theme.panelPill : Theme.panelRaised
                borderColor: selected ? Theme.borderActive : Theme.border
                borderWidth: selected ? 2 : 1
                Behavior on color { ColorAnimation { duration: Theme.durFast } }

                Row {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 16 }
                    spacing: 6
                    Repeater {
                        model: 3
                        Item {
                            width: 18; height: 18
                            LockDotShape {
                                anchors.centerIn: parent
                                size: 18
                                shape: tile.modelData.value
                                color: Theme.text
                            }
                        }
                    }
                }

                Text {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 12 }
                    text: tile.modelData.label
                    color: tile.selected ? Theme.accent : Theme.text
                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
                }

                HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Theme.set("lock", "dotShape", tile.modelData.value) }
            }
        }
    }

    // The password field as on the lock screen.
    Surface {
        anchors { left: parent.left; right: parent.right; top: tiles.bottom; topMargin: 14 }
        height: 52
        radius: height / 2
        power: 2
        color: Theme.panelRaised
        borderColor: Theme.borderActive

        PanelIcon {
            anchors { left: parent.left; leftMargin: 24; verticalCenter: parent.verticalCenter }
            name: "lock"
            size: 18
            color: Theme.textDim
        }

        Row {
            anchors.centerIn: parent
            spacing: 6
            Repeater {
                model: 7
                Item {
                    width: root.size; height: root.size
                    LockDotShape {
                        anchors.centerIn: parent
                        size: root.size
                        shape: root.current
                        color: Theme.text
                    }
                }
            }
        }
    }
}
