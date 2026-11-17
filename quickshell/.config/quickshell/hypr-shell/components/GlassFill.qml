import QtQuick
import QtQuick.Effects
import qs.theme

// A glass surface: the blurred wallpaper tinted toward `tint` at `tintAlpha`, clipped to `maskItem`.
// Standalone counterpart of WallpaperBlur; WallpaperBlur leaves tinting to an overlay, this bakes it in.
Item {
    id: root

    property Item maskItem: null
    property color tint: Theme.colors.base
    property real tintAlpha: Theme.cfg.glass.opacity
    property real strength: Theme.glassBlurAmount
    property int maxBlur: Theme.cfg.blur.size * Theme.cfg.blur.passes
    property real saturation: 0
    property real brightness: Theme.cfg.blur.brightness - 1
    // When set, the glass blurs this item (the screen background) instead of loading the wallpaper itself: the part
    // of it that lies behind this surface, so the frosted pane lines up with what is really behind it.
    property Item backdrop: null
    property rect region: Qt.rect(0, 0, width, height)

    function refresh() {
        if (!backdrop) return
        const a = mapToItem(backdrop, 0, 0)
        const b = mapToItem(backdrop, width, height)
        region = Qt.rect(a.x, a.y, b.x - a.x, b.y - a.y)

    }
    onWidthChanged: refresh()
    onHeightChanged: refresh()
    onBackdropChanged: refresh()
    Component.onCompleted: refresh()

    // The surface drifts and scales on the lock screen; follow it a few times a second.
    Timer { interval: 100; repeat: true; running: root.backdrop !== null && root.visible; onTriggered: root.refresh() }

    // With a backdrop (an already blurred copy of the screen background): the part that lies behind this surface.
    ShaderEffectSource {
        id: cutTex
        visible: false
        sourceItem: root.backdrop
        sourceRect: root.region
    }

    Image {
        id: img
        anchors.fill: parent
        visible: false
        asynchronous: true
        cache: true
        source: root.backdrop ? "" : WallpaperSource.url
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(Math.max(256, root.width), Math.max(256, root.height))
    }

    MultiEffect {
        anchors.fill: parent
        source: root.backdrop ? cutTex : img
        blurEnabled: root.backdrop === null
        blurMax: root.maxBlur
        blur: root.strength
        saturation: root.saturation
        brightness: root.brightness
        colorizationColor: root.tint
        colorization: root.tintAlpha
        maskEnabled: root.maskItem !== null
        maskSource: root.maskItem
        maskThresholdMin: 0
        maskSpreadAtMin: 0
        maskThresholdMax: 1
        maskSpreadAtMax: 1
    }
}