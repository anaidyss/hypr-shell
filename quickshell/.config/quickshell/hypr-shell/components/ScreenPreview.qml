import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import qs.theme
import "../modules/panel/PanelGeometry.js" as Geo

// A miniature of the real screen drawn from the layout tokens: wallpaper, frame with the cutout, the left rail
// and two windows with the real gaps and rounding. Also used by the frame color picker and the hot zone preview;
// children go on top of the screen, in miniature pixels (`k` converts logical pixels).
Item {
    id: root

    property real shotWidth: 460
    property bool captions: true
    property bool bands: true
    property bool showWindows: true
    property bool showGlow: true
    property color frameColor: Theme.panelBase
    default property alias overlay: overlayHolder.data

    readonly property real sw: 1560
    readonly property real sh: 1040
    readonly property real k: shotWidth / sw
    readonly property bool flush: Theme.cfg.panel.railFlush
    // Small tiles draw the frame at least this thick (in screen pixels) so its color reads.
    property real minFrame: 0
    readonly property real fw: Math.max(Theme.frameWidth, minFrame)
    readonly property real rail: Theme.railWidth
    readonly property real rad: flush ? Math.max(Theme.rounding * 1.5 * Theme.radiusScale, Theme.screenRadius) : Theme.rounding * 1.5 * Theme.radiusScale
    readonly property real go: Theme.gapsOut
    readonly property real gi: Theme.gapsIn
    readonly property rect hole: flush ? Qt.rect(rail, fw, sw - rail - fw, sh - 2 * fw) : Qt.rect(0, 0, sw, sh)
    readonly property rect area: Qt.rect(hole.x + go, hole.y + go, Math.max(0, hole.width - 2 * go), Math.max(0, hole.height - 2 * go))
    readonly property real winW: Math.max(0, (area.width - gi) / 2)

    readonly property var holePts: flush ? scaled(Geo.frameHole({ W: sw, H: sh, left: rail, top: fw, right: fw, bottom: fw, R: rad }, Theme.roundingPower)) : []
    readonly property var outerPts: scaled(Geo.roundRect(0, 0, sw, sh, Theme.screenRadius, Theme.roundingPower))

    function scaled(pts) {
        const out = []
        for (const p of pts) out.push(Qt.point(p.x * k, p.y * k))
        return out
    }

    width: parent ? parent.width : implicitWidth
    implicitHeight: screen.height

    Item {
        id: screen
        width: root.shotWidth
        height: root.shotWidth * root.sh / root.sw

        Shape {
            id: screenMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            ShapePath {
                fillColor: Theme.bg
                strokeColor: "transparent"
                PathPolyline { path: root.outerPts }
            }
        }

        Image {
            id: wall
            anchors.fill: parent
            visible: false
            asynchronous: true
            source: WallpaperSource.url
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 960
        }

        MultiEffect {
            anchors.fill: parent
            source: wall
            brightness: -0.1
            maskEnabled: true
            maskSource: screenMask
            maskThresholdMin: 0
            maskSpreadAtMin: 0
            maskThresholdMax: 1
            maskSpreadAtMax: 1
        }

        // The band between the cutout edge and the windows (gap to the screen edge)
        Rectangle {
            visible: root.bands && root.showWindows
            x: root.hole.x * root.k; y: root.hole.y * root.k
            width: root.hole.width * root.k; height: root.hole.height * root.k
            color: "transparent"
            border.width: root.go * root.k
            border.color: Theme.accent
            opacity: 0.3
        }

        Repeater {
            model: root.showWindows ? 2 : 0

            Surface {
                required property int index
                x: (root.area.x + index * (root.winW + root.gi)) * root.k
                y: root.area.y * root.k
                width: root.winW * root.k
                height: root.area.height * root.k
                radius: Theme.rounding * root.k
                power: Theme.roundingPower
                color: Theme.surface
                borderColor: index === 0 ? Theme.borderActive : Theme.border

                Column {
                    x: 10; y: 10
                    width: parent.width - 20
                    spacing: 4
                    Repeater {
                        model: [0.7, 0.45, 0.6, 0.35]
                        Rectangle {
                            required property int index
                            required property real modelData
                            width: parent.width * modelData
                            height: 4
                            radius: 2
                            color: index === 0 && parent.parent.index === 0 ? Theme.accent : Theme.panelPill
                        }
                    }
                }
            }
        }

        // The gap between the two windows
        Rectangle {
            visible: root.bands && root.showWindows
            x: (root.area.x + root.winW) * root.k
            y: root.area.y * root.k
            width: Math.max(1, root.gi * root.k)
            height: root.area.height * root.k
            color: Theme.accent
            opacity: 0.6
        }

        // Frame glow: a blurred stroke along the cutout edge, as the real panel draws it
        Shape {
            anchors.fill: parent
            visible: root.flush && root.showGlow && Theme.glowStrength > 0.01
            opacity: Theme.glowStrength
            layer.enabled: true
            layer.samples: 4
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: Math.max(6, 30 * root.k)
                blur: 1
                colorization: 1
                colorizationColor: Theme.glowColor
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: "white"
                strokeWidth: Math.max(2, 12 * root.k)
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: root.holePts }
            }
        }

        Shape {
            anchors.fill: parent
            visible: root.flush
            layer.enabled: true
            layer.samples: 4
            ShapePath {
                strokeColor: "transparent"
                fillColor: root.frameColor
                PathMultiline { paths: [root.outerPts, root.holePts] }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: Theme.border
                strokeWidth: 1
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: root.holePts }
            }
        }

        Shape {
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 4
            ShapePath {
                fillColor: "transparent"
                strokeColor: Theme.border
                strokeWidth: 1
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: root.outerPts }
            }
        }

        // Rail icons: a group at the top and a group at the bottom
        Repeater {
            model: root.flush ? 6 : 0
            Rectangle {
                required property int index
                readonly property real d: Math.max(3, 14 * root.k)
                width: d; height: d; radius: d / 2
                x: root.rail / 2 * root.k - d / 2
                y: (index < 3 ? 90 + index * 64 : root.sh - 90 - (5 - index) * 64) * root.k - d / 2
                color: Theme.textDim
            }
        }

        Item { id: overlayHolder; anchors.fill: parent }
    }

    Column {
        visible: root.captions
        anchors { left: screen.right; leftMargin: 16; right: parent.right; verticalCenter: screen.verticalCenter }
        spacing: 8

        Repeater {
            model: [
                { label: "Frame", value: root.flush ? Theme.frameWidth + " px" : "Off", swatch: 0 },
                { label: "Gap to the screen edge", value: Theme.gapsOut + " px", swatch: 1 },
                { label: "Gap between windows", value: Theme.gapsIn + " px", swatch: 1 },
                { label: "Window corners", value: Theme.rounding + " px · shape " + Theme.roundingPower, swatch: 2 },
                { label: "Screen corners", value: Theme.screenRadius + " px", swatch: 2 }
            ]

            Row {
                required property var modelData
                spacing: 8

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12; height: 12; radius: 4
                    color: modelData.swatch === 0 ? root.frameColor : (modelData.swatch === 1 ? Theme.accent : "transparent")
                    opacity: modelData.swatch === 1 ? 0.6 : 1
                    border.width: modelData.swatch === 1 ? 0 : 1
                    border.color: Theme.borderActive
                }

                Column {
                    spacing: 2
                    Text {
                        text: modelData.label
                        color: Theme.textDim
                        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                    }
                    Text {
                        text: modelData.value
                        color: Theme.text
                        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
                    }
                }
            }
        }
    }
}
