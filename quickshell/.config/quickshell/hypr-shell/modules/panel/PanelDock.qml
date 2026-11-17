import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.components

// Pinned apps (theme.json: dock.pinned) plus every running app that is not pinned.
Grid {
    id: root

    property bool vertical: false
    // Which apps to list: "all" (default), "pinned" only, or "running" (open apps that are not pinned).
    property string group: "all"
    readonly property real cell: vertical ? 34 : 38
    readonly property var items: build()

    columns: vertical ? 1 : 32
    spacing: 2

    function build() {
        // Reading the application list here makes the dock rebuild when it finishes loading.
        const loaded = DesktopEntries.applications.values.length
        const map = {}
        const out = []
        for (const id of Theme.cfg.dock.pinned) {
            const entry = DesktopEntries.heuristicLookup(id)
            const item = { id: id, entry: entry, pinned: true, windows: [] }
            map[(entry ? entry.id : id).toLowerCase()] = item
            out.push(item)
        }
        for (const t of ToplevelManager.toplevels.values) {
            const appId = t.appId || ""
            if (appId === "" || appId === "hs-miniterm") continue
            const entry = DesktopEntries.heuristicLookup(appId)
            const key = (entry ? entry.id : appId).toLowerCase()
            let item = map[key]
            if (!item) {
                item = { id: appId, entry: entry, pinned: false, windows: [] }
                map[key] = item
                out.push(item)
            }
            item.windows.push(t)
        }
        if (root.group === "pinned") return out.filter(i => i.pinned)
        if (root.group === "running") return out.filter(i => !i.pinned && i.windows.length > 0)
        return out
    }

    function iconFor(item) {
        const name = item.entry ? item.entry.icon : item.id
        if (!name) return ""
        return name.startsWith("/") ? "file://" + name : Quickshell.iconPath(name, true)
    }

    function activate(item) {
        const ws = item.windows
        if (ws.length === 0) {
            if (item.entry) item.entry.execute()
            return
        }
        const current = ws.findIndex(w => w.activated)
        ws[(current + 1) % ws.length].activate()
    }

    Repeater {
        model: root.items

        delegate: Item {
            id: app

            required property var modelData

            readonly property bool running: modelData.windows.length > 0
            readonly property bool active: modelData.windows.some(w => w.activated)

            width: root.cell
            height: root.cell

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusSm
                color: area.containsMouse ? Theme.tile : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
            }

            Image {
                id: icon
                anchors.centerIn: parent
                anchors.verticalCenterOffset: root.vertical ? 0 : -2
                width: root.cell - 12
                height: root.cell - 12
                sourceSize.width: 64
                sourceSize.height: 64
                smooth: true
                mipmap: true
                source: root.iconFor(app.modelData)
                visible: status === Image.Ready
                scale: area.pressed ? 0.9 : (area.containsMouse ? 1.08 : 1)
                Behavior on scale { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
            }

            Rectangle {
                anchors.fill: icon
                visible: !icon.visible
                radius: Theme.radiusSm
                color: Qt.alpha(Theme.accent, 0.18)
                Text {
                    anchors.centerIn: parent
                    text: (app.modelData.entry ? app.modelData.entry.name : app.modelData.id).charAt(0).toUpperCase()
                    color: Theme.accent
                    font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
                }
            }

            Rectangle {
                visible: app.running
                x: root.vertical ? 1 : (parent.width - width) / 2
                y: root.vertical ? (parent.height - height) / 2 : parent.height - height - 3
                width: root.vertical ? 3 : (app.active ? 14 : 5)
                height: root.vertical ? (app.active ? 14 : 5) : 3
                radius: 1.5
                color: app.active ? Theme.accent : Theme.textDim
                Behavior on width { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
                Behavior on height { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onClicked: mouse => {
                    if (mouse.button === Qt.MiddleButton) { if (app.modelData.entry) app.modelData.entry.execute() }
                    else root.activate(app.modelData)
                }
            }
        }
    }
}
