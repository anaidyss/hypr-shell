.pragma library

// Marks are plain objects in monitor-local logical pixels:
//   pen/marker: pts (flat x,y list); line/arrow/rect/ellipse/pixel: x0,y0,x1,y1; text: x0,y0,s; num: x0,y0,n.
// Every mark also carries c (color), w (line width step) and f (filled).

function textSize(w) { return w <= 2 ? 18 : (w <= 4 ? 26 : 38) }
function numRadius(w) { return w <= 2 ? 11 : (w <= 4 ? 14 : 19) }
function markerWidth(w) { return w * 3.5 }

function rectOf(m) {
    return { x: Math.min(m.x0, m.x1), y: Math.min(m.y0, m.y1), w: Math.abs(m.x1 - m.x0), h: Math.abs(m.y1 - m.y0) }
}

// Chaikin corner cutting keeps hand-drawn strokes round without storing every pointer sample.
function smooth(flat) {
    let pts = []
    for (let i = 0; i + 1 < flat.length; i += 2) pts.push([flat[i], flat[i + 1]])
    for (let pass = 0; pass < 2 && pts.length > 2; pass++) {
        const next = [pts[0]]
        for (let i = 0; i < pts.length - 1; i++) {
            const a = pts[i], b = pts[i + 1]
            next.push([a[0] * 0.75 + b[0] * 0.25, a[1] * 0.75 + b[1] * 0.25])
            next.push([a[0] * 0.25 + b[0] * 0.75, a[1] * 0.25 + b[1] * 0.75])
        }
        next.push(pts[pts.length - 1])
        pts = next
    }
    return pts.map(p => Qt.point(p[0], p[1]))
}

function roundedRect(x, y, w, h, r) {
    r = Math.max(0, Math.min(r, w / 2, h / 2))
    const pts = []
    const n = r < 1 ? 1 : 8
    const corner = (cx, cy, a0) => {
        for (let i = 0; i <= n; i++) {
            const a = (a0 + 90 * i / n) * Math.PI / 180
            pts.push(Qt.point(cx + r * Math.cos(a), cy + r * Math.sin(a)))
        }
    }
    corner(x + r, y + r, 180)
    corner(x + w - r, y + r, 270)
    corner(x + w - r, y + h - r, 0)
    corner(x + r, y + h - r, 90)
    pts.push(pts[0])
    return pts
}

function ellipse(x, y, w, h) {
    const pts = []
    const n = 72
    for (let i = 0; i <= n; i++) {
        const a = Math.PI * 2 * i / n
        pts.push(Qt.point(x + w / 2 + w / 2 * Math.cos(a), y + h / 2 + h / 2 * Math.sin(a)))
    }
    return pts
}

function headSize(w) { return 8 + w * 3.2 }

// Shaft stops at the base of the head so a wide stroke does not poke through the tip.
function arrowShaft(m) {
    const dx = m.x1 - m.x0, dy = m.y1 - m.y0
    const len = Math.hypot(dx, dy)
    if (len < 1) return [Qt.point(m.x0, m.y0), Qt.point(m.x1, m.y1)]
    const back = Math.min(headSize(m.w) * 0.8, len)
    return [Qt.point(m.x0, m.y0), Qt.point(m.x1 - dx / len * back, m.y1 - dy / len * back)]
}

function arrowHead(m) {
    const dx = m.x1 - m.x0, dy = m.y1 - m.y0
    const len = Math.hypot(dx, dy)
    if (len < 1) return []
    const ux = dx / len, uy = dy / len
    const s = Math.min(headSize(m.w), len)
    const bx = m.x1 - ux * s, by = m.y1 - uy * s
    const nx = -uy * s * 0.46, ny = ux * s * 0.46
    return [Qt.point(m.x1, m.y1), Qt.point(bx + nx, by + ny), Qt.point(bx - nx, by - ny), Qt.point(m.x1, m.y1)]
}

// Outline of a stroke-type mark.
function path(m) {
    switch (m.t) {
    case "pen":
    case "marker": return smooth(m.pts)
    case "line": return [Qt.point(m.x0, m.y0), Qt.point(m.x1, m.y1)]
    case "arrow": return arrowShaft(m)
    case "rect": { const r = rectOf(m); return roundedRect(r.x, r.y, r.w, r.h, 6) }
    case "ellipse": { const r = rectOf(m); return ellipse(r.x, r.y, r.w, r.h) }
    }
    return []
}

function distToSegment(px, py, x0, y0, x1, y1) {
    const dx = x1 - x0, dy = y1 - y0
    const l2 = dx * dx + dy * dy
    let t = l2 === 0 ? 0 : ((px - x0) * dx + (py - y0) * dy) / l2
    t = Math.max(0, Math.min(1, t))
    return Math.hypot(px - (x0 + t * dx), py - (y0 + t * dy))
}

