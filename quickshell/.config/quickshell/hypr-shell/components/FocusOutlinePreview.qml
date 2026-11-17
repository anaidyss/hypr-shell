import QtQuick
import qs.theme

// Settings preview for the focused window outline: a focused and an unfocused mini window drawn with the same
// colors, thickness, shading and angle the compositor gets (conf/look.lua). The motion of the real thing is not shown.
Item {
    id: root

    readonly property var fo: Theme.cfg.focus
    readonly property var order: [Theme.colors.primary, Theme.colors.tertiary, Theme.colors.secondary]
    readonly property var stops: {
        const f = root.fo
        const n = Math.max(1, Math.min(3, f.colors))
        const out = []
        for (let i = 0; i < n; i++) {
            const h = Math.max(0, root.order[i].hslHue)
            out.push(Qt.hsla(h, f.saturation, Math.min(0.92, f.lightness + f.shade), f.opacity))
            out.push(Qt.hsla(h, f.saturation, Math.max(0.12, f.lightness - f.shade), f.opacity))
        }
        out.push(out[0])
        return out
    }
    readonly property int ringSize: root.fo.enabled ? root.fo.size : 0

    width: parent ? parent.width : implicitWidth
    implicitHeight: 148

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMd
        color: Theme.panelBase
    }

    Row {
        anchors.centerIn: parent
        spacing: 24

        Repeater {
            model: [{ label: "Focused", on: true }, { label: "Unfocused", on: false }]

            delegate: Item {
                id: card
                required property var modelData
                width: 180
                height: 120

                // The window body
                Rectangle {
                    id: body
                    width: parent.width
                    height: 92
                    radius: Theme.radiusSm
                    color: Theme.colors.base
                    border.width: card.modelData.on ? 0 : 1
                    border.color: Theme.border

                    Column {
                        x: 14; y: 14
                        spacing: 8
                        Rectangle { width: 40; height: 6; radius: 3; color: Theme.accent }
                        Rectangle { width: 120; height: 5; radius: 2.5; color: Theme.separator }
                        Rectangle { width: 92; height: 5; radius: 2.5; color: Theme.separator }
                    }

                    // The outline: a gradient filled rounded rectangle with the window cut out of it.
                    Canvas {
                        id: ring
                        visible: card.modelData.on && root.ringSize > 0
                        anchors.fill: parent
                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.reset()
                            const w = width, h = height, r = body.radius, b = root.ringSize
                            const a = root.fo.angle * Math.PI / 180
                            const dx = Math.sin(a), dy = -Math.cos(a)
                            const half = Math.abs(dx) * w / 2 + Math.abs(dy) * h / 2
                            const g = ctx.createLinearGradient(w / 2 - dx * half, h / 2 - dy * half, w / 2 + dx * half, h / 2 + dy * half)
                            const st = root.stops
                            for (let i = 0; i < st.length; i++) g.addColorStop(i / (st.length - 1), st[i])
                            function rr(x, y, ww, hh, rad) {
                                rad = Math.max(0, Math.min(rad, ww / 2, hh / 2))
                                ctx.beginPath()
                                ctx.moveTo(x + rad, y)
                                ctx.arcTo(x + ww, y, x + ww, y + hh, rad)
                                ctx.arcTo(x + ww, y + hh, x, y + hh, rad)
                                ctx.arcTo(x, y + hh, x, y, rad)
                                ctx.arcTo(x, y, x + ww, y, rad)
                                ctx.closePath()
                            }
                            ctx.fillStyle = g
                            rr(0, 0, w, h, r)
                            ctx.fill()
                            ctx.globalCompositeOperation = "destination-out"
                            rr(b, b, w - 2 * b, h - 2 * b, r - b)
                            ctx.fill()
                        }
                        Connections {
                            target: root
                            function onStopsChanged() { ring.requestPaint() }
                            function onRingSizeChanged() { ring.requestPaint() }
                        }
                        Connections {
                            target: root.fo
                            function onAngleChanged() { ring.requestPaint() }
                        }
                        onWidthChanged: requestPaint()
                        onVisibleChanged: if (visible) requestPaint()
                    }
                }

                Text {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                    text: card.modelData.label
                    color: card.modelData.on ? Theme.text : Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                }
            }
        }
    }
}
