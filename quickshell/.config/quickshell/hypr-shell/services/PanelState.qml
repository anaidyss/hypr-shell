pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.theme

Singleton {
    id: root

    // Which branch is open, on which monitor, and around which point along the panel axis (-1 = centered).
    property string kind: ""
    property real anchor: -1
    property string screenName: ""
    property bool pinned: false
    property bool hovered: false
    // A text field in the panel wants the keyboard; released by Esc, when the branch closes, or after 30 s without typing.
    property bool typing: false
    // Tab shown by the dashboard; the panel window resets it to the first one once the dashboard has fully retracted.
    property int dashTab: 0
    // Media tab view: 0 track, 1 lyrics, 2 equalizer
    property int mediaView: 0
    // Which module of the right control center is focused (scrolled into view).
    property string controlFocus: "wifi"

    function typed() { typeTimer.restart() }

    // Development aid: asks every panel window to save what it draws (the shell only, no other windows) to a PNG.
    signal snapshotRequested(string path)

    // Which category the "menu" flyout shows (see RailMenus).
    property string menuId: ""

    // Branches that grow from the left strip. The first group is older; the rest are the tool menus of the strip
    // (RailMenus lists them by category).
    readonly property var railKinds: ["media", "session", "drives", "menu",
        "layout", "wsview", "gamemode", "toggles", "nightlight", "timer", "picker", "emoji", "notes", "recent", "railedit", "oled"]

    // With a flush left panel the clock and the terminal branches open from it instead of the bottom bar.
    function isRail(k) {
        if (railKinds.indexOf(k) >= 0) return true
        return Theme.cfg.panel.railFlush && (k === "clock" || k === "term")
    }

    // The utility branch (omnibox, app search) grows up from the bottom frame band.
    function isBottom(k) {
        return k === "utility"
    }

    // The control center and the notification center hang from the right frame band.
    function isRight(k) {
        return k === "control" || k === "notifs"
    }

    // ---- Several menus at once ----
    // While `multi` is on, every edge keeps its own branch (the dashboard from the top, a menu from the left strip, the
    // control center from the right, the utility branch from the bottom) and nothing closes by itself. `kind` stays the
    // one opened last, for the code that only needs "something is open". Turning it off keeps only that last one.
    property bool multi: false
    property var branches: ({})

    // The edge a branch grows from: rail (left strip), bottom, right, top (frame mode) or bar (the floating bottom bar).
    function edgeOf(k) {
        if (isRail(k)) return "rail"
        if (!Theme.cfg.panel.railFlush) return "bar"
        if (isBottom(k)) return "bottom"
        if (isRight(k)) return "right"
        return "top"
    }

    function kindFor(edge) {
        if (multi) return branches[edge] ? branches[edge].kind : ""
        return kind !== "" && edgeOf(kind) === edge ? kind : ""
    }

    function anchorFor(edge) {
        if (multi) return branches[edge] ? branches[edge].anchor : -1
        return anchor
    }

    function isOpen(k) {
        if (k === "") return false
        if (!multi) return kind === k
        for (const e in branches) if (branches[e].kind === k) return true
        return false
    }

    readonly property bool any: kind !== "" || Object.keys(branches).length > 0

    function setMulti(on) {
        if (on === multi) return
        if (on) {
            const b = {}
            if (kind !== "") b[edgeOf(kind)] = { kind: kind, anchor: anchor }
            branches = b
            multi = true
            pinned = true
        } else {
            multi = false
            branches = {}
            pinned = false
        }
    }

    function open(k, a, screen, pin) {
        // The dashboard and the control center hang from the frame band, so they only exist in frame mode.
        if ((k === "dashboard" || k === "control" || k === "notifs") && !Theme.cfg.panel.railFlush) return
        if (k !== kind) typing = false
        if (multi) {
            const b = screen === screenName ? Object.assign({}, branches) : {}
            b[edgeOf(k)] = { kind: k, anchor: a }
            branches = b
        }
        kind = k
        anchor = a
        screenName = screen
        pinned = pin || multi
    }

    // Closes everything (the mode itself stays as it is).
    function close() {
        openTimer.stop()
        typing = false
        kind = ""
        branches = {}
        pinned = multi
    }

    // Closes the branch of one kind and leaves the others open when several are held.
    function dismiss(k) {
        if (!multi) {
            if (kind === k) close()
            return
        }
        const b = Object.assign({}, branches)
        for (const e in b) if (b[e].kind === k) delete b[e]
        branches = b
        if (kind === k) {
            const rest = Object.keys(b)
            kind = rest.length > 0 ? b[rest[rest.length - 1]].kind : ""
            if (kind === "") typing = false
        }
    }

    function toggle(k, a, screen) {
        if (isOpen(k)) dismiss(k)
        else open(k, a, screen, false)
    }

    function openControl(focus, a, screen) {
        controlFocus = focus
        open("control", a, screen, false)
    }

    function hoverOpenControl(focus, a, screen, delay) {
        pending = { k: "control", a: a, s: screen, f: focus }
        openTimer.interval = delay > 0 ? delay : 140
        openTimer.restart()
    }

    function toggleControl(focus, a, screen) {
        if (kind === "control") close()
        else openControl(focus, a, screen)
    }

    property var pending: null

    // Opens an option of the open flyout in place of it (same height along the strip).
    function openOption(k) {
        open(k, anchorFor("rail"), screenName, false)
    }

    function hoverOpen(k, a, screen, delay, menu) {
        pending = { k: k, a: a, s: screen, m: menu }
        openTimer.interval = delay > 0 ? delay : 140
        openTimer.restart()
    }

    function hoverCancel(k) {
        if (pending && pending.k === k) openTimer.stop()
    }

    Timer {
        id: openTimer
        interval: 140
        onTriggered: {
            if (root.pending.f !== undefined) root.controlFocus = root.pending.f
            if (root.pending.m !== undefined && root.pending.m !== "") root.menuId = root.pending.m
            root.open(root.pending.k, root.pending.a, root.pending.s, false)
        }
    }

    Timer { id: typeTimer; interval: 30000; running: root.typing; onTriggered: root.typing = false }

    Timer {
        interval: 600
        running: root.kind !== "" && !root.hovered && !root.pinned
        onTriggered: root.close()
    }

    // ---- Touchpad swipes (three fingers, bound in input.lua) ----
    // Down opens the dashboard, up the utility branch, left the control center; the opposite swipe closes the branch
    // at once. A swiped-in branch waits `swipeGrace` ms for the pointer: if it never comes, the branch closes, if it
    // does, the branch closes like a hovered one (600 ms after the pointer leaves).
    readonly property int swipeGrace: 1500
    property string swipeKind: ""

    function swipe(dir) {
        const opposite = { up: "dashboard", down: "utility", right: "control" }
        const opens = { down: "dashboard", up: "utility", left: "control" }
        if (opposite[dir] && isOpen(opposite[dir])) {
            dismiss(opposite[dir])
            return
        }
        const k = opens[dir]
        if (!k || isOpen(k)) return
        open(k, -1, Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "", true)
        if (!isOpen(k)) return
        swipeKind = k
        graceTimer.restart()
    }

    Timer {
        id: graceTimer
        interval: root.swipeGrace
        onTriggered: {
            const k = root.swipeKind
            root.swipeKind = ""
            if (!root.isOpen(k) || root.multi) return
            root.pinned = false
            if (!root.hovered) root.dismiss(k)
        }
    }

    IpcHandler {
        target: "panel"
        function toggle(kind: string): void {
            if (root.isOpen(kind)) root.dismiss(kind)
            else root.open(kind, -1, Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "", true)
        }
        // Holds several menus open at once (one per edge); a second call goes back to one menu at a time.
        function multi(): void {
            root.setMulti(!root.multi)
            Quickshell.execDetached(["notify-send", "-a", "hypr-shell", "-t", "2500", root.multi ? "Menus stay open" : "One menu at a time"])
        }
        function control(tab: string): void {
            root.controlFocus = tab
            root.open("control", -1, Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "", true)
        }
        function menu(id: string): void {
            root.menuId = id
            root.open("menu", -1, Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "", true)
        }
        function close(): void { root.close() }
        // Touchpad swipe direction (up|down|left|right), see swipe().
        function swipe(dir: string): void { root.swipe(dir) }
        function dashboardTab(index: int): void { root.dashTab = index }
        function mediaView(index: int): void { root.dashTab = 1; root.mediaView = index }
        function snapshot(path: string): void { root.snapshotRequested(path) }
    }
}
