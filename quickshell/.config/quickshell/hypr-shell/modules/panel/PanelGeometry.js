.pragma library

// Panel outlines are traced clockwise and built from superellipse quarters.
// Angles in degrees as on screen: 0 is right, 90 down, 180 left, 270 up.

function sgn(v) { return v < 0 ? -1 : 1 }

// Elliptical superellipse quarter with separate radii; rx or ry may be 0 (the arc flattens into a line).
function arcXY(pts, cx, cy, rx, ry, a0, a1, power) {
    if (rx < 0.5 && ry < 0.5) {
        const th = a1 * Math.PI / 180
        pts.push(Qt.point(cx + rx * Math.cos(th), cy + ry * Math.sin(th)))
        return
    }
    const e = 2 / Math.max(2, power)
    const n = 10
    for (let i = 0; i <= n; i++) {
        const th = (a0 + (a1 - a0) * i / n) * Math.PI / 180
        const c = Math.cos(th), s = Math.sin(th)
        pts.push(Qt.point(cx + rx * sgn(c) * Math.pow(Math.abs(c), e), cy + ry * sgn(s) * Math.pow(Math.abs(s), e)))
    }
}

function arc(pts, cx, cy, r, a0, a1, power) {
    arcXY(pts, cx, cy, r, r, a0, a1, power)
}

function close(pts) {
    pts.push(pts[0])
    return pts
}

// Branch corner radii: ra is along the panel edge (always full), re (tip corners) and rf (fillets at the panel)
// are across it. While a branch retracts, re and rf shrink to 0, so each corner's bounding square folds
// onto its side that lies on the panel and the curve flattens into a straight line.

// Left rail branch: b = { y, y2, x2, ra, re, rf }.
function railBranch(pts, x1, b, power) {
    arcXY(pts, x1 + b.rf, b.y - b.ra, b.rf, b.ra, 180, 90, power)
    arcXY(pts, b.x2 - b.re, b.y + b.ra, b.re, b.ra, 270, 360, power)
    arcXY(pts, b.x2 - b.re, b.y2 - b.ra, b.re, b.ra, 0, 90, power)
    arcXY(pts, x1 + b.rf, b.y2 + b.ra, b.rf, b.ra, 270, 180, power)
}

// Bottom bar branch: b = { x, x2, y, ra, re, rf }, y0 is the top edge of the bar.
// flushL / flushR: the branch side continues the bar end in a straight line instead of a fillet.
function barBranch(pts, y0, b, power) {
    if (!b.flushL) arcXY(pts, b.x - b.ra, y0 - b.rf, b.ra, b.rf, 90, 0, power)
    arcXY(pts, b.x + b.ra, b.y + b.re, b.ra, b.re, 180, 270, power)
    arcXY(pts, b.x2 - b.ra, b.y + b.re, b.ra, b.re, 270, 360, power)
    if (!b.flushR) arcXY(pts, b.x2 + b.ra, y0 - b.rf, b.ra, b.rf, 180, 90, power)
}

// Full-height strip attached to the left screen edge. Its inner edge flares out into the top and
// bottom screen edges, so the free desktop area gets rounded corners next to the strip.
// g = { x0, x1, H (screen height), R, branch }
function railFlush(g, power) {
    const pts = [Qt.point(g.x0, 0)]
    arc(pts, g.x1 + g.R, g.R, g.R, 270, 180, power)
    if (g.branch) railBranch(pts, g.x1, g.branch, power)
    arc(pts, g.x1 + g.R, g.H - g.R, g.R, 180, 90, power)
    pts.push(Qt.point(g.x0, g.H))
    return close(pts)
}

// g = { x0, x1, y0, y1, R, rr (bottom corner radius), branch }
function rail(g, power) {
    const pts = []
    arc(pts, g.x0 + g.R, g.y0 + g.R, g.R, 180, 270, power)
    arc(pts, g.x1 - g.R, g.y0 + g.R, g.R, 270, 360, power)
    if (g.branch) railBranch(pts, g.x1, g.branch, power)
    arc(pts, g.x1 - g.rr, g.y1 - g.rr, g.rr, 0, 90, power)
    arc(pts, g.x0 + g.rr, g.y1 - g.rr, g.rr, 90, 180, power)
    return close(pts)
}

// g = { x0, x1, y0, y1, R, rtl (top-left corner radius), branch }
function bar(g, power) {
    const pts = []
    const b = g.branch
    if (!(b && b.flushL)) arc(pts, g.x0 + g.rtl, g.y0 + g.rtl, g.rtl, 180, 270, power)
    if (b) barBranch(pts, g.y0, b, power)
    if (!(b && b.flushR)) arc(pts, g.x1 - g.R, g.y0 + g.R, g.R, 270, 360, power)
    arc(pts, g.x1 - g.R, g.y1 - g.R, g.R, 0, 90, power)
    arc(pts, g.x0 + g.R, g.y1 - g.R, g.R, 90, 180, power)
    return close(pts)
}

