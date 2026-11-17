import QtQuick
import qs.theme

// Settings preview for borders: a focused and an unfocused mini window with the configured border,
// each with a 2x magnifier on its corner. Read-only.
Item {
    id: root

    readonly property real cardW: 220
    readonly property var cards: [
        { label: "Focused", border: Theme.borderActive },
        { label: "Unfocused", border: Theme.border }
    ]

    width: parent ? parent.width : implicitWidth
    implicitHeight: 104

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMd
        color: Theme.panelBase
    }

    Row {
        anchors.centerIn: parent
        spacing: 16

        Repeater {
            model: root.cards

            Item {
                id: slot
                required property var modelData
                width: root.cardW
                height: 76

                Surface {
                    width: 152
                    height: parent.height
                    radius: Theme.radiusMd
                    color: Theme.panelFillHigh
                    borderColor: slot.modelData.border
                    borderWidth: 1

                    Row {
                        x: 14
                        y: 12
                        spacing: 4
                        Repeater {
                            model: 3
                            Rectangle { width: 6; height: 6; radius: 3; color: Theme.panelHigh }
                        }
                    }
                    Text {
                        x: 14
                        y: 26
                        text: slot.modelData.label
                        color: Theme.text
                        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
                    }
                    Column {
                        x: 14
                        y: 46
                        spacing: 4
                        Rectangle { width: 96; height: 4; radius: 2; color: Theme.panelPill }
                        Rectangle { width: 64; height: 4; radius: 2; color: Theme.panelPill }
                    }
                }

                // 2x magnifier on the top-left corner of the card above.
                Item {
                    x: 160
                    y: 10
                    width: 56
                    height: 56
                    clip: true

                    Rectangle { anchors.fill: parent; color: Theme.panelDeep }
                    Rectangle {
                        x: 8
                        y: 8
                        width: 152 * 2
                        height: 76 * 2
                        radius: Theme.radiusMd * 2
                        color: Theme.panelFillHigh
                        border.width: 2
                        border.color: slot.modelData.border
                    }
                    Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Theme.border }
                }
            }
        }
    }
}
