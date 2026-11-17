import QtQuick
import qs.theme

// Settings preview for `accents.count`: the four colors of the shell (main accent, secondary accent and two muted
// tones) as swatches, and a small framed block drawn with the real tokens.
Item {
    id: root

    readonly property var slots: [
        { name: "Accent", color: Theme.accent, ok: true },
        { name: "Secondary", color: Theme.secondaryColor, ok: Theme.extraColors.length > 0 },
        { name: "Muted frame", color: Qt.tint(Theme.mutedBase, Qt.alpha(Theme.accent, Theme.mutedTint)), ok: true },
        { name: "Muted surface", color: Qt.tint(Theme.mutedBase, Qt.alpha(Theme.extraColors.length > 0 ? Theme.secondaryColor : Theme.accent, Theme.mutedTint)), ok: true }
    ]

    width: parent ? parent.width : implicitWidth
    implicitHeight: 12 + swatchRow.height + 12 + picker.height + note.height + 8 + frame.height + 12

    Row {
        id: swatchRow
        y: 12
        spacing: 16
        height: 56

        Repeater {
            model: root.slots

            Column {
                id: slot
                required property var modelData
                required property int index
                readonly property bool used: index < Theme.colorCount && modelData.ok
                spacing: 4
                width: 96

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 32; height: 32; radius: 16
                    color: slot.modelData.color
                    border.width: slot.modelData.ok ? 0 : 1
                    border.color: Theme.border
                    opacity: slot.used ? 1 : Theme.disabledOpacity
                    Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: slot.modelData.name
                    color: slot.used ? Theme.text : Theme.textOff
                    font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
                }
            }
        }
    }

    // The wallpaper colors that can serve as the secondary accent; a click picks one.
    Row {
        id: picker
        anchors { left: parent.left; top: swatchRow.bottom; topMargin: 12 }
        height: visible ? 28 : 0
        spacing: 8
        visible: Theme.extraColors.length > 1

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Secondary accent from"
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
        Repeater {
            model: Theme.extraColors
            Rectangle {
                id: chip
                required property string modelData
                required property int index
                readonly property bool picked: index === Math.min(Theme.cfg.accents.pick, Theme.extraColors.length - 1)
                anchors.verticalCenter: parent.verticalCenter
                width: 28; height: 28; radius: 14
                color: "transparent"
                border.width: 2
                border.color: picked ? Theme.borderActive : "transparent"
                Rectangle { anchors { fill: parent; margins: 4 } radius: width / 2; color: chip.modelData }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Theme.set("accents", "pick", chip.index) }
            }
        }
    }

    Text {
        id: note
        anchors { left: parent.left; right: parent.right; top: picker.bottom; topMargin: 12 }
        height: visible ? implicitHeight : 0
        visible: Theme.extraColors.length === 0
        wrapMode: Text.WordWrap
        text: "This wallpaper has no distinct second color, so a neighbouring hue of the accent stands in"
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
    }

    // A piece of the screen frame with a block inside, as the shell draws it with the current settings.
    Rectangle {
        id: frame
        anchors { left: parent.left; right: parent.right; top: note.bottom; topMargin: 8 }
        height: 144
        radius: Theme.radiusLg
        color: Theme.mutedGray
        Behavior on color { ColorAnimation { duration: Theme.durNormal } }

        Block {
            anchors { fill: parent; margins: 14 }
            title: "Performance"
            icon: "pulse"

            Row {
                anchors.fill: parent
                spacing: 16

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        text: "Memory"
                        color: Theme.textDim
                        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                    }
                    Text {
                        text: "6.4 GB"
                        color: Theme.text
                        font { family: Theme.fontUi; pixelSize: 26; weight: Theme.wStrong }
                    }
                }

                Row {
                    anchors.bottom: parent.bottom
                    height: parent.height
                    spacing: 3
                    Repeater {
                        model: [0.35, 0.5, 0.42, 0.7, 0.55, 0.62, 0.85, 0.6, 0.72, 0.5, 0.66, 0.8]
                        Item {
                            required property real modelData
                            width: 5; height: parent.height
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width; radius: 2
                                height: parent.height * parent.modelData
                                color: Theme.accent
                            }
                        }
                    }
                }

                Row {
                    anchors.bottom: parent.bottom
                    height: parent.height
                    spacing: 3
                    Repeater {
                        model: [0.2, 0.3, 0.25, 0.4, 0.3, 0.35]
                        Item {
                            required property real modelData
                            width: 5; height: parent.height
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width; radius: 2
                                height: parent.height * parent.modelData
                                color: Theme.accent2
                            }
                        }
                    }
                }
            }
        }
    }
}
