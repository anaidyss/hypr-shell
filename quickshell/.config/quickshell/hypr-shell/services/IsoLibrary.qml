pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import "../data/distros.js" as Distros

// The ISO library: the .iso/.img files in `drives.isoDir`. `hs-flash scan` reads what each image says about itself
// (volume label, build date, a version guess); the distribution is recognised here from the file name and label.
// Anything the user sets by hand (distribution, display name, version) is kept per file name in
// ~/.local/state/hypr-shell/isos.json and wins over the guess. The folder is rescanned only while the branch shows it.
Singleton {
    id: root

    property bool wanted: false
    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: Theme.cfg.drives.isoDir.replace(/^~/, home)
    readonly property string shownDir: dir.indexOf(home) === 0 ? "~" + dir.slice(home.length) : dir

    property var items: []
    property bool loaded: false
    property bool missing: false
    property string error: ""
    property var overrides: ({})

    readonly property var distros: Distros.list
    function distro(id) { return Distros.byId(id) }

    function detect(file, label) {
        const hay = (file + " " + label).toLowerCase()
        for (const d of Distros.list) {
            try {
                if (new RegExp(d.match).test(hay)) return d.id
            } catch (e) {}
        }
        return "linux"
    }

    function enrich(raw) {
        return raw.map(it => {
            const o = overrides[it.file] || {}
            const autoId = it.windows ? "windows" : detect(it.file, it.label)
            const id = o.distro || autoId
            const d = Distros.byId(id) || Distros.byId("linux")
            const item = Object.assign({}, it, {
                distro: id,
                autoDistro: autoId,
                logo: d.path,
                distroName: d.name,
                name: o.name || d.name,
                version: o.version !== undefined && o.version !== "" ? o.version : it.version,
                autoVersion: it.version,
                edited: o.distro !== undefined || o.name !== undefined || o.version !== undefined
            })
            // A newer stable release of the same line on the mirror (see IsoMirror.updateFor), or null.
            item.update = IsoMirror.updateFor(item)
            return item
        })
    }

    property var raw: []
    onOverridesChanged: items = enrich(raw)
    Connections {
        target: IsoMirror
        function onEntriesChanged() { root.items = root.enrich(root.raw) }
    }

    function setOverride(file, distroId, name, version) {
        const all = Object.assign({}, overrides)
        const o = {}
        if (distroId !== "" ) o.distro = distroId
        if (name !== "") o.name = name
        if (version !== "") o.version = version
        if (Object.keys(o).length === 0) delete all[file]
        else all[file] = o
        overrides = all
        store.setText(JSON.stringify(all, null, 2))
    }
    function resetOverride(file) { setOverride(file, "", "", "") }

    // "2026-11-01" -> "1 Nov 2026"; age in words for how fresh the image is.
    readonly property var months: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    function niceDate(iso) {
        const m = /^(\d{4})-(\d\d)-(\d\d)/.exec(iso || "")
        return m ? parseInt(m[3]) + " " + months[parseInt(m[2]) - 1] + " " + m[1] : ""
    }
    function ageDays(iso) {
        const t = Date.parse(iso + "T00:00:00")
        return isNaN(t) ? -1 : Math.max(0, Math.floor((Date.now() - t) / 86400000))
    }
    function age(iso) {
        const d = ageDays(iso)
        if (d < 0) return ""
        if (d === 0) return "today"
        if (d < 14) return d + (d === 1 ? " day old" : " days old")
        if (d < 61) return Math.round(d / 7) + " weeks old"
        if (d < 730) return Math.round(d / 30.4) + " months old"
        return Math.round(d / 365) + " years old"
    }

    function rescan() { if (!scan.running) scan.running = true }
    function createDir() {
        Quickshell.execDetached(["mkdir", "-p", dir])
        createTimer.restart()
    }
    function openDir() { Quickshell.execDetached(["xdg-open", dir]) }

    Timer { id: createTimer; interval: 400; onTriggered: root.rescan() }
    Timer { interval: 4000; repeat: true; running: root.wanted; triggeredOnStart: true; onTriggered: root.rescan() }

    Process {
        id: scan
        command: ["hs-flash", "scan", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                let r = { ok: false, items: [] }
                try { r = JSON.parse(text) } catch (e) { root.error = "Cannot read the ISO folder" }
                root.missing = !!r.missing
                if (r.ok) root.error = ""
                const sig = JSON.stringify(r.items || [])
                if (sig !== JSON.stringify(root.raw)) {
                    root.raw = r.items || []
                    root.items = root.enrich(root.raw)
                }
                root.loaded = true
            }
        }
    }

    FileView {
        id: store
        path: root.home + "/.local/state/hypr-shell/isos.json"
        printErrors: false
        onLoaded: {
            try { root.overrides = JSON.parse(text()) } catch (e) { root.overrides = {} }
        }
    }

    // ---- checksum ----
    property string shaFile: ""
    property real shaRatio: 0
    property var shaResult: ({})  // file -> { match: true|false|null, sha256, source }
    readonly property bool hashing: shaProc.running

    function checksum(path, file) {
        if (shaProc.running) return
        shaFile = file
        shaRatio = 0
        shaProc.command = ["hs-flash", "sha", path]
        shaProc.running = true
    }

    Process {
        id: shaProc
        stdout: SplitParser {
            onRead: line => {
                let r = {}
                try { r = JSON.parse(line) } catch (e) { return }
                if (r.stage === "sha") root.shaRatio = r.total > 0 ? r.done / r.total : 0
                if (r.stage === "done") {
                    const all = Object.assign({}, root.shaResult)
                    all[root.shaFile] = r
                    root.shaResult = all
                    Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | wl-copy', "sh", r.sha256])
                }
            }
        }
        onExited: root.shaFile = ""
    }

    IpcHandler {
        target: "isos"
        // The library as the branch sees it: distribution, version and the newer image on the mirror, if any.
        function list(): string {
            return JSON.stringify(root.items.map(it => ({ file: it.file, distro: it.distro, version: it.version,
                update: it.update ? it.update.file : "" })))
        }
        function rescan(): void { root.wanted = true; root.rescan() }
        function download(path: string): void {
            const e = IsoMirror.entries.find(x => x.path === path)
            if (e) IsoMirror.download(e)
        }
    }
}
