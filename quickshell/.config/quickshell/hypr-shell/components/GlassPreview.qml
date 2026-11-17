import QtQuick
import QtQuick.Effects
import qs.theme

// Settings preview for the panel glass: the wallpaper, and a panel card over it built from the same blur,
// brightness, contrast, grain and opacity tokens. Read-only; the sliders below edit the values.
Item {
    id: root

    readonly property real blurPx: Math.min(64, Theme.cfg.blur.size * Theme.cfg.blur.passes * 0.5)
    readonly property int cardRadius: Theme.radiusMd

    width: parent ? parent.width : implicitWidth
    implicitHeight: 148

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
        id: card
        x: root.width * 0.38
        y: 12
        width: root.width * 0.58
        height: root.height - 24

        Rectangle { id: cardMask; anchors.fill: parent; radius: root.cardRadius; color: "white"; layer.enabled: true }
        MultiEffect {
            anchors.fill: parent
            source: wall
            blurEnabled: true
            autoPaddingEnabled: false
            blurMax: 64
            blur: Math.min(1, root.blurPx / 64) * Theme.glassBlurAmount
            saturation: 0
            brightness: Theme.cfg.blur.brightness - 1
            contrast: Theme.cfg.blur.contrast - 1
            colorizationColor: Theme.panelBase
            colorization: Theme.cfg.glass.opacity
            maskEnabled: true
            maskSource: cardMask
            maskThresholdMin: 0
            maskSpreadAtMin: 0
            maskThresholdMax: 1
            maskSpreadAtMax: 1
        }

        // The light scheme's fill sits on top of the blur at its own (denser) opacity, as on the real panel.
        Rectangle {
            anchors.fill: parent
            visible: Theme.isLight
            radius: root.cardRadius
            color: Theme.panelFill
        }

        // Grain: sparse light dots whose strength follows blur.noise.
        Canvas {
            anchors { fill: parent; margins: 10 }
            opacity: Math.min(1, Theme.cfg.blur.noise * 8)
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                let seed = 7
                for (let i = 0; i < 900; i++) {
                    seed = (seed * 1103515245 + 12345) & 0x7fffffff
                    const x = seed % Math.max(1, Math.floor(width))
                    seed = (seed * 1103515245 + 12345) & 0x7fffffff
                    const y = seed % Math.max(1, Math.floor(height))
                    ctx.fillStyle = i % 2 === 0 ? "rgba(255,255,255,0.5)" : "rgba(0,0,0,0.5)"
                    ctx.fillRect(x, y, 1, 1)
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: root.cardRadius
            color: "transparent"
            border.width: 1
            border.color: Theme.border
        }

        Column {
            anchors { fill: parent; margins: 16 }
            spacing: 8

            Row {
                height: 16
                spacing: 8
                PanelIcon { anchors.verticalCenter: parent.verticalCenter; name: "pulse"; size: 16; color: Theme.accent2 }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "PERFORMANCE"
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy; letterSpacing: 1.3 }
                }
            }

            Row {
                width: parent.width
                spacing: Theme.gapTile
                Repeater {
                    model: [{ v: "6.4 GB", l: "Memory" }, { v: "8%", l: "CPU" }]
                    Rectangle {
                        required property var modelData
                        width: (parent.width - Theme.gapTile) / 2
                        height: 52
                        radius: Theme.radiusSm
                        color: Theme.panelRaised
                        Column {
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 12 }
                            Text { text: modelData.l; color: Theme.textDim; font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold } }
                            Text { text: modelData.v; color: Theme.text; font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong } }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        x: 12
        y: root.height - height - 12
        width: leftLabel.implicitWidth + 16
        height: 22
        radius: 8
        color: Theme.blockGlass
        Text {
            id: leftLabel
            anchors.centerIn: parent
            text: "WITHOUT GLASS"
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy; letterSpacing: 1.3 }
        }
    }

    Rectangle {
        x: card.x + card.width - width - 16
        y: card.y + 14
        width: rightLabel.implicitWidth + 16
        height: 22
        radius: 8
        color: Theme.panelPill
        Text {
            id: rightLabel
            anchors.centerIn: parent
            text: "WITH GLASS"
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy; letterSpacing: 1.3 }
        }
    }
}