function nearPolyline(pts, x, y, tol) {
    for (let i = 0; i + 1 < pts.length; i++)
        if (distToSegment(x, y, pts[i].x, pts[i].y, pts[i + 1].x, pts[i + 1].y) <= tol) return true
    return false
}

function inRect(r, x, y, pad) {
    return x >= r.x - pad && x <= r.x + r.w + pad && y >= r.y - pad && y <= r.y + r.h + pad
}

// Text is measured by the view, which stores the width in tw once it has laid the text out.
function hit(m, x, y) {
    const tol = Math.max(7, m.w * 2)
    switch (m.t) {
    case "pen":
    case "marker": return nearPolyline(smooth(m.pts), x, y, m.t === "marker" ? markerWidth(m.w) / 2 + 4 : tol)
    case "line":
    case "arrow": return distToSegment(x, y, m.x0, m.y0, m.x1, m.y1) <= tol
    case "rect":
    case "ellipse": {
        const r = rectOf(m)
        if (m.f) return inRect(r, x, y, 4)
        return nearPolyline(path(m), x, y, tol)
    }
    case "pixel": return inRect(rectOf(m), x, y, 0)
    case "num": return Math.hypot(x - m.x0, y - m.y0) <= numRadius(m.w) + 4
    case "text": return inRect({ x: m.x0, y: m.y0, w: m.tw || 40, h: textSize(m.w) * 1.4 }, x, y, 4)
    }
    return false
}

// Shift constrains lines to 45 degree steps and boxes to squares.
function constrain(m, x, y) {
    if (m.t === "line" || m.t === "arrow") {
        const dx = x - m.x0, dy = y - m.y0
        const a = Math.round(Math.atan2(dy, dx) / (Math.PI / 4)) * (Math.PI / 4)
        const d = Math.hypot(dx, dy)
        return { x: m.x0 + Math.cos(a) * d, y: m.y0 + Math.sin(a) * d }
    }
    if (m.t === "rect" || m.t === "ellipse" || m.t === "pixel") {
        const dx = x - m.x0, dy = y - m.y0
        const d = Math.max(Math.abs(dx), Math.abs(dy))
        return { x: m.x0 + (dx < 0 ? -d : d), y: m.y0 + (dy < 0 ? -d : d) }
    }
    return { x: x, y: y }
}

function luminance(hex) {
    const c = hex.toString().replace("#", "")
    const v = i => parseInt(c.substr(i, 2), 16) / 255
    return 0.2126 * v(0) + 0.7152 * v(2) + 0.0722 * v(4)
}

// Output sizes offered by the editor; fixed widths that would enlarge the picture are left out.
// With an integer screen scale the scene can only be rendered in multiples of it, so sizes are rounded to `step`.
function sizeOptions(srcW, srcH, step) {
    step = step || 1
    const snap = v => Math.max(step, Math.round(v / step) * step)
    const out = [{ id: "orig", label: "Original", w: srcW, h: srcH }]
    for (const w of [1920, 1280, 800])
        if (w < srcW) out.push({ id: String(w), label: w + " px", w: snap(w), h: snap(srcH * w / srcW) })
    if (srcW >= 200) out.push({ id: "half", label: "50%", w: snap(srcW / 2), h: snap(srcH / 2) })
    return out
}

function targetFor(id, srcW, srcH, step) {
    const list = sizeOptions(srcW, srcH, step)
    return list.find(o => o.id === id) || list[0]
}

function pad(n) { return n < 10 ? "0" + n : String(n) }

// A small strftime: %Y %y %m %d %H %M %S %% (anything else is kept as is).
function strftime(fmt, d) {
    return fmt.replace(/%([YymdHMS%])/g, (all, c) => {
        switch (c) {
        case "Y": return String(d.getFullYear())
        case "y": return pad(d.getFullYear() % 100)
        case "m": return pad(d.getMonth() + 1)
        case "d": return pad(d.getDate())
        case "H": return pad(d.getHours())
        case "M": return pad(d.getMinutes())
        case "S": return pad(d.getSeconds())
        }
        return "%"
    })
}

function expandHome(p, home) {
    if (p === "~") return home
    if (p.startsWith("~/")) return home + p.substring(1)
    return p
}

function splitPath(p) {
    const slash = p.lastIndexOf("/")
    const dir = slash > 0 ? p.substring(0, slash) : (slash === 0 ? "/" : ".")
    const file = p.substring(slash + 1)
    const dot = file.lastIndexOf(".")
    if (dot <= 0) return { dir: dir, base: file, ext: "" }
    return { dir: dir, base: file.substring(0, dot), ext: file.substring(dot + 1).toLowerCase() }
}

function tidyDir(p) {
    let s = p.trim()
    while (s.length > 1 && s.endsWith("/")) s = s.substring(0, s.length - 1)
    return s
}

function dirLabel(p, home) {
    if (p === "") return "Clipboard only"
    if (p === home) return "Home"
    const slash = p.lastIndexOf("/")
    return slash >= 0 && slash < p.length - 1 ? p.substring(slash + 1) : p
}
