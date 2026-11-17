pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false
    property string page: "colors"
    property string pendingId: ""
    signal snapshotRequested(string path, string page)

    function show(name) {
        if (name) page = name
        open = true
    }

    // Jump to a specific setting: the page scrolls to the row and highlights it.
    function go(pageId, settingId) {
        pendingId = settingId
        page = pageId
        open = true
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { root.open = !root.open }
        function open(): void { root.show("") }
        function close(): void { root.open = false }
        function snapshot(path: string, page: string): void { root.snapshotRequested(path, page) }
        function page(name: string): void { root.show(name) }
        function find(settingId: string): void {
            for (const it of SettingsSchema.items)
                if (it.id === settingId) { root.go(it.page, it.id); return }
        }
    }
}
