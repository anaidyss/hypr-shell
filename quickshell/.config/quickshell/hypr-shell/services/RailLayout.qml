pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// What the left strip shows and in which order: three zones (top, middle, bottom) of item ids, a list of hidden
// items and hidden tool-menu category tabs. Kept in ~/.local/state/hypr-shell/rail.json; the strip (PanelRailItems)
// is built from it and BranchRailedit edits it.
Singleton {
    id: root

    readonly property var zones: ["top", "middle", "bottom"]
    readonly property var zoneTitles: ({ top: "Top", middle: "Middle", bottom: "Bottom" })

    // Every item the strip knows, with its default zone; the default order is the order of this list per zone.
    readonly property var catalog: [
        { id: "distro", label: "Launcher", icon: "search", zone: "top" },
        { id: "term", label: "Terminal", icon: "terminal", zone: "top" },
        { id: "running", label: "Open apps", icon: "layers", zone: "top" },
        { id: "workspaces", label: "Workspaces", icon: "dashboard", zone: "top" },
        { id: "tabs", label: "Tool menus", icon: "tabTools", zone: "top" },
        { id: "clock", label: "Clock", icon: "clock", zone: "middle" },
        { id: "controls", label: "Notes and shortcuts", icon: "note", zone: "bottom" },
        { id: "vpn", label: "VPN", icon: "shield", zone: "bottom" },
        { id: "status", label: "Layout and battery", icon: "battery", zone: "bottom" },
        { id: "power", label: "Power", icon: "power", zone: "bottom" }
    ]

    function meta(id) {
        for (const c of catalog) if (c.id === id) return c
        return null
    }

    function stored(zone) {
        return zone === "top" ? data.top : (zone === "middle" ? data.middle : data.bottom)
    }

    // Ids of a zone in order, hidden ones included; known ids only, and items missing from the file join their default zone.
    function ids(zone) {
        const out = []
        const seen = {}
        for (const z of zones)
            for (const id of stored(z)) {
                if (seen[id] || !meta(id)) continue
                seen[id] = true
                if (z === zone) out.push(id)
            }
        for (const c of catalog) if (!seen[c.id] && c.zone === zone) out.push(c.id)
        return out
    }

    function visibleIds(zone) {
        return ids(zone).filter(id => data.hidden.indexOf(id) < 0)
    }

    function zoneOf(id) {
        for (const z of zones) if (ids(z).indexOf(id) >= 0) return z
        return "top"
    }

    function visible(id) { return data.hidden.indexOf(id) < 0 }

    function tabVisible(categoryId) { return data.hiddenTabs.indexOf(categoryId) < 0 }

    function save() { file.writeAdapter() }

    function write(zone, list) {
        if (zone === "top") data.top = list
        else if (zone === "middle") data.middle = list
        else data.bottom = list
    }

    // Commits all three zones at once so the ids missing from the file get their place written down.
    function commit(layout) {
        for (const z of zones) write(z, layout[z])
        save()
    }

    function snapshot() {
        const l = {}
        for (const z of zones) l[z] = ids(z).slice()
        return l
    }

    // Up moves an item toward the top of its zone; at the top of a zone it crosses into the end of the zone above.
    function moveUp(id) {
        const l = snapshot()
        const z = zoneOf(id)
        const i = l[z].indexOf(id)
        if (i > 0) {
            l[z].splice(i, 1)
            l[z].splice(i - 1, 0, id)
        } else if (z !== "top") {
            const above = zones[zones.indexOf(z) - 1]
            l[z].splice(i, 1)
            l[above].push(id)
        } else return
        commit(l)
    }

    function moveDown(id) {
        const l = snapshot()
        const z = zoneOf(id)
        const i = l[z].indexOf(id)
        if (i < l[z].length - 1) {
            l[z].splice(i, 1)
            l[z].splice(i + 1, 0, id)
        } else if (z !== "bottom") {
            const below = zones[zones.indexOf(z) + 1]
            l[z].splice(i, 1)
            l[below].unshift(id)
        } else return
        commit(l)
    }

    function canMoveUp(id) { return zoneOf(id) !== "top" || ids("top").indexOf(id) > 0 }
    function canMoveDown(id) { return zoneOf(id) !== "bottom" || ids("bottom").indexOf(id) < ids("bottom").length - 1 }

    function setVisible(id, on) {
        const h = data.hidden.filter(x => x !== id)
        if (!on) h.push(id)
        data.hidden = h
        save()
    }

    function setTabVisible(categoryId, on) {
        const h = data.hiddenTabs.filter(x => x !== categoryId)
        if (!on) h.push(categoryId)
        data.hiddenTabs = h
        save()
    }

    function reset() {
        data.top = []
        data.middle = []
        data.bottom = []
        data.hidden = []
        data.hiddenTabs = []
        save()
    }

    readonly property bool isDefault: data.hidden.length === 0 && data.hiddenTabs.length === 0
        && data.top.length + data.middle.length + data.bottom.length === 0

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/hypr-shell/rail.json"
        printErrors: false
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        adapter: JsonAdapter {
            id: data
            property list<string> top: []
            property list<string> middle: []
            property list<string> bottom: []
            property list<string> hidden: []
            property list<string> hiddenTabs: []
        }
    }
}
