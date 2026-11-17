import QtQuick
import qs.theme
import qs.services
import qs.components

// The equalizer as one graph: a grid, a smooth curve through the ten bands filled towards 0 dB, and a point per band.
// Drag anywhere in a column to set it, scroll to nudge, double click to reset. The first column is the preamp,
// kept apart by a divider and not part of the curve.
Tile {
    id: root

    radius: Theme.radiusMd

    readonly property int cols: 11
    readonly property bool live: Equalizer.enabled
    property int hoverCol: -1
    property int dragCol: -1
    readonly property int focusCol: dragCol >= 0 ? dragCol : hoverCol

    function valueOf(c) { return c === 0 ? Equalizer.preamp : Equalizer.gains[c - 1] }
    function setValue(c, db) {
        if (c === 0) Equalizer.setPreamp(db)
        else Equalizer.setGain(c - 1, db)
    }

    Item {
        id: plot
        x: root.pad; y: root.pad
        width: root.width - 2 * root.pad
        height: root.height - 2 * root.pad - labels.height - 4

        readonly property real colW: width / root.cols
        readonly property real half: height / 2 - 10
        readonly property real zero: height / 2
        readonly property real divX: colW

        function colX(c) { return (c + 0.5) * colW }
        function yFor(db) { return zero - db / Equalizer.range * half }
        function dbAt(y) { return (zero - y) / half * Equalizer.range }
        function colAt(x) { return Math.max(0, Math.min(root.cols - 1, Math.floor(x / colW))) }

        // Hovered or dragged column
        Rectangle {
            x: plot.colX(Math.max(0, root.focusCol)) - width / 2
            width: plot.colW - 4
            height: plot.height
            radius: Theme.radiusSm
            color: Theme.panelPill
            opacity: root.focusCol >= 0 ? 1 : 0
            Behavior on x { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
            Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
        }

        // Grid: ±12, ±6 and the 0 dB line
        Repeater {
            model: [12, 6, 0, -6, -12]

            Rectangle {
                required property real modelData
                x: 0
                y: Math.round(plot.yFor(modelData))
                width: plot.width
                height: 1
                color: modelData === 0 ? Theme.textOff : Theme.panelTrack
            }
        }

        // Preamp divider
        Rectangle {
            x: Math.round(plot.divX)
            width: 1
            height: plot.height
            color: Theme.panelTrack
        }

        Canvas {
            id: curve
            anchors.fill: parent
            renderStrategy: Canvas.Cooperative

            readonly property color stroke: root.live ? Theme.accent : Theme.textDim

            onStrokeChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                if (nodes.count < root.cols) return
                const pts = [{ x: plot.divX, y: nodes.itemAt(1).cy }]
                for (let c = 1; c < root.cols; c++) pts.push({ x: plot.colX(c), y: nodes.itemAt(c).cy })
                pts.push({ x: width, y: nodes.itemAt(root.cols - 1).cy })

                // Monotone cubic (Fritsch–Carlson): smooth, but never swings past its neighbours, so flat bands stay flat
                const n = pts.length
                const d = [], m = []
                for (let i = 0; i < n - 1; i++) d.push((pts[i + 1].y - pts[i].y) / (pts[i + 1].x - pts[i].x))
                m.push(d[0])
                for (let i = 1; i < n - 1; i++) m.push(d[i - 1] * d[i] <= 0 ? 0 : (d[i - 1] + d[i]) / 2)
                m.push(d[n - 2])
                for (let i = 0; i < n - 1; i++) {
                    if (d[i] === 0) { m[i] = 0; m[i + 1] = 0; continue }
                    const a = m[i] / d[i], b = m[i + 1] / d[i], s = a * a + b * b
                    if (s > 9) { const t = 3 / Math.sqrt(s); m[i] = t * a * d[i]; m[i + 1] = t * b * d[i] }
                }
                const path = () => {
                    ctx.moveTo(pts[0].x, pts[0].y)
                    for (let i = 0; i < n - 1; i++) {
                        const h = (pts[i + 1].x - pts[i].x) / 3
                        ctx.bezierCurveTo(pts[i].x + h, pts[i].y + m[i] * h, pts[i + 1].x - h, pts[i + 1].y - m[i + 1] * h, pts[i + 1].x, pts[i + 1].y)
                    }
                }

                if (root.live) {
                    ctx.beginPath()
                    path()
                    ctx.lineTo(width, plot.zero)
                    ctx.lineTo(plot.divX, plot.zero)
                    ctx.closePath()
                    ctx.globalAlpha = 0.18
                    ctx.fillStyle = stroke
                    ctx.fill()
                    ctx.globalAlpha = 1
                }

                ctx.beginPath()
                path()
                ctx.lineWidth = 2.5
                ctx.lineJoin = "round"
                ctx.lineCap = "round"
                ctx.strokeStyle = stroke
                ctx.stroke()
            }
        }

        // Points; their animated positions drive the curve, so presets glide into place.
        Repeater {
            id: nodes
            model: root.cols

            Item {
                id: node
                required property int index
                readonly property real value: root.valueOf(index)
                readonly property bool focused: root.focusCol === index
                property real cy: plot.yFor(value)

                Behavior on cy { enabled: root.dragCol !== node.index; NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
                onCyChanged: curve.requestPaint()

                // The preamp is a level, not a band: a short line across its column
                Rectangle {
                    visible: node.index === 0
                    x: plot.colX(0) - width / 2
                    y: node.cy - height / 2
                    width: plot.colW - 16
                    height: 2
                    radius: 1
                    color: curve.stroke
                    opacity: 0.55
                }

                Rectangle {
                    readonly property real d: node.focused ? 16 : 12
                    x: plot.colX(node.index) - d / 2
                    y: node.cy - d / 2
                    width: d; height: d
                    radius: d / 2
                    color: root.live ? Theme.accent : Theme.textDim
                    border.width: 2
                    border.color: root.color
                    Behavior on width { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
                    Behavior on height { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
                }

                // Value while touched: above the point, below it near the top edge
                Rectangle {
                    readonly property bool below: node.cy < height + 16
                    x: Math.max(0, Math.min(plot.width - width, plot.colX(node.index) - width / 2))
                    y: below ? node.cy + 12 : node.cy - 12 - height
                    width: valueText.implicitWidth + 12
                    height: 20
                    radius: height / 2
                    color: Theme.panelHigh
                    opacity: node.focused ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }

                    Text {
                        id: valueText
                        anchors.centerIn: parent
                        text: {
                            const v = node.value
                            if (Math.abs(v) < 0.05) return "0 dB"
                            return (v > 0 ? "+" : "−") + (Math.abs(v) % 1 === 0 ? Math.abs(v).toFixed(0) : Math.abs(v).toFixed(1)) + " dB"
                        }
                        color: Theme.text
                        font { family: Theme.fontMono; pixelSize: 11; weight: Theme.wBold }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPositionChanged: mouse => {
                if (pressed) root.setValue(root.dragCol, plot.dbAt(mouse.y))
                else root.hoverCol = plot.colAt(mouse.x)
            }
            onExited: root.hoverCol = -1
            onPressed: mouse => {
                root.dragCol = plot.colAt(mouse.x)
                root.setValue(root.dragCol, plot.dbAt(mouse.y))
            }
            onReleased: root.dragCol = -1
            onCanceled: root.dragCol = -1
            onDoubleClicked: mouse => root.setValue(plot.colAt(mouse.x), 0)
            onWheel: wheel => {
                const c = plot.colAt(wheel.x)
                root.hoverCol = c
                root.setValue(c, root.valueOf(c) + (wheel.angleDelta.y > 0 ? 0.5 : -0.5))
            }
        }
    }

    // Band names under the columns
    Item {
        id: labels
        x: plot.x
        y: plot.y + plot.height + 4
        width: plot.width
        height: 14

        Repeater {
            model: ["Pre"].concat(Equalizer.freqs)

            Text {
                required property string modelData
                required property int index
                x: plot.colX(index) - width / 2
                text: modelData
                color: root.focusCol === index ? Theme.text : Theme.textDim
                font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
            }
        }
    }
}
