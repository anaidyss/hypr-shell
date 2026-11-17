import QtQuick
import qs.theme

// A raised area inside a block or on the panel; children are placed directly inside.
Surface {
    radius: Theme.radiusSm
    // Solid mode: a tinted container (see Theme.tertiaryContainer and friends) instead of the plain layer.
    property color tone: "transparent"
    property string paintRole: "tile"
    // The layer color the nearest block offers (see Block.layerTile), the plain panel layer otherwise.
    readonly property color layerColor: {
        for (let it = parent; it; it = it.parent)
            if (it.layerTile !== undefined) return it.layerTile
        return Theme.panelRaised
    }
    color: Theme.ovTile.a > 0 ? Theme.ovTile : lit ? Theme.milkTile : (Theme.solid && tone.a > 0 ? tone : layerColor)
    borderWidth: 0

    // On a light block (see Block.light) the tile is a slightly darker milk. A binding, not a one-time check:
    // the scheme can flip between light and dark while the dashboard exists, and the tile has to follow its block.
    readonly property bool lit: {
        for (let it = parent; it; it = it.parent)
            if (it.lightScope === true) return true
        return false
    }

    readonly property real pad: Theme.padTile
}
