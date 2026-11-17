import QtQuick
import qs.theme

// Frame color: three tiles with a miniature screen each; the chosen one is outlined.
Item {
    id: root

    readonly property string current: Theme.cfg.glass.surfaceColor
    // The same three colors as Theme.panelTarget (it has no token for black).
    readonly property var options: [
        { value: "accent", label: "Accent", detail: "From the wallpaper", color: Theme.accentColor },
        { value: "black", label: "Black", detail: "Clean and quiet", color: "#0b0b0e" },
        { value: "shade", label: "Shade", detail: "Darkest tone of the wallpaper", color: Theme.colors.crust },
        { value: "gray", label: "Muted", detail: "Gray tinted with the wallpaper", color: Theme.mutedGray }
    ]
    readonly property real gap: 14
    readonly property real tileWidth: (width - (options.length - 1) * gap) / options.length

    width: parent ? parent.width : implicitWidth
    implicitHeight: 8 + tileWidth * 1040 / 1560 + 8 + 19 + 2 + 16 + 8 + 8

    Row {
        spacing: root.gap
        y: 4

        Repeater {
            model: root.options

            Surface {
                id: tile
                required property var modelData
                readonly property bool selected: root.current === modelData.value

                width: root.tileWidth
                height: root.implicitHeight - 8
                radius: Theme.radiusMd
                color: hover.hovered ? Theme.panelPill : Theme.panelRaised
                borderColor: selected ? Theme.borderActive : Theme.border
                borderWidth: selected ? 2 : 1
                Behavior on color { ColorAnimation { duration: Theme.durFast } }

                ScreenPreview {
                    x: 8; y: 8
                    width: shotWidth
                    shotWidth: tile.width - 16
                    captions: false
                    bands: false
                    showGlow: false
                    minFrame: 40
                    frameColor: tile.modelData.color
                }

                Column {
                    x: 12
                    y: 8 + (tile.width - 16) * 1040 / 1560 + 8
                    width: tile.width - 24
                    spacing: 2
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: tile.modelData.label
                        color: tile.selected ? Theme.accent : Theme.text
                        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    }
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: tile.modelData.detail
                        color: Theme.textDim
                        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                    }
                }

                HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Theme.set("glass", "surfaceColor", tile.modelData.value) }
            }
        }
    }
}
