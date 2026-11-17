import QtQuick
import qs.theme

// A raised tile on the dashboard; children are placed directly inside.
// Every time it becomes visible it fades in and rises a little, tiles with a higher order a moment later.
Rectangle {
    id: root

    property int order: 0
    property real enter: 1
    // Solid mode: a tinted container (see Theme.tertiaryContainer and friends) instead of the plain layer.
    property color tone: "transparent"
    // Solid mode: a light milk tile with dark text; its contents read fg, fgDim, fgAccent from here.
    property bool light: false
    readonly property bool lit: Theme.solid && light && Theme.isLight
    readonly property color fg: lit ? Theme.onMilk : Theme.text
    readonly property color fgDim: lit ? Theme.onMilkDim : Theme.textDim
    readonly property color fgAccent: lit ? Theme.milkAccent : Theme.accent
    readonly property bool lightScope: lit

    radius: Theme.radiusLg
    property string paintRole: "tile"
    color: Theme.ovTile.a > 0 ? Theme.ovTile : lit ? Theme.milk : (Theme.solid && tone.a > 0 ? tone : Theme.panelRaised)
    border.width: 1
    border.color: Theme.separator
    opacity: enter
    transform: Translate { y: (1 - root.enter) * 12 }

    onVisibleChanged: if (visible) enterAnim.restart()

    SequentialAnimation {
        id: enterAnim
        PropertyAction { target: root; property: "enter"; value: 0 }
        PauseAnimation { duration: root.order * 55 }
        NumberAnimation { target: root; property: "enter"; to: 1; duration: Theme.durSlow; easing.type: Theme.easing; easing.overshoot: Theme.overshoot }
    }
}
