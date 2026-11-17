import QtQuick
import QtQuick.Shapes
import qs.theme

// A chart of recent samples, right-aligned so a young history grows in from the right edge.
// kind: area (gradient fill), line (line only), step (held values), dots (dotted line), bars (histogram),
// blocks (segmented equalizer columns), mirror (`values` up, `values2` down).
Item {
    id: root

    property var values: []
    property var values2: []
    property int count: 60
    property string kind: "area"
    // `max` fixes the top of the scale; 0 scales to the data (at least `floor`). `min` is the bottom.
    property real max: 0
    property real min: 0
    property real floor: 0
    // Zoom the scale onto the data (at least `fitSpan` tall) instead of using min..max
    property bool fit: false
    property real fitSpan: 0.05
    property int grid: 2
    // Samples between vertical time ticks; 0 hides them
    property int tickEvery: 0
    // Bars above this level are drawn in the danger colour; 0 disables
    property real hotAt: 0
    // Whether area and step charts fill below the line
    property bool filled: true
    // A dashed warning line at this value; 0 hides it
    property real limit: 0
    property bool showAverage: false
    property color color: Theme.accent
    property color color2: Theme.accent2
    property real lineWidth: 1.6

    // Blocks merge neighbouring samples so each column is wide enough to read as a segmented bar
    readonly property int bucket: kind === "blocks" ? Math.max(1, Math.ceil(3 / Math.max(0.1, step))) : 1
    readonly property real barWidth: Math.max(1, step * bucket * (kind === "blocks" ? 0.72 : 0.62))

    readonly property real step: count > 1 ? width / (count - 1) : width
    readonly property bool mirrored: kind === "mirror"
    readonly property bool barred: kind === "bars" || kind === "blocks" || kind === "mirror"
    readonly property bool drawn: values.length > 1

    function span(a) {
        let m = 0
        for (let i = 0; i < a.length; i++) if (a[i] > m) m = a[i]
        return m
    }

    readonly property real peak: Math.max(span(values), span(values2))
    readonly property real average: {
        let s = 0
        for (let i = 0; i < values.length; i++) s += values[i]
        return values.length > 0 ? s / values.length : 0
    }
    readonly property real lowest: {
        if (values.length === 0) return 0
        let m = values[0]
        for (let i = 1; i < values.length; i++) if (values[i] < m) m = values[i]
        return m
    }
    readonly property real fitSize: Math.max(fitSpan, peak - lowest)
    readonly property real fitMid: (peak + lowest) / 2
    readonly property real scaleLow: fit ? fitMid - fitSize * 0.65 : min
    readonly property real ceiling: {
        if (fit) return fitMid + fitSize * 0.65
        if (max > 0) return max
        const m = Math.max(floor, peak)
        return m > min ? m : min + 1
    }

    function level(v) { return Math.max(0, Math.min(1, (v - scaleLow) / (ceiling - scaleLow))) }
    function xAt(i, n) { return width - (n - 1 - i) * step }
    function yAt(v) { return 1 + (height - 2) * (1 - level(v)) }

    function linePoints(vals, held) {
        const n = vals.length
        const out = []
        if (n < 2 || width <= 0) return out
        for (let i = 0; i < n; i++) {
            const x = xAt(i, n)
            if (held && i > 0) out.push(Qt.point(x, yAt(vals[i - 1])))
            out.push(Qt.point(x, yAt(vals[i])))
        }
        return out
    }

    function barLines(vals, up, from, to) {
        const n = vals.length
        const out = []
        if (n < 2 || width <= 0) return out
        const half = height / 2
        const base = mirrored ? half : height
        const room = mirrored ? half - 1 : height - 2
        for (let i = n - 1; i >= 0; i -= bucket) {
            let v = vals[i]
            for (let j = 1; j < bucket && i - j >= 0; j++) v = Math.max(v, vals[i - j])
            const l = level(v)
            if (l < from || l >= to) continue
            const len = Math.max(1, l * room)
            const x = xAt(i, n)
            out.push([Qt.point(x, base), Qt.point(x, up ? base - len : base + len)])
        }
        return out
    }

    readonly property var curve: !barred && drawn ? linePoints(values, kind === "step") : []
    readonly property var fillArea: filled && (kind === "area" || kind === "step") && curve.length > 0
        ? curve.concat([Qt.point(width, height), Qt.point(curve[0].x, height)]) : []
    readonly property bool columns: kind === "bars" || kind === "blocks"
    readonly property var barsCalm: columns ? barLines(values, true, 0, hotAt > 0 ? hotAt : 2)
        : mirrored ? barLines(values, true, 0, 2) : []
    readonly property var barsHot: columns && hotAt > 0 ? barLines(values, true, hotAt, 2) : []
    readonly property var barsDown: mirrored ? barLines(values2, false, 0, 2) : []

    readonly property var gridLines: {
        const out = []
        for (let i = 1; i <= grid; i++) {
            const y = Math.round(height * i / (grid + 1)) + 0.5
            out.push([Qt.point(0, y), Qt.point(width, y)])
        }
        return out
    }
    readonly property var tickLines: {
        const out = []
        if (tickEvery <= 0) return out
        for (let i = tickEvery; i < count; i += tickEvery) {
            const x = Math.round(width - i * step) + 0.5
            if (x > 0) out.push([Qt.point(x, 0), Qt.point(x, height)])
        }
        return out
    }
    readonly property var limitLine: limit > scaleLow && limit < ceiling && drawn
        ? [Qt.point(0, Math.round(yAt(limit)) + 0.5), Qt.point(width, Math.round(yAt(limit)) + 0.5)] : []
    readonly property var averageLine: showAverage && drawn
        ? [Qt.point(0, Math.round(yAt(average)) + 0.5), Qt.point(width, Math.round(yAt(average)) + 0.5)] : []

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.separator
            strokeWidth: 1
            PathMultiline { paths: root.tickLines }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.panelPill
            strokeWidth: 1
            PathMultiline { paths: root.gridLines }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.panelTrackHigh
            strokeWidth: 1
            PathMultiline { paths: root.mirrored ? [[Qt.point(0, Math.round(root.height / 2) + 0.5), Qt.point(root.width, Math.round(root.height / 2) + 0.5)]] : [] }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.color
            strokeWidth: root.barWidth
            strokeStyle: root.kind === "blocks" ? ShapePath.DashLine : ShapePath.SolidLine
            dashPattern: [3 / root.barWidth, 1.6 / root.barWidth]
            capStyle: ShapePath.FlatCap
            PathMultiline { paths: root.barsCalm }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.danger
            strokeWidth: root.barWidth
            strokeStyle: root.kind === "blocks" ? ShapePath.DashLine : ShapePath.SolidLine
            dashPattern: [3 / root.barWidth, 1.6 / root.barWidth]
            capStyle: ShapePath.FlatCap
            PathMultiline { paths: root.barsHot }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.color2
            strokeWidth: root.barWidth
            capStyle: ShapePath.FlatCap
            PathMultiline { paths: root.barsDown }
        }

        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: 0; x2: 0; y2: root.height
                GradientStop { position: 0; color: Qt.alpha(root.color, 0.34) }
                GradientStop { position: 0.55; color: Qt.alpha(root.color, 0.2) }
                GradientStop { position: 1; color: Qt.alpha(root.color, 0) }
            }
            PathPolyline { path: root.fillArea }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.color
            strokeWidth: root.kind === "dots" ? 2.4 : root.lineWidth
            strokeStyle: root.kind === "dots" ? ShapePath.DashLine : ShapePath.SolidLine
            dashPattern: [0.01, 1.5]
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathPolyline { path: root.curve }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.textDim
            strokeWidth: 1
            strokeStyle: ShapePath.DashLine
            dashPattern: [3, 4]
            PathPolyline { path: root.averageLine }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.alpha(Theme.danger, 0.6)
            strokeWidth: 1
            strokeStyle: ShapePath.DashLine
            dashPattern: [5, 3]
            PathMultiline { paths: root.limitLine.length > 0 ? [root.limitLine] : [] }
        }
    }

    // The latest sample
    Rectangle {
        visible: root.curve.length > 0
        width: 6; height: 6; radius: 3
        x: root.width - 4
        y: root.curve.length > 0 ? root.curve[root.curve.length - 1].y - 3 : 0
        color: root.color
        Behavior on y { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
    }
}
