import QtQuick
import qs.theme
import qs.services
import qs.components

// Color picker menu of the strip: pick from the screen, the history, and paint the color onto a part of the interface.
// Paint mode is the main way (click any part of the shell); the role list below does the same without clicking.
Item {
    id: root

    implicitWidth: 360
    implicitHeight: 424

    readonly property string cur: ColorPicker.current

    Block {
        anchors { fill: parent; margins: 12 }
        title: "Color picker"
        icon: "pipette"
        tone: Theme.tertiaryContainer

        Column {
            anchors.fill: parent
            spacing: Theme.gapsIn

            Row {
                width: parent.width
                height: 48
                spacing: 12

                Rectangle {
                    width: 48
                    height: 48
                    radius: Theme.radiusSm
                    color: root.cur === "" ? "transparent" : root.cur
                    border { width: 1; color: Theme.border }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 48 - 12 - 8 - copyRow.width
                    spacing: 2

                    Text {
                        text: root.cur === "" ? "No color yet" : root.cur
                        color: root.cur === "" ? Theme.textDim : Theme.text
                        font { family: root.cur === "" ? Theme.fontUi : Theme.fontMono; pixelSize: root.cur === "" ? 14 : 18; weight: Theme.wStrong }
                    }
                    Text {
                        width: parent.width
                        text: ColorPicker.flash !== "" ? "Copied " + ColorPicker.flash : ColorPicker.rgb(root.cur)
                        color: Theme.textDim
                        elide: Text.ElideRight
                        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                    }
                }

                Row {
                    id: copyRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    ActionButton { text: "Hex"; enabled: root.cur !== ""; onClicked: ColorPicker.copy(root.cur) }
                    ActionButton { text: "RGB"; enabled: root.cur !== ""; onClicked: ColorPicker.copy(ColorPicker.rgb(root.cur)) }
                }
            }

            Row {
                width: parent.width
                spacing: 8

                ActionButton {
                    width: (parent.width - 8) / 2
                    icon: "pipette"
                    text: ColorPicker.picking ? "Picking…" : "Pick from screen"
                    primary: true
                    enabled: !ColorPicker.picking
                    onClicked: ColorPicker.pick()
                }
                ActionButton {
                    width: (parent.width - 8) / 2
                    icon: "brush"
                    text: ColorPicker.painting ? "Painting" : "Paint"
                    active: ColorPicker.painting
                    enabled: root.cur !== ""
                    onClicked: ColorPicker.painting ? ColorPicker.stopPaint() : ColorPicker.startPaint("")
                }
            }

            Text {
                text: "HISTORY"
                color: Theme.textDim
                visible: ColorPicker.history.length > 0
                font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy; letterSpacing: 1.3 }
            }

            Flow {
                width: parent.width
                spacing: 6
                visible: ColorPicker.history.length > 0

                Repeater {
                    model: ColorPicker.history

                    Rectangle {
                        required property string modelData
                        width: 24
                        height: 24
                        radius: Theme.radiusSm * 0.6
                        color: modelData
                        border { width: modelData === root.cur ? 2 : 1; color: modelData === root.cur ? Theme.borderActive : Theme.border }

                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: ColorPicker.select(parent.modelData) }
                    }
                }
            }

            Text {
                text: "PAINT A ROLE"
                color: Theme.textDim
                font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy; letterSpacing: 1.3 }
            }

            Grid {
                width: parent.width
                columns: 2
                spacing: 4

                Repeater {
                    model: ColorPicker.roles

                    Item {
                        id: role
                        required property var modelData
                        readonly property string set: ColorPicker.valueOf(modelData.id)

                        width: (parent.width - 4) / 2
                        height: 30
                        opacity: root.cur !== "" || set !== "" ? 1 : Theme.disabledOpacity

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radiusSm
                            color: roleHover.hovered ? Theme.panelHigh : Theme.panelPill
                            Behavior on color { ColorAnimation { duration: Theme.durFast } }
                        }
                        Rectangle {
                            x: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14
                            radius: 4
                            color: role.set !== "" ? role.set : "transparent"
                            border { width: 1; color: Theme.border }
                        }
                        Text {
                            x: 28
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 28 - 26
                            text: role.modelData.label
                            color: Theme.text
                            elide: Text.ElideRight
                            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                        }
                        PanelIcon {
                            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                            visible: role.set !== ""
                            name: "close"
                            size: 14
                            color: Theme.textDim

                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: ColorPicker.clear(role.modelData.id) }
                        }

                        HoverHandler { id: roleHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: ColorPicker.apply(role.modelData.id) }
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 8
                ActionButton { icon: "restart"; text: "Undo"; enabled: ColorPicker.canUndo; onClicked: ColorPicker.undo() }
                ActionButton { text: "Reset all"; enabled: ColorPicker.hasOverrides; onClicked: ColorPicker.resetAll() }
            }
        }
    }
}
