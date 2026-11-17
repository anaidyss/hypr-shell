import QtQuick
import "shot.js" as Shot

// Drawing state of the screenshot editor: active tool, style, the marks and their undo history.
QtObject {
    id: root

    property string tool: "move"
    property string color: "#ff5a5f"
    property real width: 4
    property bool fill: false

    // Each history entry is a complete list of marks; undo and redo only move the position.
    property var history: [[]]
    property int pos: 0
    readonly property var items: history[pos] || []
    property var cur: null

    readonly property bool canUndo: pos > 0
    readonly property bool canRedo: pos < history.length - 1
    readonly property bool dragTool: ["pen", "marker", "line", "arrow", "rect", "ellipse", "pixel"].indexOf(tool) >= 0
    readonly property bool usesColor: ["pen", "marker", "line", "arrow", "rect", "ellipse", "text", "num"].indexOf(tool) >= 0
    readonly property bool usesWidth: ["pen", "marker", "line", "arrow", "rect", "ellipse", "text", "num"].indexOf(tool) >= 0
    readonly property bool usesFill: tool === "rect" || tool === "ellipse"

    function commit(list) {
        history = history.slice(0, pos + 1).concat([list])
        pos = history.length - 1
    }

    function undo() { if (canUndo) pos-- }
    function redo() { if (canRedo) pos++ }
    function clear() { if (items.length > 0) commit([]) }
    function reset() { pos = 0; history = [[]]; cur = null }

    function begin(x, y) {
        cur = { t: tool, c: color, w: width, f: fill && usesFill, x0: x, y0: y, x1: x, y1: y, pts: [x, y] }
    }

    function update(x, y, shift) {
        if (!cur) return
        if (cur.t === "pen" || cur.t === "marker") {
            const n = cur.pts.length
            if (Math.hypot(x - cur.pts[n - 2], y - cur.pts[n - 1]) < 1.5) return
            cur.pts.push(x, y)
        } else {
            const p = shift ? Shot.constrain(cur, x, y) : { x: x, y: y }
            cur.x1 = p.x
            cur.y1 = p.y
        }
        curChanged()
    }

    function finish() {
        const m = cur
        cur = null
        if (!m) return
        const tiny = (m.t === "pen" || m.t === "marker") ? m.pts.length < 4 : Math.hypot(m.x1 - m.x0, m.y1 - m.y0) < 4
        if (tiny) return
        if (m.t === "pixel" && (Math.abs(m.x1 - m.x0) < 6 || Math.abs(m.y1 - m.y0) < 6)) return
        commit(items.concat([m]))
    }

    function placeNumber(x, y) {
        let n = 0
        for (const m of items) if (m.t === "num") n = Math.max(n, m.n)
        commit(items.concat([{ t: "num", c: color, w: width, f: true, x0: x, y0: y, n: n + 1 }]))
    }

    function addText(x, y, s, textWidth) {
        if (s.trim() === "") return
        commit(items.concat([{ t: "text", c: color, w: width, f: false, x0: x, y0: y, s: s, tw: textWidth }]))
    }

    function eraseAt(x, y) {
        for (let i = items.length - 1; i >= 0; i--) {
            if (Shot.hit(items[i], x, y)) {
                const next = items.slice()
                next.splice(i, 1)
                commit(next)
                return true
            }
        }
        return false
    }
}
