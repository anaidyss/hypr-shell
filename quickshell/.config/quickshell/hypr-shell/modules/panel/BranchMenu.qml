import QtQuick
import qs.theme
import qs.services
import qs.components

// Flyout of one category of the strip's tool menus. Hovering the category opens it at once; a click on an option
// opens that branch in its place. Each category has its own layout (RailMenus.categories[].layout): rows with a line
// of explanation, a big first tile with smaller ones under it, or a grid of equal tiles.
Item {
    id: root

    readonly property var cat: RailMenus.category(PanelState.menuId)
    readonly property int pad: Theme.padTile
    readonly property int gap: 8
    readonly property real inner: implicitWidth - 2 * pad

    implicitWidth: 264
    implicitHeight: pad + header.height + gap + body.height + pad

    Row {
        id: header
        x: root.pad + 4
        y: root.pad
        height: 24
        spacing: 8

        PanelIcon { anchors.verticalCenter: parent.verticalCenter; name: root.cat.icon; size: 16; color: Theme.textDim }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.cat.title.toUpperCase()
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy; letterSpacing: 1.3 }
        }
    }

    Item {
        id: body
        x: root.pad
        y: root.pad + header.height + root.gap
        width: root.inner
        height: root.cat.layout === "rows" ? rows.height : (root.cat.layout === "hero" ? hero.height : grid.height)

        // Rows: icon plate, name, one line of what it does.
        Column {
            id: rows
            visible: root.cat.layout === "rows"
            width: parent.width
            spacing: root.gap

            Repeater {
                model: root.cat.layout === "rows" ? root.cat.options : []
                MenuOption {
                    required property var modelData
                    required property int index
                    opt: modelData; order: index; variant: "row"
                    width: rows.width; height: 56
                }
            }
        }

        // Hero: the first option is large, the others are tiles under it.
        Column {
            id: hero
            visible: root.cat.layout === "hero"
            width: parent.width
            spacing: root.gap

            Repeater {
                model: root.cat.layout === "hero" ? root.cat.options.slice(0, 1) : []
                MenuOption {
                    required property var modelData
                    required property int index
                    opt: modelData; order: index; variant: "hero"
                    width: hero.width; height: 72
                }
            }
            Row {
                spacing: root.gap
                Repeater {
                    id: heroRest
                    model: root.cat.layout === "hero" ? root.cat.options.slice(1) : []
                    MenuOption {
                        required property var modelData
                        required property int index
                        opt: modelData; order: index + 1
                        variant: heroRest.count === 1 ? "row" : "tile"
                        width: (hero.width - root.gap * (heroRest.count - 1)) / Math.max(1, heroRest.count)
                        height: heroRest.count === 1 ? 56 : 72
                    }
                }
            }
        }

        // Grid: equal tiles in one row.
        Row {
            id: grid
            visible: root.cat.layout === "grid"
            spacing: root.gap

            Repeater {
                id: gridTiles
                model: root.cat.layout === "grid" ? root.cat.options : []
                MenuOption {
                    required property var modelData
                    required property int index
                    opt: modelData; order: index; variant: "tile"
                    width: (body.width - root.gap * (gridTiles.count - 1)) / Math.max(1, gridTiles.count); height: 72
                }
            }
        }
    }
}
