import QtQuick
import QtQuick.Effects
import qs.theme

// A blurred, desaturated copy of the active wallpaper. The shell's glass base: place a tinted fill on top of it.
// `maskItem` optionally clips the backdrop to a shape (opaque white = kept, transparent = cut out).
Item {
    id: root

    property Item maskItem: null
    property real strength: Theme.glassBlurAmount
    // Match the compositor blur (theme.blur.size × passes) so the shell glass reads like the old layer blur.
    property int maxBlur: Theme.cfg.blur.size * Theme.cfg.blur.passes
    property real saturation: 0
    property real brightness: Theme.cfg.blur.brightness - 1

    Image {
        id: img
        anchors.fill: parent
        visible: false
        asynchronous: true
        cache: true
        source: WallpaperSource.url
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(Math.max(256, root.width), Math.max(256, root.height))
    }

    MultiEffect {
        anchors.fill: parent
        source: img
        blurEnabled: true
        blurMax: root.maxBlur
        blur: root.strength
        saturation: root.saturation
        brightness: root.brightness
        maskEnabled: root.maskItem !== null
        maskSource: root.maskItem
        maskThresholdMin: 0
        maskSpreadAtMin: 0
        maskThresholdMax: 1
        maskSpreadAtMax: 1
    }
}