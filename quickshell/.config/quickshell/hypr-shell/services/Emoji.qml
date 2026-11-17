pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// The emoji menu's data: the dataset built by `hs-emoji-build` (data/emoji.json: groups of [emoji, name, keywords],
// English and Russian) plus the recently used ones. Picking copies the emoji and types it into the window that had
// the focus, when `wtype` is installed.
Singleton {
    id: root

    property var groups: []
    property var recent: []
    readonly property bool loaded: groups.length > 0

    function flat() {
        const out = []
        for (const g of groups) for (const it of g.items) out.push(it)
        return out
    }

    // Emoji of a group (index into groups, -1 = recent), or the search results over everything when `query` is set.
    function view(group, query) {
        const q = query.trim().toLowerCase()
        if (q !== "") {
            const words = q.split(/\s+/)
            const out = []
            for (const it of flat()) {
                const hay = it[1] + " " + it[2]
                if (words.every(w => hay.indexOf(w) >= 0)) {
                    out.push(it)
                    if (out.length >= 300) break
                }
            }
            return out
        }
        if (group < 0) {
            const all = flat()
            const byChar = {}
            for (const it of all) byChar[it[0]] = it
            return recent.map(c => byChar[c]).filter(x => x)
        }
        return groups[group] ? groups[group].items : []
    }

    function pick(ch) {
        recent = [ch].concat(recent.filter(c => c !== ch)).slice(0, 32)
        store.setText(JSON.stringify({ recent: recent }))
        Quickshell.execDetached(["sh", "-c",
            "printf %s \"$1\" | wl-copy; if command -v wtype >/dev/null 2>&1; then sleep 0.25; wtype -- \"$1\"; " +
            "else notify-send -a Emoji -t 1500 Copied \"$1\"; fi", "_", ch])
        PanelState.dismiss("emoji")
    }

    FileView {
        path: Quickshell.shellPath("data/emoji.json")
        printErrors: false
        onLoaded: {
            try { root.groups = JSON.parse(text()).groups } catch (e) { console.warn("emoji data:", e) }
        }
    }

    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.local/state/hypr-shell/emoji.json"
        printErrors: false
        onLoaded: {
            try { root.recent = JSON.parse(text()).recent || [] } catch (e) {}
        }
    }
}