// Single L-shaped form. g = { x0, rx1 (right edge of the rail), ry0, by0 (top of the bar), y1, x1, R, railBranch, barBranch }
function joined(g, power) {
    const pts = []
    arc(pts, g.x0 + g.R, g.ry0 + g.R, g.R, 180, 270, power)
    arc(pts, g.rx1 - g.R, g.ry0 + g.R, g.R, 270, 360, power)
    if (g.railBranch) railBranch(pts, g.rx1, g.railBranch, power)
    arc(pts, g.rx1 + g.R, g.by0 - g.R, g.R, 180, 90, power)
    if (g.barBranch) barBranch(pts, g.by0, g.barBranch, power)
    if (!(g.barBranch && g.barBranch.flushR)) arc(pts, g.x1 - g.R, g.by0 + g.R, g.R, 270, 360, power)
    arc(pts, g.x1 - g.R, g.y1 - g.R, g.R, 0, 90, power)
    arc(pts, g.x0 + g.R, g.y1 - g.R, g.R, 90, 180, power)
    return close(pts)
}

// Patch for the inner corner while merging: an R×R square minus a quarter disc.
function patch(rx1, by0, R, power) {
    const pts = [Qt.point(rx1, by0 - R), Qt.point(rx1, by0), Qt.point(rx1 + R, by0)]
    arc(pts, rx1 + R, by0 - R, R, 90, 180, power)
    return close(pts)
}

function patchEdge(rx1, by0, R, power) {
    const pts = []
    arc(pts, rx1 + R, by0 - R, R, 90, 180, power)
    return pts
}

function roundRect(x, y, w, h, r, power) {
    const pts = []
    arc(pts, x + r, y + r, r, 180, 270, power)
    arc(pts, x + w - r, y + r, r, 270, 360, power)
    arc(pts, x + w - r, y + h - r, r, 0, 90, power)
    arc(pts, x + r, y + h - r, r, 90, 180, power)
    return close(pts)
}

// One polygon with a hole: the hole is joined to the outline by a zero-width seam,
// so a single even-odd fill leaves it transparent. Both inputs are closed.
function withHole(outer, hole) {
    return outer.concat(hole, [outer[0]])
}

// Branch hanging from the top frame band. b = { x, x2, y2, ra, re, rf }, y0 is the inner edge of the band.
// Traced right to left, as part of the desktop cutout outline.
function topBranch(pts, y0, b, power) {
    arcXY(pts, b.x2 + b.ra, y0 + b.rf, b.ra, b.rf, 270, 180, power)
    arcXY(pts, b.x2 - b.ra, b.y2 - b.re, b.ra, b.re, 0, 90, power)
    arcXY(pts, b.x + b.ra, b.y2 - b.re, b.ra, b.re, 90, 180, power)
    arcXY(pts, b.x - b.ra, y0 + b.rf, b.ra, b.rf, 360, 270, power)
}

// Branch hanging from the right frame band. b = { y, y2, x2, ra, re, rf }, x0 is the inner edge of the band.
// Traced bottom to top, as part of the desktop cutout outline.
function rightBranch(pts, x0, b, power) {
    arcXY(pts, x0 - b.rf, b.y2 + b.ra, b.rf, b.ra, 360, 270, power)
    arcXY(pts, b.x2 + b.re, b.y2 - b.ra, b.re, b.ra, 90, 180, power)
    arcXY(pts, b.x2 + b.re, b.y + b.ra, b.re, b.ra, 180, 270, power)
    arcXY(pts, x0 - b.rf, b.y - b.ra, b.rf, b.ra, 90, 0, power)
}

// Outline of the free desktop area inside the screen frame, traced counter-clockwise.
// The frame itself is the screen rectangle minus this cutout (even-odd fill).
// g = { W, H, left, top, right, bottom, R, railBranch, rightBranch, topBranch, bottomBranch }
function frameHole(g, power) {
    const pts = []
    arc(pts, g.left + g.R, g.top + g.R, g.R, 270, 180, power)
    if (g.railBranch) railBranch(pts, g.left, g.railBranch, power)
    arc(pts, g.left + g.R, g.H - g.bottom - g.R, g.R, 180, 90, power)
    if (g.bottomBranch) barBranch(pts, g.H - g.bottom, g.bottomBranch, power)
    arc(pts, g.W - g.right - g.R, g.H - g.bottom - g.R, g.R, 90, 0, power)
    if (g.rightBranch) rightBranch(pts, g.W - g.right, g.rightBranch, power)
    arc(pts, g.W - g.right - g.R, g.top + g.R, g.R, 0, -90, power)
    if (g.topBranch) topBranch(pts, g.top, g.topBranch, power)
    return close(pts)
}

function screenRect(W, H) {
    return [Qt.point(0, 0), Qt.point(W, 0), Qt.point(W, H), Qt.point(0, H), Qt.point(0, 0)]
}
