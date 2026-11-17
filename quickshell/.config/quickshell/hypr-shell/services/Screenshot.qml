pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.theme
import "../modules/screenshot/shot.js" as Shot

Singleton {
    id: root

    // The overlay is shown on one monitor over a frozen frame of it.
    property bool active: false
    property string monitor: ""
    property string frame: ""
    // Windows of that monitor, topmost first, in monitor-local logical pixels.
    property var windows: []
    // Optional rectangle (logical, monitor-local) committed as soon as the overlay is up, for scripting and tests.
    property var preset: null

    property bool busy: false
    signal cancelRequested()
    signal snapshotRequested(string path)
    signal demoRequested()
    signal copyRequested(bool plain)
    signal saveRequested(bool plain, string path)
    signal menuRequested(string name)
    // copy: a picked area goes straight to the clipboard; edit: the area opens in the editor first.
    property string mode: "copy"
    property string lastFile: ""
    property string pendingMonitor: ""
    property string pendingFrame: ""

    readonly property string dir: Quickshell.env("XDG_RUNTIME_DIR") + "/hs-shot"
    readonly property string home: Quickshell.env("HOME")

    // What the editor remembers between shots (state file, outside the repository).
    readonly property string defaultDir: Shot.tidyDir(Shot.expandHome(Theme.cfg.screenshot.dir, home))
    // Empty means clipboard only.
    property string saveDir: ""
    property bool dirChosen: false
    property var recent: []
    property string format: "png"
    property string sizeId: "orig"
    property string tool: "move"
    property string color: ""
    property real width: 4
    property bool fill: false

    readonly property string effectiveDir: dirChosen ? saveDir : defaultDir
    readonly property string extension: format === "jpg" ? "jpg" : format

    function tempPath(kind, ext) { return dir + "/" + kind + "-" + Date.now() + "." + ext }

    function start(rect, editMode) {
        if (busy || active) return
        const m = Hyprland.focusedMonitor
        if (!m) return
        busy = true
        mode = editMode ? "edit" : "copy"
        preset = rect || null
        pendingMonitor = m.name
        // An open branch (the dashboard, say) stays and ends up in the shot; pinned so the pointer
        // leaving it for the overlay does not close it. The plain shot keeps a toast too (it may be
        // what is being captured); only the editor clears it before the frame is taken.
        if (PanelState.kind !== "") {
            heldKind = PanelState.kind
            heldPinned = PanelState.pinned
            PanelState.pinned = true
        }
        const clutter = editMode && Toasts.active
        if (editMode) Toasts.dismiss()
        if (clutter) settle.restart()
        else settle.triggered()
    }

    property string heldKind: ""
    property bool heldPinned: false

    function releaseBranch() {
        if (heldKind !== "" && PanelState.kind === heldKind) PanelState.pinned = heldPinned
        heldKind = ""
    }

    function close() {
        releaseBranch()
        if (frame !== "") Quickshell.execDetached(["rm", "-f", frame])
        active = false
        busy = false
        frame = ""
        preset = null
    }

    function expand(p) { return Shot.tidyDir(Shot.expandHome(p, home)) }

    function setDir(p) {
        const d = p === "" ? "" : expand(p)
        saveDir = d
        dirChosen = true
        if (d !== "" && d !== defaultDir) recent = [d].concat(recent.filter(x => x !== d)).slice(0, 4)
        savePrefs()
    }

    function setFormat(f) { format = f; savePrefs() }
    function setSize(id) { sizeId = id; savePrefs() }

    function remember(tool, color, width, fill) {
        if (!loaded || (root.tool === tool && root.color === color && root.width === width && root.fill === fill)) return
        root.tool = tool
        root.color = color
        root.width = width
        root.fill = fill
        savePrefs()
    }

    property bool loaded: false

    function savePrefs() {
        if (!loaded) return
        saveTimer.restart()
    }

    // Describes where a finished picture goes; the editor fills in the exact path for "Save as".
    function makeJob(save, exactPath) {
        if (!save) return { save: false }
        let dir = effectiveDir !== "" ? effectiveDir : defaultDir, base = Shot.strftime(Theme.cfg.screenshot.filename, new Date()), ext = extension
        if (exactPath) {
            const p = Shot.splitPath(expand(exactPath))
            dir = p.dir
            base = p.base
            if (p.ext === "png" || p.ext === "webp") ext = p.ext
            else if (p.ext === "jpg" || p.ext === "jpeg") ext = "jpg"
            else if (p.ext !== "") base = base + "." + p.ext
        }
        return { save: true, dir: dir, base: base, ext: ext }
    }

    // `png` always exists (the clipboard needs it); `file` is the same picture in the chosen format.
    function finish(job, png, file, w, h) {
        if (lastFile !== "" && lastFile !== png) Quickshell.execDetached(["rm", "-f", lastFile])
        lastFile = png
        Quickshell.execDetached(["sh", "-c", 'wl-copy -t image/png < "$1"', "sh", png])
        if (!job.save) {
            Quickshell.execDetached(["notify-send", "-a", "Screenshot", "-i", png, "-t", "3000", "Copied", w + " × " + h])
            return
        }
        Quickshell.execDetached(["sh", "-c", saveScript, "sh", file, job.dir, job.base, job.ext, w + " × " + h, png])
    }

    function copied(path, w, h) { finish({ save: false }, path, "", w, h) }

    // Picks a free name, copies the picture there and offers to open it from the toast.
    readonly property string saveScript: 'src=$1; dir=$2; base=$3; ext=$4; dims=$5; icon=$6\n'
        + 'mkdir -p "$dir" || { notify-send -a Screenshot -u critical "Not saved" "Cannot create $dir"; exit 1; }\n'
        + 'f="$dir/$base.$ext"; i=1\n'
        + 'while [ -e "$f" ]; do f="$dir/$base-$i.$ext"; i=$((i + 1)); done\n'
        + 'cp "$src" "$f" || { notify-send -a Screenshot -u critical "Not saved" "Cannot write $f"; exit 1; }\n'
        + '[ "$src" = "$icon" ] || rm -f "$src"\n'
        + 'a=$(notify-send -a Screenshot -i "$icon" -A default=Open -t 5000 "Saved" "$(basename "$f") · $dims")\n'
        + '[ "$a" = default ] && xdg-open "$f"\n'

    function parseWindows(text) {
        let data
        try { data = JSON.parse(text) } catch (e) { return [] }
        const m = data.monitors.find(x => x.name === pendingMonitor)
        if (!m) return []
        const spaces = [m.activeWorkspace.id]
        if (m.specialWorkspace && m.specialWorkspace.name !== "") spaces.push(m.specialWorkspace.id)
        const list = data.clients.filter(c => c.mapped && !c.hidden && c.monitor === m.id && spaces.indexOf(c.workspace.id) >= 0)
        // Floating windows sit above tiled ones; among equals the most recently focused is on top.
        list.sort((a, b) => (b.floating - a.floating) || (a.focusHistoryID - b.focusHistoryID))
        return list.map(c => ({ x: c.at[0] - m.x, y: c.at[1] - m.y, w: c.size[0], h: c.size[1] }))
    }

    Timer {
        id: settle
        interval: 280
        onTriggered: {
            root.pendingFrame = root.tempPath("frame", "ppm")
            grab.command = ["sh", "-c", 'mkdir -p "$1" && find "$1" -type f -mmin +60 -delete; grim -t ppm -o "$2" "$3"', "sh", root.dir, root.pendingMonitor, root.pendingFrame]
            grab.running = true
        }
    }

    Process {
        id: grab
        onExited: code => {
            if (code !== 0) { root.releaseBranch(); root.busy = false; return }
            info.running = true
        }
    }

    Process {
        id: info
        command: ["sh", "-c", "echo '{\"monitors\":'; hyprctl monitors -j; echo ',\"clients\":'; hyprctl clients -j; echo '}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.windows = root.parseWindows(text)
                root.monitor = root.pendingMonitor
                root.frame = root.pendingFrame
                root.active = true
            }
        }
    }

    FileView {
        id: prefsFile
        path: Theme.stateDir + "/screenshot.json"
        printErrors: false
        onLoaded: {
            try {
                const p = JSON.parse(text())
                if (typeof p.dir === "string") { root.saveDir = p.dir; root.dirChosen = true }
                if (Array.isArray(p.recent)) root.recent = p.recent.filter(x => typeof x === "string").slice(0, 4)
                if (["png", "jpg", "webp"].indexOf(p.format) >= 0) root.format = p.format
                if (typeof p.size === "string") root.sizeId = p.size
                if (typeof p.tool === "string") root.tool = p.tool
                if (typeof p.color === "string") root.color = p.color
                if (typeof p.width === "number") root.width = p.width
                if (typeof p.fill === "boolean") root.fill = p.fill
            } catch (e) {}
            root.loaded = true
        }
        onLoadFailed: root.loaded = true
    }

    Timer {
        id: saveTimer
        interval: 400
        onTriggered: prefsFile.setText(JSON.stringify({
            dir: root.dirChosen ? root.saveDir : undefined, recent: root.recent, format: root.format, size: root.sizeId,
            tool: root.tool, color: root.color, width: root.width, fill: root.fill
        }))
    }

    // Whole monitor straight to the clipboard, no overlay.
    Process {
        id: full
        property string path: ""
        property string size: ""
        onExited: code => { if (code === 0) root.copied(path, size.split("x")[0], size.split("x")[1]) }
    }

    function screen() {
        if (busy || active) return
        const m = Hyprland.focusedMonitor
        if (!m) return
        const o = m.lastIpcObject
        full.path = tempPath("shot", "png")
        full.size = o.width + "x" + o.height
        full.command = ["sh", "-c", 'mkdir -p "$1" && grim -o "$2" "$3"', "sh", dir, m.name, full.path]
        full.running = true
    }

    IpcHandler {
        target: "screenshot"
        function region(): void { root.start(null, false) }
        function edit(): void { root.start(null, true) }
        function area(x: int, y: int, w: int, h: int): void { root.start({ x: x, y: y, w: w, h: h }, false) }
        function editArea(x: int, y: int, w: int, h: int): void { root.start({ x: x, y: y, w: w, h: h }, true) }
        function snapshot(path: string): void { root.snapshotRequested(path) }
        function demo(): void { root.demoRequested() }
        function copy(plain: bool): void { root.copyRequested(plain) }
        function save(plain: bool, path: string): void { root.saveRequested(plain, path) }
        function menu(name: string): void { root.menuRequested(name) }
        function size(id: string): void { root.setSize(id) }
        function format(name: string): void { root.setFormat(name) }
        function screen(): void { root.screen() }
        function cancel(): void { root.cancelRequested() }
    }
}
