import QtQuick
import qs.theme

// A captioned card; the content goes into `holder`. `glass` is for blocks over a wallpaper, otherwise it is a veil over the panel.
Surface {
    id: root

    property string title
    property string icon
    property bool glass: false
    // `backdrop` (from Surface): on the lock screen the block frosts that item, so it reads as the same matte glass as the dashboards.
    default property alias content: holder.data
    readonly property real pad: Theme.padBlock

    radius: Theme.radiusLg
    // Solid mode: a block may take a tinted container color (weather, media) instead of the plain layer.
    property color tone: "transparent"
    // Solid mode: a light milk block with dark text; its contents read their colors from fg, fgDim, fgAccent and fgLine.
    property bool light: false
    readonly property bool lit: Theme.solid && light && Theme.isLight
    readonly property color fg: lit ? Theme.onMilk : Theme.text
    readonly property color fgDim: lit ? Theme.onMilkDim : Theme.textDim
    readonly property color fgAccent: lit ? Theme.milkAccent : Theme.accent
    readonly property color fgLine: lit ? Theme.milkLine : Theme.border
    // Tells nested tiles that they sit on a light surface.
    readonly property bool lightScope: lit
    // The layer color for tiles on this block (a glass block over a wallpaper in solid mode has its own hued ladder).
    readonly property color layerTile: glass ? Theme.lockTile : Theme.panelRaised
    readonly property color layerHigh: glass ? Theme.lockPill : Theme.panelHigh
    property string paintRole: "card"
    color: Theme.ovCard.a > 0 ? Theme.ovCard : lit ? Theme.milk : (Theme.solid && tone.a > 0 ? tone : (glass && !glassFill ? Theme.blockGlass : Theme.panelRaised))
    glassFill: glass && backdrop !== null && !Theme.solid
    glassTint: Theme.panelBase
    glassTintAlpha: Theme.panelAlpha
    borderColor: Theme.border

    Row {
        x: root.pad
        y: 14
        height: 16
        spacing: 8
        visible: root.title !== ""

        PanelIcon { anchors.verticalCenter: parent.verticalCenter; name: root.icon; size: 16; color: root.lit ? Theme.milkAccent : Theme.accent2 }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.width - root.pad * 2 - 24)
            elide: Text.ElideRight
            text: root.title.toUpperCase()
            color: root.fgDim
            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy; letterSpacing: 1.3 }
        }
    }

    Item {
        id: holder
        x: root.pad
        y: root.title !== "" ? 38 : root.pad
        width: root.width - root.pad * 2
        height: root.height - y - root.pad
    }
}
