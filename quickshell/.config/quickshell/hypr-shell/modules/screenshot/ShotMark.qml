import QtQuick
import QtQuick.Shapes
import qs.theme
import "shot.js" as Shot

// One mark of the screenshot editor; `base` is the item pixelate marks sample from.
Item {
    id: root

    property var m
    property Item base

    readonly property string kind: m ? m.t : ""
    readonly property bool stroked: ["pen", "marker", "line", "arrow", "rect", "ellipse"].indexOf(kind) >= 0
    readonly property bool marker: kind === "marker"

    // Highlighter strokes share one layer so a stroke crossing itself does not get darker.
    layer.enabled: marker
    opacity: marker ? 0.4 : 1

    Shape {
        anchors.fill: parent
        visible: root.stroked
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.stroked ? root.m.c : "transparent"
            strokeWidth: root.marker ? Shot.markerWidth(root.m.w) : (root.stroked ? root.m.w : 0)
            fillColor: root.stroked && root.m.f ? Qt.alpha(root.m.c, 0.28) : "transparent"
            capStyle: root.marker ? ShapePath.FlatCap : ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: root.stroked ? Shot.path(root.m) : [] }
        }

        ShapePath {
            strokeColor: "transparent"
            fillColor: root.kind === "arrow" ? root.m.c : "transparent"
            PathPolyline { path: root.kind === "arrow" ? Shot.arrowHead(root.m) : [] }
        }
    }

    Rectangle {
        visible: root.kind === "num"
        readonly property real r: root.kind === "num" ? Shot.numRadius(root.m.w) : 0
        x: root.kind === "num" ? root.m.x0 - r : 0
        y: root.kind === "num" ? root.m.y0 - r : 0
        width: r * 2
        height: r * 2
        radius: r
        color: root.kind === "num" ? root.m.c : "transparent"

        Text {
            anchors.centerIn: parent
            text: root.kind === "num" ? root.m.n : ""
            color: root.kind === "num" && Shot.luminance(root.m.c) > 0.6 ? "#111111" : "#ffffff"
            font { family: Theme.fontUi; pixelSize: parent.r * 1.15; weight: Theme.wBold }
        }
    }

    Text {
        id: label
        visible: root.kind === "text"
        x: root.kind === "text" ? root.m.x0 : 0
        y: root.kind === "text" ? root.m.y0 : 0
        text: root.kind === "text" ? root.m.s : ""
        color: root.kind === "text" ? root.m.c : "transparent"
        font { family: Theme.fontUi; pixelSize: root.kind === "text" ? Shot.textSize(root.m.w) : 12; weight: Theme.wStrong }
    }

    // Redaction: the area is sampled at a coarse texture and stretched back without smoothing.
    ShaderEffectSource {
        readonly property var r: root.kind === "pixel" ? Shot.rectOf(root.m) : ({ x: 0, y: 0, w: 1, h: 1 })
        visible: root.kind === "pixel" && root.base !== null
        sourceItem: root.base
        sourceRect: Qt.rect(r.x, r.y, r.w, r.h)
        textureSize: Qt.size(Math.max(1, Math.round(r.w / 7)), Math.max(1, Math.round(r.h / 7)))
        smooth: false
        x: r.x
        y: r.y
        width: r.w
        height: r.h
    }
}
