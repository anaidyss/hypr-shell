pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

// Quick notes: plain .md files in one folder, edited in the utility branch and optionally pinned to the
// desktop as floating sticky cards.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: Theme.cfg.notes.dir.replace(/^~/, home)

    // [{ path, name, mtime, text }], newest first.
    property var notes: []
    property bool loading: false

    // The note shown in the editor: `openPath` is requested, `loadedPath` holds the content that has arrived.
    property string openPath: ""
    property string loadedPath: ""
    property string loaded: ""

    // Pinned stickies: the paths are what the window list follows; positions live in a separate map so that
    // dragging a card does not rebuild its window.
    property var pinned: []
    property var positions: ({})

    signal created(string path)

    function start() { reload() }

    function reload() {
        loading = true
        listProc.command = ["hs-notes", "list", dir]
        listProc.running = true
    }

    function nameOf(path) {
        const n = path.split("/").pop()
        return n.replace(/\.md$/, "")
    }

    function find(path) { return notes.find(n => n.path === path) || null }

    function rows(query) {
        const q = query.trim().toLowerCase()
        const out = []
        for (const n of notes) {
            if (q !== "" && n.name.toLowerCase().indexOf(q) < 0 && n.text.toLowerCase().indexOf(q) < 0) continue
            out.push({ kind: "note", key: "note:" + n.path, path: n.path, title: n.name, mtime: n.mtime })
        }
        // Creating leads when there is nothing to open, and trails the matches otherwise.
        const exact = q !== "" && notes.some(n => n.name.toLowerCase() === q)
        const row = { kind: "newnote", key: "newnote", title: query.trim() }
        if (q === "" || out.length === 0) out.unshift(row)
        else if (!exact) out.push(row)
        return out
    }

    function create(name) {
        createProc.command = ["hs-notes", "create", dir, name]
        createProc.running = true
    }

    function trash(path) {
        flush()
        Quickshell.execDetached(["hs-notes", "trash", path])
        notes = notes.filter(n => n.path !== path)
        unpin(path)
        if (openPath === path) openPath = ""
    }

    // ---- Editing ----------------------------------------------------------------------------------

    property string pendingPath: ""
    property string pendingText: ""

    function open(path) {
        if (path === openPath) return
        flush()
        loaded = ""
        loadedPath = ""
        openPath = path
    }

    function edit(text) {
        if (loadedPath === "") return
        pendingPath = loadedPath
        pendingText = text
        saveTimer.restart()
    }

    function flush() {
        saveTimer.stop()
        if (pendingPath === "") return
        Quickshell.execDetached(["hs-notes", "write", pendingPath, pendingText])
        pendingPath = ""
    }

    Timer {
        id: saveTimer
        interval: 600
        onTriggered: root.flush()
    }

    FileView {
        id: reader
        path: root.openPath
        printErrors: false
        onLoaded: {
            root.loaded = text()
            root.loadedPath = path
        }
    }

    // ---- Stickies ---------------------------------------------------------------------------------

    function isPinned(path) { return pinned.indexOf(path) >= 0 }

    function pin(path, screen) {
        if (isPinned(path)) return
        const n = pinned.length
        const next = Object.assign({}, positions)
        next[path] = { x: 120 + 28 * n, y: 90 + 28 * n, screen: screen }
        positions = next
        pinned = pinned.concat([path])
        persist()
    }

    function unpin(path) {
        if (!isPinned(path)) return
        pinned = pinned.filter(p => p !== path)
        persist()
    }

    function togglePin(path, screen) { isPinned(path) ? unpin(path) : pin(path, screen) }

    function setPos(path, x, y) {
        const next = Object.assign({}, positions)
        next[path] = Object.assign({}, next[path] || {}, { x: x, y: y })
        positions = next
        persist()
    }

    function persist() {
        const items = pinned.map(p => Object.assign({ path: p }, positions[p] || { x: 120, y: 90, screen: "" }))
        store.setText(JSON.stringify({ items: items }))
    }

    FileView {
        id: store
        path: root.home + "/.local/state/hypr-shell/stickies.json"
        printErrors: false
        onLoaded: {
            try {
                const items = JSON.parse(text()).items || []
                const pos = {}
                for (const i of items) pos[i.path] = { x: i.x, y: i.y, screen: i.screen }
                root.positions = pos
                root.pinned = items.map(i => i.path)
            } catch (e) {}
        }
    }

    IpcHandler {
        target: "notes"
        function pin(path: string, screen: string): void { root.pin(path, screen) }
        function unpin(path: string): void { root.unpin(path) }
    }

    // ---- Processes --------------------------------------------------------------------------------

    Process {
        id: listProc
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.split("\n")) {
                    if (line === "") continue
                    try { out.push(JSON.parse(line)) } catch (e) {}
                }
                root.notes = out
                root.loading = false
            }
        }
    }

    Process {
        id: createProc
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim()
                if (path === "") return
                root.notes = [{ path: path, name: root.nameOf(path), mtime: Date.now(), text: "" }].concat(root.notes)
                root.created(path)
            }
        }
    }
}
