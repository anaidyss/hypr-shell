import QtQuick
import QtQuick.Effects
import qs.theme

// Settings preview for the terminal: a mini kitty window over the wallpaper with the configured opacity,
// blurred behind when terminal blur is on. Read-only.
Item {
    id: root

    // The real kitty background (see hs-apps `term_bg`).
    readonly property real tint: Theme.cfg.terminal.tint
    readonly property color hueSource: Theme.solid ? (Theme.panelBase.hslSaturation > 0.02 ? Theme.panelBase : Theme.colors.primary) : Theme.colors.base
    readonly property color termBg: Theme.isLight ? (Theme.solid ? Qt.tint("#f2f2f4", Qt.alpha(Theme.panelBase, 0.22))
        : Qt.tint("#f6f6f7", Qt.alpha(Theme.colors.base, 0.5)))
        : Qt.hsla(hueSource.hslHue, tint, Theme.solid ? Math.min(0.32, Theme.panelBase.hslLightness + 0.04) : 0.07, 1)
    readonly property real termOpacity: Theme.solid ? Theme.cfg.terminal.solidOpacity : Theme.cfg.terminal.opacity
    readonly property bool blurred: Theme.solid || Theme.cfg.terminal.blur
    readonly property int termRadius: Theme.radiusMd

    width: parent ? parent.width : implicitWidth
    implicitHeight: 150

    Image {
        id: wall
        anchors.fill: parent
        visible: false
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        source: WallpaperSource.url
        sourceSize: Qt.size(720, 360)
    }

    Rectangle { id: backMask; anchors.fill: parent; radius: Theme.radiusMd; color: "white"; layer.enabled: true }
    MultiEffect {
        anchors.fill: parent
        source: wall
        maskEnabled: true
        maskSource: backMask
        maskThresholdMin: 0
        maskSpreadAtMin: 0
        maskThresholdMax: 1
        maskSpreadAtMax: 1
    }

    Item {
        id: term
        x: 16
        y: 14
        width: Math.min(root.width - 32, 440)
        height: root.height - 28

        Rectangle { id: termMask; anchors.fill: parent; radius: root.termRadius; color: "white"; layer.enabled: true }

        MultiEffect {
            anchors.fill: parent
            visible: root.blurred
            source: wall
            blurEnabled: true
            autoPaddingEnabled: false
            blurMax: 64
            blur: 0.5
            saturation: 0
            brightness: Theme.cfg.blur.brightness - 1
            maskEnabled: true
            maskSource: termMask
            maskThresholdMin: 0
            maskSpreadAtMin: 0
            maskThresholdMax: 1
            maskSpreadAtMax: 1
        }

        Rectangle {
            anchors.fill: parent
            radius: root.termRadius
            color: Qt.alpha(root.termBg, root.termOpacity)
            border.width: 1
            border.color: Theme.panelBase
        }

        Column {
            anchors { fill: parent; margins: 16 }
            spacing: 4

            Row {
                spacing: 8
                Text { text: "~/hypr-shell"; color: Theme.accent; font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold } }
                Text { text: "main"; color: Theme.colors.secondary; font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold } }
                Text { text: ">"; color: Theme.accent; font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold } }
                Text { text: "ls"; color: Theme.text; font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold } }
            }
            Row {
                spacing: 12
                Text { text: "bin"; color: Theme.colors.secondary; font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold } }
                Text { text: "quickshell"; color: Theme.colors.tertiary; font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold } }
                Text { text: "theme"; color: Theme.colors.secondary; font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold } }
                Text { text: "DESIGN.md"; color: Theme.text; font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold } }
            }
            Text { text: "error: file not found"; color: Theme.danger; font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold } }
            Row {
                spacing: 8
                Text { text: "build ok in 1.2 s"; color: Theme.success; font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold } }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8; height: 14; color: Theme.text }
            }
        }
    }

    Text {
        anchors { left: term.right; leftMargin: 16; right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        visible: width > 80
        wrapMode: Text.WordWrap
        text: Math.round(root.termOpacity * 100) + "% opaque" + (root.blurred ? ", blurred" : ", sharp")
        color: Theme.text
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
        style: Text.Outline
        styleColor: Theme.blockGlass
    }
}
