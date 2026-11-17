import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services
import "../panel/PanelGeometry.js" as Geo
import "shot.js" as Shot

PanelWindow {
    id: win

    required property var modelData

    readonly property bool showing: Screenshot.active && Screenshot.monitor === modelData.name
    readonly property bool editor: Screenshot.mode === "edit"

    // pick: choosing the area; edit: area fixed, marks can be drawn; out: result is being exported or dropped.
    property string phase: "pick"
    readonly property bool leaving: phase === "out"
    // Region and window pick differently in the editor; the plain screenshot accepts both.
    property string pickKind: "region"
    property string editMode: "region"

    // "" when idle, otherwise what the current pointer drag does: select, windowpick, move, draw or a handle id.
    property string dragKind: ""
    readonly property bool dragging: dragKind !== ""
    property bool moved: false
    property real px0: 0
    property real py0: 0
    property real mx: 0
    property real my: 0
    property var hover: null
    property var startRect: null
    property int curs: Qt.CrossCursor
    property var textAt: null
    property bool plainSnap: false

    // The selection as drawn. While picking it glides between windows and collapses over empty space.
    property real rx: 0
    property real ry: 0
    property real rw: 0
    property real rh: 0
    property bool snap: false
    property real holeR: phase === "pick" ? Theme.radiusSm : 2

    // Physical pixels per logical pixel, from the real frame, so fractional scales are handled.
    readonly property real sx: frozen.sourceSize.width > 0 ? frozen.sourceSize.width / width : 1
    readonly property real sy: frozen.sourceSize.height > 0 ? frozen.sourceSize.height / height : 1

    readonly property int resizeStep: Number.isInteger(devicePixelRatio) ? devicePixelRatio : 1

    readonly property var sel: {
        if (dragKind === "select" && moved) return { x: Math.min(px0, mx), y: Math.min(py0, my), w: Math.abs(mx - px0), h: Math.abs(my - py0) }
        return hover
    }

    readonly property var handles: [
        { id: "tl", x: rx, y: ry }, { id: "tr", x: rx + rw, y: ry },
        { id: "br", x: rx + rw, y: ry + rh }, { id: "bl", x: rx, y: ry + rh },
        { id: "t", x: rx + rw / 2, y: ry }, { id: "r", x: rx + rw, y: ry + rh / 2 },
        { id: "b", x: rx + rw / 2, y: ry + rh }, { id: "l", x: rx, y: ry + rh / 2 }
    ]

    readonly property var toolKeys: ({
        [Qt.Key_1]: "move", [Qt.Key_2]: "pen", [Qt.Key_3]: "marker", [Qt.Key_4]: "line", [Qt.Key_5]: "arrow",
        [Qt.Key_6]: "rect", [Qt.Key_7]: "ellipse", [Qt.Key_8]: "text", [Qt.Key_9]: "num", [Qt.Key_0]: "pixel", [Qt.Key_E]: "erase"
    })

    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: showing
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "hs-screenshot"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onSelChanged: applySel()

    onShowingChanged: {
        if (showing) {
            phase = "pick"
            pickKind = "region"
            editMode = "region"
            dragKind = ""
            moved = false
            hover = null
            textAt = null
            curs = Qt.CrossCursor
            rx = ry = rw = rh = 0
            ed.reset()
            if (Screenshot.loaded) {
                if (Screenshot.tool !== "") ed.tool = Screenshot.tool
                if (Screenshot.color !== "") ed.color = Screenshot.color
                ed.width = Screenshot.width
                ed.fill = Screenshot.fill
            }
            output.menu = ""
            keys.forceActiveFocus()
        }
    }

    function applySel() {
        if (phase !== "pick") return
        const s = sel
        if (s) {
            if (rw < 1 && rh < 1) {
                snap = true
                rx = s.x + s.w / 2
                ry = s.y + s.h / 2
                snap = false
            }
            rx = s.x; ry = s.y; rw = s.w; rh = s.h
        } else {
            rx += rw / 2; ry += rh / 2; rw = 0; rh = 0
        }
    }

    function hit(x, y) {
        for (const w of Screenshot.windows) {
            const x0 = Math.max(0, w.x), y0 = Math.max(0, w.y)
            const x1 = Math.min(width, w.x + w.w), y1 = Math.min(height, w.y + w.h)
            if (x1 - x0 < 24 || y1 - y0 < 24) continue
            if (x >= x0 && x < x1 && y >= y0 && y < y1) return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 }
        }
        return null
    }

    // Selections sit on whole physical pixels so the exported picture matches what is shown.
    function snapRect(r) {
        const x0 = Math.max(0, Math.min(width - 1 / sx, Math.round(r.x * sx) / sx))
        const y0 = Math.max(0, Math.min(height - 1 / sy, Math.round(r.y * sy) / sy))
        const w = Math.max(1 / sx, Math.min(width - x0, Math.round(r.w * sx) / sx))
        const h = Math.max(1 / sy, Math.min(height - y0, Math.round(r.h * sy) / sy))
        return { x: x0, y: y0, w: w, h: h }
    }

    function ring(x, y, w, h) {
        const r = Math.max(0, Math.min(holeR, w / 2, h / 2))
        const p = Theme.roundingPower
        const pts = []
        Geo.arc(pts, x + r, y + r, r, 180, 270, p)
        Geo.arc(pts, x + w - r, y + r, r, 270, 360, p)
        Geo.arc(pts, x + w - r, y + h - r, r, 0, 90, p)
        Geo.arc(pts, x + r, y + h - r, r, 90, 180, p)
        return Geo.close(pts)
    }

    function setRect(r) {
        rx = r.x; ry = r.y; rw = r.w; rh = r.h
    }

    function fullScreen() { return { x: 0, y: 0, w: width, h: height } }

    function enterEdit(r, kind) {
        if (phase !== "pick" || frozen.status !== Image.Ready) return
        phase = "edit"
        editMode = kind
        hover = null
        dragKind = ""
        moved = false
        ed.reset()
        setRect(snapRect(r))
        keys.forceActiveFocus()
    }

    function setMode(mode) {
        finishText()
        ed.reset()
        if (mode === "screen") {
            if (phase === "edit") { editMode = "screen"; setRect(snapRect(fullScreen())) }
            else enterEdit(fullScreen(), "screen")
            return
        }
        editMode = mode
        pickKind = mode
        phase = "pick"
        hover = null
        applySel()
    }

    // Plain screenshot: area picked, export at once at full size.
    function commitRect(r) {
        if (phase !== "pick" || frozen.status !== Image.Ready) return
        phase = "out"
        setRect(snapRect(r))
        beginExport({ save: false }, "orig")
    }

    function copyEdit() { exportEdit(Screenshot.makeJob(false, "")) }

    function saveEdit(path) {
        if (path === "" && Screenshot.effectiveDir === "") return
        exportEdit(Screenshot.makeJob(true, path))
    }

    function exportEdit(job) {
        if (phase !== "edit") return
        finishText()
        beginExport(job, Screenshot.sizeId)
    }

    function beginExport(job, sizeId) {
        phase = "out"
        flashRect = { x: rx, y: ry, w: rw, h: rh }
        flash.restart()
        closeTimer.interval = 2500
        closeTimer.restart()
        Qt.callLater(() => doExport(job, sizeId))
    }

    function doExport(job, sizeId) {
        const pw = Math.round(rw * sx), ph = Math.round(rh * sy)
        const t = Shot.targetFor(sizeId, pw, ph, resizeStep)
        if (t.w === pw && t.h === ph) {
            art.grabToImage(result => deliver(result, job, pw, ph), Qt.size(art.width, art.height))
            return
        }
        // Resizing goes through a mipmapped image: the GPU would alias if the scene were rendered small directly.
        const full = Screenshot.tempPath("full", "png")
        art.grabToImage(result => {
            if (!result.saveToFile(full)) { closeNow(); return }
            scaler.job = job
            scaler.tw = t.w
            scaler.th = t.h
            scaler.full = full
            scaler.width = t.w / devicePixelRatio
            scaler.height = t.h / devicePixelRatio
            scaler.source = "file://" + full
        }, Qt.size(art.width, art.height))
    }

    function deliver(result, job, w, h) {
        const png = Screenshot.tempPath("shot", "png")
        if (!result.saveToFile(png)) { closeNow(); return }
        let file = png
        let j = job
        if (job.save && job.ext !== "png") {
            file = Screenshot.tempPath("shot", job.ext)
            if (!result.saveToFile(file)) {
                file = png
                j = { save: true, dir: job.dir, base: job.base, ext: "png" }
            }
        }
        Screenshot.finish(j, png, file, w, h)
        plainSnap = false
        closeTimer.interval = Theme.durFast + 60
        closeTimer.restart()
    }

    function closeNow() {
        plainSnap = false
        closeTimer.interval = Theme.durFast + 60
        closeTimer.restart()
    }

    function cancel() {
        if (leaving) return
        phase = "out"
        closeTimer.interval = Theme.durFast + 60
        closeTimer.restart()
    }

    function startText(x, y) {
        finishText()
        textAt = { x: x, y: y }
        textBox.text = ""
        textBox.forceActiveFocus()
    }

    function finishText() {
        if (!textAt) return
        const t = textAt
        textAt = null
        ed.addText(t.x, t.y, textBox.text, textBox.contentWidth)
        keys.forceActiveFocus()
    }

    function cancelText() {
        textAt = null
        keys.forceActiveFocus()
    }

    function handleAt(x, y) {
        for (const h of handles) if (Math.hypot(x - h.x, y - h.y) <= 10) return h.id
        return ""
    }

    function inside(x, y) { return x >= rx && x <= rx + rw && y >= ry && y <= ry + rh }

    function cursorFor(x, y) {
        const h = handleAt(x, y)
        if (h === "tl" || h === "br") return Qt.SizeFDiagCursor
        if (h === "tr" || h === "bl") return Qt.SizeBDiagCursor
        if (h === "t" || h === "b") return Qt.SizeVerCursor
        if (h === "l" || h === "r") return Qt.SizeHorCursor
        if (!inside(x, y)) return Qt.ArrowCursor
        if (ed.tool === "move") return Qt.SizeAllCursor
        if (ed.tool === "text") return Qt.IBeamCursor
        if (ed.tool === "erase") return Qt.PointingHandCursor
        return Qt.CrossCursor
    }

    function resizeTo(kind, x, y) {
        const s = startRect
        const min = 24
        let l = s.x, t = s.y, r = s.x + s.w, b = s.y + s.h
        if (kind.indexOf("l") >= 0) l = Math.max(0, Math.min(x, r - min))
        if (kind.indexOf("r") >= 0) r = Math.min(width, Math.max(x, l + min))
        if (kind.indexOf("t") >= 0) t = Math.max(0, Math.min(y, b - min))
        if (kind.indexOf("b") >= 0) b = Math.min(height, Math.max(y, t + min))
        setRect(snapRect({ x: l, y: t, w: r - l, h: b - t }))
    }

    function moveTo(x, y) {
        const s = startRect
        const nx = Math.max(0, Math.min(width - s.w, s.x + x - px0))
        const ny = Math.max(0, Math.min(height - s.h, s.y + y - py0))
        setRect(snapRect({ x: nx, y: ny, w: s.w, h: s.h }))
    }

    property var flashRect: ({ x: 0, y: 0, w: 0, h: 0 })

    // Development aid: puts one mark of every kind into the current selection.
    function addDemo() {
        const x = rx + 30, y = ry + 30
        const c = ["#ff5a5f", "#ffb020", "#34c759", "#3d8bff", "#ffffff"]
        ed.commit([
            { t: "pixel", c: c[0], w: 4, f: false, x0: rx + 52, y0: ry + 60, x1: rx + 400, y1: ry + 92 },
            { t: "rect", c: c[0], w: 4, f: false, x0: x, y0: y + 170, x1: x + 150, y1: y + 240 },
            { t: "rect", c: c[3], w: 4, f: true, x0: x + 170, y0: y + 170, x1: x + 300, y1: y + 240 },
            { t: "ellipse", c: c[2], w: 4, f: false, x0: x + 320, y0: y + 170, x1: x + 440, y1: y + 240 },
            { t: "arrow", c: c[1], w: 4, f: false, x0: x, y0: y + 330, x1: x + 220, y1: y + 270 },
            { t: "line", c: c[4], w: 2, f: false, x0: x + 250, y0: y + 330, x1: x + 440, y1: y + 270 },
            { t: "marker", c: c[1], w: 4, f: false, pts: [x, y + 110, x + 60, y + 100, x + 140, y + 112, x + 230, y + 100, x + 330, y + 110] },
            { t: "pen", c: c[2], w: 4, f: false, pts: [x, y + 370, x + 40, y + 340, x + 80, y + 395, x + 130, y + 350, x + 180, y + 395, x + 240, y + 345] },
            { t: "num", c: c[0], w: 4, f: true, x0: x + 300, y0: y + 365, n: 1 },
            { t: "num", c: c[3], w: 4, f: true, x0: x + 345, y0: y + 365, n: 2 },
            { t: "text", c: c[4], w: 4, f: false, x0: x + 380, y0: y + 350, s: "Look here", tw: 120 }
        ])
    }

    ShotModel {
        id: ed
        color: Theme.accent.toString()
        onToolChanged: win.finishText()
    }

    Connections {
        target: Screenshot
        function onCancelRequested() { if (win.showing) win.cancel() }
        function onSnapshotRequested(path) {
            if (!win.showing) return
            snapshot.path = path
            win.plainSnap = true
            snapshot.restart()
        }
        function onDemoRequested() { if (win.showing && win.phase === "edit") win.addDemo() }
        function onSaveRequested(plain, path) {
            if (!win.showing || win.phase !== "edit") return
            win.plainSnap = plain
            win.saveEdit(path)
        }
        function onMenuRequested(name) { if (win.showing && win.phase === "edit") output.menu = name }
        function onCopyRequested(plain) {
            if (!win.showing || win.phase !== "edit") return
            win.plainSnap = plain
            win.copyEdit()
        }
    }

    // Development aid: saves what the overlay draws over a neutral backdrop, never the real frame.
    Timer {
        id: snapshot
        property string path: ""
        interval: 160
        onTriggered: scene.grabToImage(result => {
            result.saveToFile(path)
            win.plainSnap = false
        })
    }

    Connections {
        target: ed
        function onToolChanged() { win.remember() }
        function onColorChanged() { win.remember() }
        function onWidthChanged() { win.remember() }
        function onFillChanged() { win.remember() }
    }

    function remember() { Screenshot.remember(ed.tool, ed.color, ed.width, ed.fill) }

    Timer { id: closeTimer; onTriggered: Screenshot.close() }
    Timer { id: idle; interval: 45000; running: win.showing; onTriggered: win.cancel() }

    // Scripted selections wait for the frame to load before committing.
    Timer {
        id: presetTimer
        interval: 60
        repeat: true
        running: win.showing && Screenshot.preset !== null && win.phase === "pick"
        onTriggered: {
            if (frozen.status !== Image.Ready) return
            const p = Screenshot.preset
            Screenshot.preset = null
            if (!p) return
            if (win.editor) win.enterEdit(p, "region")
            else win.commitRect(p)
        }
    }

    Behavior on rx { enabled: win.phase === "pick" && !win.dragging && !win.snap; NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
    Behavior on ry { enabled: win.phase === "pick" && !win.dragging && !win.snap; NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
    Behavior on rw { enabled: win.phase === "pick" && !win.dragging && !win.snap; NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
    Behavior on rh { enabled: win.phase === "pick" && !win.dragging && !win.snap; NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
    Behavior on holeR { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }

    Item {
        id: scene

        anchors.fill: parent

        // Downscales the full-size export for the smaller output sizes.
        Image {
            id: scaler

            property var job: null
            property int tw: 0
            property int th: 0
            property string full: ""

            z: -1
            x: 0
            y: 0
            asynchronous: true
            cache: false
            mipmap: true
            smooth: true
            source: ""

            onStatusChanged: {
                if (status !== Image.Ready || job === null) return
                const j = job, w = tw, h = th, f = full
                job = null
                grabToImage(result => {
                    win.deliver(result, j, w, h)
                    source = ""
                    Quickshell.execDetached(["rm", "-f", f])
                }, Qt.size(Math.round(w / win.devicePixelRatio), Math.round(h / win.devicePixelRatio)))
            }
        }

        Image {
            id: frozen
            anchors.fill: parent
            visible: !win.plainSnap
            asynchronous: true
            cache: true
            smooth: true
            source: win.showing && Screenshot.frame !== "" ? "file://" + Screenshot.frame : ""
        }

        Item {
            id: dim

            anchors.fill: parent
            opacity: win.showing && win.phase !== "out" ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }

            Shape {
                anchors.fill: parent
                layer.enabled: true
                layer.samples: 4

                ShapePath {
                    fillRule: ShapePath.OddEvenFill
                    fillColor: Qt.rgba(0, 0, 0, 0.5)
                    strokeColor: "transparent"
                    PathMultiline { paths: [Geo.screenRect(win.width, win.height), win.ring(win.rx, win.ry, win.rw, win.rh)] }
                }
            }
        }

        ShotArt {
            id: art

            x: win.rx
            y: win.ry
            width: win.rw
            height: win.rh
            visible: win.phase !== "pick" && win.rw > 0
            frame: frozen.source
            model: ed
            screenW: win.width
            screenH: win.height
            plain: win.plainSnap
        }

        Shape {
            anchors.fill: parent
            opacity: dim.opacity
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                fillColor: "transparent"
                strokeColor: win.rw > 1 && win.rh > 1 ? Theme.borderActive : "transparent"
                strokeWidth: 1
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: win.ring(win.rx, win.ry, win.rw, win.rh) }
            }
        }

        Repeater {
            model: win.handles

            Rectangle {
                required property var modelData

                x: modelData.x - width / 2
                y: modelData.y - height / 2
                width: 10
                height: 10
                radius: 5
                color: "white"
                border.width: 1
                border.color: Qt.rgba(0, 0, 0, 0.45)
                opacity: win.phase === "edit" ? 1 : 0
                visible: opacity > 0.01

                Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
            }
        }

        Rectangle {
            id: chip

            readonly property bool edit: win.phase === "edit"
            readonly property bool wanted: win.rw > 40 && win.rh > 24
            readonly property real below: win.ry + win.rh + 8
            readonly property bool fitsBelow: below + height <= win.height

            x: edit ? Math.max(8, win.rx) : Math.max(8, Math.min(win.width - width - 8, win.rx + win.rw - width))
            y: edit ? (win.ry - height - 10 >= 6 ? win.ry - height - 10 : win.ry + 8) : (fitsBelow ? below : win.ry + win.rh - height - 8)
            width: label.implicitWidth + 20
            height: 24
            radius: 8
            color: Qt.rgba(0, 0, 0, 0.72)
            border.width: 1
            border.color: Theme.border
            opacity: wanted && win.phase !== "out" ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }

            Text {
                id: label
                anchors.centerIn: parent
                text: Math.round(win.rw * win.sx) + " × " + Math.round(win.rh * win.sy)
                color: Theme.text
                font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold }
            }
        }

        Rectangle {
            visible: win.textAt !== null
            x: win.textAt ? win.textAt.x - 4 : 0
            y: win.textAt ? win.textAt.y - 3 : 0
            width: Math.max(40, textBox.contentWidth) + 8
            height: textBox.contentHeight + 6
            radius: 4
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(ed.color, 0.6)
        }

        TextInput {
            id: textBox

            visible: win.textAt !== null
            x: win.textAt ? win.textAt.x : 0
            y: win.textAt ? win.textAt.y : 0
            color: ed.color
            selectionColor: Qt.alpha(ed.color, 0.35)
            font { family: Theme.fontUi; pixelSize: Shot.textSize(ed.width); weight: Theme.wStrong }
            onAccepted: win.finishText()
            Keys.onEscapePressed: win.cancelText()
        }

        Rectangle {
            id: flashBox

            x: win.flashRect.x
            y: win.flashRect.y
            width: win.flashRect.w
            height: win.flashRect.h
            radius: 2
            color: "white"
            opacity: 0

            NumberAnimation { id: flash; target: flashBox; property: "opacity"; from: 0.8; to: 0; duration: 180; easing.type: Theme.easingCalm }
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: win.curs

            onPositionChanged: m => {
                idle.restart()
                win.mx = m.x
                win.my = m.y
                const shift = (m.modifiers & Qt.ShiftModifier) !== 0
                if (win.phase === "pick") {
                    if (win.dragKind === "select") {
                        if (!win.moved && Math.hypot(m.x - win.px0, m.y - win.py0) >= 4) win.moved = true
                    } else {
                        win.hover = win.hit(m.x, m.y)
                    }
                } else if (win.phase === "edit") {
                    if (win.dragKind === "draw") ed.update(m.x, m.y, shift)
                    else if (win.dragKind === "move") win.moveTo(m.x, m.y)
                    else if (win.dragKind !== "") win.resizeTo(win.dragKind, m.x, m.y)
                    else win.curs = win.cursorFor(m.x, m.y)
                }
            }

            onPressed: m => {
                if (win.phase === "pick") {
                    if (m.button === Qt.RightButton) { win.cancel(); return }
                    win.px0 = m.x
                    win.py0 = m.y
                    win.mx = m.x
                    win.my = m.y
                    win.moved = false
                    win.dragKind = win.editor && win.pickKind === "window" ? "windowpick" : "select"
                } else if (win.phase === "edit") {
                    if (m.button !== Qt.LeftButton) return
                    if (output.menu !== "") { output.menu = ""; keys.forceActiveFocus(); return }
                    if (win.textAt) { win.finishText(); return }
                    const h = win.handleAt(m.x, m.y)
                    win.px0 = m.x
                    win.py0 = m.y
                    win.startRect = { x: win.rx, y: win.ry, w: win.rw, h: win.rh }
                    if (h !== "") { win.dragKind = h; return }
                    if (!win.inside(m.x, m.y)) return
                    const t = ed.tool
                    if (t === "move") win.dragKind = "move"
                    else if (t === "erase") ed.eraseAt(m.x, m.y)
                    else if (t === "num") ed.placeNumber(m.x, m.y)
                    else if (t === "text") win.startText(m.x, m.y)
                    else if (ed.dragTool) { ed.begin(m.x, m.y); win.dragKind = "draw" }
                }
            }

            onReleased: m => {
                if (m.button !== Qt.LeftButton || !win.dragging) return
                if (win.phase === "pick") {
                    const drawn = win.dragKind === "select" && win.moved
                    const picked = drawn ? win.sel : win.hover
                    if (picked && picked.w >= 4 && picked.h >= 4) {
                        if (win.editor) win.enterEdit(picked, drawn ? "region" : "window")
                        else win.commitRect(picked)
                    }
                } else if (win.dragKind === "draw") {
                    ed.finish()
                }
                win.dragKind = ""
                win.moved = false
                if (win.phase === "edit") win.curs = win.cursorFor(m.x, m.y)
            }
        }

        ShotModes {
            x: Math.round((win.width - width) / 2)
            y: 14
            mode: win.editMode
            opacity: win.editor && win.phase !== "out" ? 1 : 0
            visible: opacity > 0.01
            onPicked: m => win.setMode(m)

            Behavior on opacity { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easingCalm } }
        }

        ShotTools {
            id: tools

            x: {
                let v = win.rx + win.rw + 12
                if (v + width > win.width - 8) v = win.rx - width - 12
                if (v < 8) v = Math.min(win.rx + win.rw - width - 12, win.width - width - 8)
                return v
            }
            y: Math.max(8, Math.min(win.height - height - 8, win.ry + win.rh / 2 - height / 2))
            model: ed
            opacity: win.phase === "edit" ? 1 : 0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easingCalm } }
        }

        ShotBar {
            id: bar

            readonly property real block: height + 8 + output.height

            x: Math.max(8, Math.min(win.width - width - 8, win.rx + win.rw / 2 - width / 2))
            y: {
                let v = win.ry + win.rh + 12
                if (v + block > win.height - 8) v = win.ry + win.rh - block - 12
                return Math.max(8, Math.min(v, win.height - block - 8))
            }
            model: ed
            opacity: win.phase === "edit" ? 1 : 0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easingCalm } }
        }

        ShotOutput {
            id: output

            x: Math.max(8, Math.min(win.width - width - 8, win.rx + win.rw / 2 - width / 2))
            y: bar.y + bar.height + 8
            srcW: Math.round(win.rw * win.sx)
            srcH: Math.round(win.rh * win.sy)
            step: win.resizeStep
            opacity: win.phase === "edit" ? 1 : 0
            visible: opacity > 0.01
            onCopyRequested: win.copyEdit()
            onSaveRequested: win.saveEdit("")
            onSaveAsRequested: path => win.saveEdit(path)
            onCancelRequested: win.cancel()
            onMenuChanged: if (menu === "") keys.forceActiveFocus()

            Behavior on opacity { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easingCalm } }
        }

        Item {
            id: keys

            focus: true
            Keys.onPressed: event => {
                idle.restart()
                const ctrl = (event.modifiers & Qt.ControlModifier) !== 0
                const shift = (event.modifiers & Qt.ShiftModifier) !== 0
                if (event.key === Qt.Key_Escape) {
                    if (output.menu !== "") output.menu = ""
                    else win.cancel()
                } else if (win.phase === "edit" && ctrl && event.key === Qt.Key_S) {
                    if (shift) output.openSaveAs()
                    else win.saveEdit("")
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (win.phase === "edit") win.copyEdit()
                    else if (win.phase === "pick") {
                        if (win.editor) win.enterEdit(win.fullScreen(), "screen")
                        else win.commitRect(win.fullScreen())
                    }
                } else if (win.phase === "edit" && ctrl && event.key === Qt.Key_Z) {
                    if (shift) ed.redo()
                    else ed.undo()
                } else if (win.phase === "edit" && ctrl && event.key === Qt.Key_Y) {
                    ed.redo()
                } else if (win.phase === "edit" && !ctrl && win.toolKeys[event.key] !== undefined) {
                    ed.tool = win.toolKeys[event.key]
                    win.curs = win.cursorFor(win.mx, win.my)
                } else {
                    return
                }
                event.accepted = true
            }
        }
    }
}
