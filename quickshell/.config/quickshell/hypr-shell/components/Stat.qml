import QtQuick
import QtQuick.Layouts
import qs.theme

// A small figure: caption on top, value below.
Tile {
    id: stat

    property string label
    property string value
    property bool mono: false

    Layout.fillWidth: true
    Layout.preferredHeight: 64

    // Neighbouring figures alternate between two containers, like the tiles of the dashboards.
    readonly property int slot: {
        let n = 0
        if (!parent) return 0
        for (const c of parent.children) {
            if (c === stat) return n
            if (c.hasOwnProperty("mono")) n++
        }
        return 0
    }
    tone: slot % 2 === 0 ? Theme.accentContainer : Theme.tertiaryContainer

    Text {
        x: 12
        y: 12
        width: stat.width - 24
        text: stat.label.toUpperCase()
        color: Theme.textDim
        elide: Text.ElideRight
        font { family: Theme.fontUi; pixelSize: 10; weight: Theme.wHeavy; letterSpacing: 1.2 }
    }
    Text {
        x: 12
        y: stat.height - height - 12
        width: stat.width - 24
        text: stat.value
        color: Theme.text
        elide: Text.ElideRight
        font { family: stat.mono ? Theme.fontMono : Theme.fontUi; pixelSize: stat.mono ? 11 : 16; weight: Theme.wStrong }
    }
}
