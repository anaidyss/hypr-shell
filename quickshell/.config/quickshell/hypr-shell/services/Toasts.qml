pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false
    property bool paused: false
    // Notifications that arrived while the dashboard covered the toast spot; shown as a badge on its first tab.
    property int missed: 0

    Connections {
        target: PanelState
        function onKindChanged() { if (!PanelState.isOpen("dashboard")) root.missed = 0 }
        function onBranchesChanged() { if (!PanelState.isOpen("dashboard")) root.missed = 0 }
    }

    // Notifications that arrived while the lock screen was up (newest first), shown on it and cleared at the next lock.
    property var unread: []
    function clearUnread() { unread = [] }

    // Notification center: everything that arrived and is still around, newest first. Each entry is a plain copy
    // (id, app, icon, image, summary, body, time, critical) plus `n`, the live notification while the sender keeps it.
    property var history: []
    readonly property int count: history.length

    function remember(n, critical) {
        const entry = { id: n.id, app: n.appName, icon: iconSource(n.appIcon), image: n.image ? n.image : "", summary: n.summary,
            body: n.body.replace(/<[^>]*>/g, ""), time: Date.now(), critical: critical, n: n }
        const rest = history.filter(e => e.id !== n.id)
        const all = [entry].concat(rest)
        for (const old of all.slice(50)) if (old.n) old.n.dismiss()
        history = all.slice(0, 50)
        n.closed.connect(() => forget(entry.id))
    }

    function forget(id) {
        history = history.filter(e => e.id !== id)
    }

    // Removes one entry from the center (and tells the sender).
    function remove(id) {
        const e = history.find(x => x.id === id)
        forget(id)
        if (source && source.id === id) hide()
        if (e && e.n) e.n.dismiss()
    }

    // Runs the default action of an entry (opens the sender), then removes it.
    function activate(id) {
        const e = history.find(x => x.id === id)
        if (e && e.n && e.n.actions) for (const a of e.n.actions) if (a.identifier === "default") { a.invoke(); break }
        remove(id)
    }

    function clearAll() {
        const all = history
        history = []
        hide()
        for (const e of all) if (e.n) e.n.dismiss()
    }

    property bool active: false
    property string app: ""
    property string icon: ""
    property string image: ""
    property string summary: ""
    property string body: ""
    property bool critical: false
    property var source: null

    readonly property string defaultActionId: {
        const list = source && source.actions ? source.actions : []
        for (const a of list) if (a.identifier === "default") return a.identifier
        return ""
    }

    function invokeDefault() {
        if (source && defaultActionId !== "") {
            for (const a of source.actions) if (a.identifier === "default") { a.invoke(); break }
        }
        dismiss()
    }

    // The popup goes away on its own after a while; the notification stays in the center.
    function hide() {
        hideTimer.stop()
        active = false
        source = null
    }

    // Closing the popup explicitly removes the notification too.
    function dismiss() {
        const n = source
        hide()
        if (n) {
            forget(n.id)
            n.dismiss()
        }
    }

    function iconSource(name) {
        if (!name) return ""
        return name.startsWith("/") ? "file://" + name : Quickshell.iconPath(name, true)
    }

    onPausedChanged: {
        if (!active) return
        if (paused) hideTimer.stop()
        else hideTimer.restart()
    }

    NotificationServer {
        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true
            const critical = n.urgency === NotificationUrgency.Critical
            if (LockState.showing)
                root.unread = [{ app: n.appName, summary: n.summary, body: n.body.replace(/<[^>]*>/g, ""), time: Date.now() }].concat(root.unread).slice(0, 20)
            root.remember(n, critical)
            if (root.dnd && !critical) return
            // The center is open: the new entry shows up in it, no popup on top.
            if (PanelState.isOpen("notifs")) return
            if (PanelState.isOpen("dashboard")) root.missed++

            root.source = n
            root.app = n.appName
            root.icon = root.iconSource(n.appIcon)
            root.image = n.image ? n.image : ""
            root.summary = n.summary
            root.body = n.body
            root.critical = critical
            root.active = true

            hideTimer.interval = critical ? 15000 : (n.expireTimeout > 0 ? Math.min(n.expireTimeout * 1000, 9000) : 5000)
            if (!root.paused) hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        onTriggered: root.hide()
    }

    IpcHandler {
        target: "notifications"
        function toggleDnd(): void { root.dnd = !root.dnd }
        function setDnd(value: bool): void { root.dnd = value }
        function dismiss(): void { root.dismiss() }
        function clear(): void { root.clearAll() }
        function count(): int { return root.count }
    }
}
