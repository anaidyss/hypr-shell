import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// Palette picker: the wallpaper's own Material You palette and the fixed presets, each drawn as a miniature app window.
Item {
    id: root

    readonly property var entries: [
        { id: "matugen", label: "Wallpaper" },
        { id: "catppuccin-mocha", label: "Catppuccin Mocha" },
        { id: "tokyo-night", label: "Tokyo Night" },
        { id: "nord", label: "Nord" }
    ]
    readonly property real cardW: (width - 3 * Theme.gapBlock) / 4
    readonly property real cardH: 136

    width: parent ? parent.width : implicitWidth
    implicitHeight: cardH + 16

    Repeater {
        model: root.entries

        delegate: Item {
            id: card

            required property var modelData
            required property int index

            readonly property bool selected: Theme.cfg.theme.preset === modelData.id
            readonly property bool wall: modelData.id === "matugen"
            readonly property var pal: wall ? Theme.colors : preset

            x: index * (root.cardW + Theme.gapBlock)
            y: 8
            width: root.cardW
            height: root.cardH

            FileView {
                path: Quickshell.env("HOME") + "/.config/hypr-shell/presets/" + card.modelData.id + ".json"
                printErrors: false
                watchChanges: true
                onFileChanged: reload()
                adapter: JsonAdapter {
                    id: preset
                    property color crust: "#101010"
                    property color mantle: "#141414"
                    property color base: "#181818"
                    property color surface0: "#202020"
                    property color surface1: "#282828"
                    property color surface2: "#303030"
                    property color text: "#e0e0e0"
                    property color subtext: "#a0a0a0"
                    property color primary: "#8ab4a0"
                    property color primaryText: "#101010"
                    property color secondary: "#a0a8c0"
                    property color tertiary: "#c0a0c0"
                    property color error: "#ff6b6b"
                }
            }

            Surface {
                anchors.fill: parent
                radius: Theme.radiusMd
                color: hover.hovered ? Theme.panelPill : Theme.tile
                borderColor: card.selected ? Theme.borderActive : Theme.border
                borderWidth: card.selected ? 2 : 1
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
            }

            // Miniature app window
            Surface {
                id: win
                x: 8; y: 8
                width: parent.width - 16
                height: 76
                radius: 10
                color: card.pal.base
                borderColor: card.pal.surface2

                Rectangle {
                    id: titlebar
                    width: parent.width; height: 12
                    color: card.pal.crust
                    Row {
                        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                        spacing: 3
                        Repeater {
                            model: [card.pal.error, card.pal.secondary, card.pal.primary]
                            Rectangle { required property color modelData; width: 4; height: 4; radius: 2; color: modelData }
                        }
                    }
                }

                Rectangle {
                    id: side
                    y: titlebar.height
                    width: 30; height: parent.height - y
                    color: card.pal.mantle
                    Column {
                        x: 5; y: 6
                        spacing: 5
                        Repeater {
                            model: 3
                            Rectangle { required property int index; width: index === 0 ? 20 : 14; height: 3; radius: 1.5; color: index === 0 ? card.pal.primary : card.pal.subtext }
                        }
                    }
                }

                Column {
                    x: side.width + 8; y: titlebar.height + 6
                    width: parent.width - x - 8
                    spacing: 5

                    Rectangle {
                        width: parent.width; height: 12; radius: 4
                        color: card.pal.surface1
                        Rectangle { x: 4; anchors.verticalCenter: parent.verticalCenter; width: 2; height: 6; radius: 1; color: card.pal.primary }
                        Rectangle { x: 10; anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.45; height: 3; radius: 1.5; color: card.pal.text }
                    }
                    Rectangle { width: parent.width * 0.8; height: 3; radius: 1.5; color: card.pal.subtext }
                    Rectangle { width: parent.width * 0.55; height: 3; radius: 1.5; color: card.pal.subtext }
                    Rectangle {
                        width: 28; height: 10; radius: 5
                        color: card.pal.primary
                        Rectangle { anchors.centerIn: parent; width: 14; height: 3; radius: 1.5; color: card.pal.primaryText }
                    }
                }
            }

            // Colors that matter most
            Row {
                x: 8; y: 8 + 76 + 8
                width: parent.width - 16
                height: 8
                spacing: 4
                Repeater {
                    model: [card.pal.surface1, card.pal.primary, card.pal.secondary, card.pal.tertiary, card.pal.error]
                    Rectangle {
                        required property color modelData
                        width: (parent.width - 16) / 5; height: 8; radius: 4
                        color: modelData
                    }
                }
            }

            Item {
                x: 8; y: 8 + 76 + 8 + 8 + 8
                width: parent.width - 16
                height: 18

                PanelIcon {
                    id: check
                    anchors.verticalCenter: parent.verticalCenter
                    visible: card.selected
                    name: "check"
                    size: 14
                    color: Theme.accent
                }
                Text {
                    anchors { left: card.selected ? check.right : parent.left; leftMargin: card.selected ? 4 : 0; right: parent.right; verticalCenter: parent.verticalCenter }
                    elide: Text.ElideRight
                    text: card.modelData.label
                    color: card.selected ? Theme.accent : Theme.text
                    font { family: Theme.fontUi; pixelSize: 12; weight: card.selected ? Theme.wStrong : Theme.wBold }
                }
            }

            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Theme.set("theme", "preset", card.modelData.id) }
        }
    }
}
