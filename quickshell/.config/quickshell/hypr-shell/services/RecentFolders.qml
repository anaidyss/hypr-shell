pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Recently used or changed folders for the "Recent folders" branch. `hs-recent` merges GTK's recent files with a
// shallow scan of `roots`; it only runs while the branch asks for it (refresh), never in the background.
// Pinned folders and the scanned roots are kept in ~/.local/state/hypr-shell/recent.json.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    property var folders: []
    property bool loading: false
    property var pinned: store.pinned
    property var roots: store.roots.length > 0 ? store.roots : defaultRoots

    readonly property var defaultRoots: [home, home + "/Documents", home + "/Downloads", home + "/Projects", home + "/dev", home + "/code"]

    // Pinned folders first (still in the order they were pinned), then the rest by recency.
    readonly property var rows: {
        const pins = []
        const rest = []
        for (const f of folders) (pinned.indexOf(f.path) >= 0 ? pins : rest).push(f)
        for (const p of pinned) if (!pins.some(f => f.path === p)) pins.push({ path: p, name: p.split("/").pop(), parent: p.substring(0, p.lastIndexOf("/")).replace(home, "~"), ts: 0 })
        return pins.concat(rest)
    }

    function refresh() {
        if (loading) return
        loading = true
        proc.command = ["hs-recent", "--days", "21", "--max", "40"].concat(roots)
        proc.running = true
    }

    function isPinned(path) { return pinned.indexOf(path) >= 0 }

    function togglePin(path) {
        const list = pinned.slice()
        const i = list.indexOf(path)
        if (i >= 0) list.splice(i, 1)
        else list.push(path)
        store.pinned = list
        saveTimer.restart()
    }

    function openFiles(path) {
        Quickshell.execDetached(["nautilus", path])
        PanelState.dismiss("recent")
    }

    function openTerminal(path) {
        Quickshell.execDetached(["kitty", "--directory", path])
        PanelState.dismiss("recent")
    }

    function age(ts) {
        if (ts <= 0) return "pinned"
        const s = Math.max(0, Date.now() / 1000 - ts)
        if (s < 90) return "now"
        if (s < 3600) return Math.round(s / 60) + " min"
        if (s < 86400) return Math.round(s / 3600) + " h"
        return Math.round(s / 86400) + " d"
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                let list = []
                try { list = JSON.parse(text) } catch (e) {}
                root.folders = list
                root.loading = false
            }
        }
    }

    Timer { id: saveTimer; interval: 300; onTriggered: file.writeAdapter() }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/hypr-shell/recent.json"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        adapter: JsonAdapter {
            id: store
            property list<string> pinned: []
            property list<string> roots: []
        }
    }
}
