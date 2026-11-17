import QtQuick
import QtQuick.Shapes
import qs.theme

// Unified shell surface: fill, border and corner shape matching Hyprland windows (superellipse rounding_power).
Item {
    id: root

    property real radius: Theme.radiusLg
    // Per-corner overrides (-1 = `radius`): a tile that sits in the corner of a branch follows that corner.
    property real radiusTL: -1
    property real radiusTR: -1
    property real radiusBR: -1
    property real radiusBL: -1
    property real power: Theme.roundingPower
    property color color: Theme.surface
    property color borderColor: Theme.border
    property real borderWidth: 1
    // Instead of a flat color, fill the surface with the blurred wallpaper tinted by `glassTint` (glass at `glassTintAlpha`).
    property bool glassFill: false
    property color glassTint: Theme.colors.base
    property real glassTintAlpha: Theme.cfg.glass.opacity
    // An item to frost instead of the wallpaper file (see GlassFill.backdrop).
    property Item backdrop: null
    // With `order` >= 0 the surface fades in and rises a little every time it becomes visible, later for higher orders.
    property int order: -1
    property real enter: 1

    opacity: order >= 0 ? enter : 1
    transform: Translate { y: root.order >= 0 ? (1 - root.enter) * 12 : 0 }

    onVisibleChanged: if (visible && order >= 0) enterAnim.restart()

    SequentialAnimation {
        id: enterAnim
        PropertyAction { target: root; property: "enter"; value: 0 }
        PauseAnimation { duration: Math.max(0, root.order) * 55 }
        NumberAnimation { target: root; property: "enter"; to: 1; duration: Theme.durSlow; easing.type: Theme.easing; easing.overshoot: Theme.overshoot }
    }

    readonly property var outline: build(width, height,
        [radiusTL < 0 ? radius : radiusTL, radiusTR < 0 ? radius : radiusTR, radiusBR < 0 ? radius : radiusBR, radiusBL < 0 ? radius : radiusBL],
        power, borderWidth / 2)

    // `r` holds the corner radii clockwise from the top left.
    function build(w, h, r, p, inset) {
        const x0 = inset, y0 = inset, x1 = w - inset, y1 = h - inset
        const rr = r.map(v => Math.max(0, Math.min(v - inset, (x1 - x0) / 2, (y1 - y0) / 2)))
        const e = 2 / Math.max(2, p)
        const pts = []
        function corner(q, emit) {
            const n = rr[q] < 1 ? 1 : 14
            for (let i = 0; i <= n; i++) {
                const t = Math.PI / 2 * i / n
                emit(rr[q], rr[q] * Math.pow(Math.cos(t), e), rr[q] * Math.pow(Math.sin(t), e))
            }
        }
        corner(0, (k, c, s) => pts.push(Qt.point(x0 + k - c, y0 + k - s)))
        corner(1, (k, c, s) => pts.push(Qt.point(x1 - k + s, y0 + k - c)))
        corner(2, (k, c, s) => pts.push(Qt.point(x1 - k + c, y1 - k + s)))
        corner(3, (k, c, s) => pts.push(Qt.point(x0 + k - s, y1 - k + c)))
        pts.push(pts[0])
        return pts
    }

    // White superellipse mask for the glass fill; it stays under the GlassFill, which covers it with blurred wallpaper.
    Shape {
        id: glassMask
        anchors.fill: parent
        visible: root.glassFill
        layer.enabled: root.glassFill
        layer.samples: 4
        ShapePath {
            fillColor: "white"
            strokeColor: "transparent"
            PathPolyline { path: root.outline }
        }
    }

    GlassFill {
        anchors.fill: parent
        visible: root.glassFill
        maskItem: glassMask
        backdrop: root.backdrop
        maxBlur: root.backdrop ? 48 : Theme.cfg.blur.size * Theme.cfg.blur.passes
        tintAlpha: 0
    }

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            fillColor: root.glassFill ? Qt.alpha(root.glassTint, root.glassTintAlpha) : root.color
            strokeColor: root.borderWidth > 0 ? root.borderColor : "transparent"
            strokeWidth: root.borderWidth
            joinStyle: ShapePath.RoundJoin

            PathPolyline { path: root.outline }
        }

        // Glass: the surface's own color is a thin veil on top of the tinted blur, as on the panel.
        ShapePath {
            fillColor: root.glassFill ? root.color : "transparent"
            strokeColor: "transparent"

            PathPolyline { path: root.outline }
        }
    }
}
