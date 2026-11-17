import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.components

// Workspace overview: a plate per workspace with its windows laid out as in the compositor, each a live thumbnail
// refreshed every few seconds. Click a plate to switch, click a window to focus it, drag a window to another plate
// (or to the "+" plate for a new workspace), middle click or the corner button closes it.
Item {
    id: root

    readonly property real pad: 12
    readonly property int cols: 2
    readonly property real gap: Theme.gapTile
    readonly property real cellW: 232
    readonly property real labelH: 20
    readonly property real cellH: Math.round(cellW * 0.62) + labelH
    readonly property real inset: 6
    readonly property int cellCount: spaces.length + (dragging ? 1 : 0)
    readonly property int rows: Math.max(1, Math.ceil(cellCount / cols))
    readonly property int shownRows: Math.min(3, rows)

    property var spaces: []
    property string sig: ""
    property string dragAddr: ""
    property var dragTop: null
    property string dragIcon: ""
    property real gx: 0
    property real gy: 0
    property int dropIndex: -1
    readonly property bool dragging: dragAddr !== ""
    readonly property int nextId: spaces.reduce((m, c) => Math.max(m, c.id), 0) + 1
    readonly property var live: build()

    signal shot()

    implicitWidth: 2 * pad + cols * cellW + (cols - 1) * gap
    implicitHeight: 2 * pad + shownRows * cellH + (shownRows - 1) * gap

    function iconFor(cls) {
        const entry = DesktopEntries.heuristicLookup(cls)
        const name = entry && entry.icon ? entry.icon : cls
        return name.startsWith("/") ? "file://" + name : Quickshell.iconPath(name, true)
    }

    function build() {
        const tops = Hyprland.toplevels.values
        const out = []
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id <= 0) continue
            const mon = ws.monitor
            const scale = mon && mon.scale > 0 ? mon.scale : 1
            const wins = []
            for (const t of tops) {
                if (!t.workspace || t.workspace.id !== ws.id) continue
                const o = t.lastIpcObject
                if (!o || !o.at || !o.size || o.class === "hs-miniterm") continue
                wins.push({ top: t, icon: root.iconFor(o.class || ""), x: o.at[0], y: o.at[1], w: o.size[0], h: o.size[1], active: t.activated })
            }
            out.push({ ws: ws, id: ws.id, focused: ws.focused, mw: mon ? mon.width / scale : 1560, mh: mon ? mon.height / scale : 1040, windows: wins })
        }
        out.sort((a, b) => a.id - b.id)
        return out
    }

    function sync() {
        if (dragging) return
        const sg = JSON.stringify(live.map(c => [c.id, c.focused, c.mw, c.mh, c.windows.map(w => [w.top.address, w.icon, w.x, w.y, w.w, w.h, w.active])]))
        if (sg === sig) return
        sig = sg
        spaces = live
    }

    function refresh() {
        Hyprland.refreshWorkspaces()
        Hyprland.refreshToplevels()
        Qt.callLater(sync)
    }

    function moveWindow(top, id) {
        const a = top.address.startsWith("0x") ? top.address : "0x" + top.address
        Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.window.move({ workspace = ' + id + ', window = "address:' + a + '", follow = false })'])
        refreshSoon.restart()
    }

    function dragAt(px, py) {
        gx = px
        gy = py
        const p = flick.mapFromItem(null, px, py)
        let idx = -1
        if (p.x >= 0 && p.y >= 0 && p.x < flick.width && p.y < flick.height) {
            const col = Math.floor(p.x / (cellW + gap))
            const row = Math.floor((p.y + flick.contentY) / (cellH + gap))
            if (col < cols) idx = row * cols + col
        }
        if (idx >= cellCount) idx = -1
        dropIndex = idx
    }

    function dropDrag() {
        const top = dragTop
        const idx = dropIndex
        const id = idx < 0 ? -1 : (idx < spaces.length ? spaces[idx].id : nextId)
        dragTop = null
        dragAddr = ""
        dropIndex = -1
        if (top && id > 0) moveWindow(top, id)
        Qt.callLater(sync)
    }

    onLiveChanged: sync()
    Component.onCompleted: { sync(); refresh() }
    onVisibleChanged: if (visible) { refresh(); shot() }

    Timer { id: refreshSoon; interval: 350; onTriggered: root.refresh() }
    Timer { interval: 2000; repeat: true; running: root.visible; onTriggered: root.refresh() }
    // Thumbnails are captured on open and then rarely.
    Timer { interval: 5000; repeat: true; running: root.visible; onTriggered: root.shot() }

    Text {
        anchors.centerIn: parent
        visible: root.spaces.length === 0
        text: "No workspaces"
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
    }

    Flickable {
        id: flick
        x: root.pad
        y: root.pad
        width: root.width - 2 * root.pad
        height: root.height - 2 * root.pad
        clip: true
        contentWidth: width
        contentHeight: root.rows * (root.cellH + root.gap) - root.gap
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Repeater {
            model: root.spaces

            Item {
                id: cell
                required property var modelData
                required property int index

                x: (index % root.cols) * (root.cellW + root.gap)
                y: Math.floor(index / root.cols) * (root.cellH + root.gap)
                width: root.cellW
                height: root.cellH

                Text {
                    x: 4
                    height: root.labelH
                    verticalAlignment: Text.AlignVCenter
                    text: cell.modelData.id + (cell.modelData.windows.length > 0 ? "  ·  " + cell.modelData.windows.length : "")
                    color: cell.modelData.focused ? Theme.accent : Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
                }

                Tile {
                    id: plate
                    y: root.labelH
                    width: parent.width
                    height: parent.height - root.labelH
                    radius: Theme.radiusSm
                    tone: cell.modelData.focused ? Theme.accentContainer : "transparent"
                    borderWidth: root.dropIndex === cell.index ? 2 : 1
                    borderColor: root.dropIndex === cell.index ? Theme.accent : Theme.border

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cell.modelData.ws.activate()
                    }

                    Item {
                        id: screen
                        readonly property real availW: plate.width - 2 * root.inset
                        readonly property real availH: plate.height - 2 * root.inset
                        readonly property real s: Math.min(availW / cell.modelData.mw, availH / cell.modelData.mh)
                        x: root.inset + (availW - cell.modelData.mw * s) / 2
                        y: root.inset + (availH - cell.modelData.mh * s) / 2
                        width: cell.modelData.mw * s
                        height: cell.modelData.mh * s
                        clip: true

                        Rectangle { anchors.fill: parent; radius: Theme.radiusSm * 0.6; color: Theme.panelDeep }

                        Repeater {
                            model: cell.modelData.windows

                            WsWindow {
                                required property var modelData
                                info: modelData
                                scaleFactor: screen.s
                                held: root.dragAddr === modelData.top.address
                                onClicked: { cell.modelData.ws.activate(); if (modelData.top.wayland) modelData.top.wayland.activate() }
                                onCloseRequested: { if (modelData.top.wayland) modelData.top.wayland.close(); refreshSoon.restart() }
                                onDragStarted: (px, py) => {
                                    root.dragTop = modelData.top
                                    root.dragAddr = modelData.top.address
                                    root.dragIcon = modelData.icon
                                    root.dragAt(px, py)
                                }
                                onDragMoved: (px, py) => root.dragAt(px, py)
                                onDragEnded: root.dropDrag()
                                Component.onCompleted: root.shot.connect(capture)
                            }
                        }
                    }

                    PanelIcon {
                        anchors.centerIn: parent
                        visible: cell.modelData.windows.length === 0
                        name: "layers"
                        size: 24
                        color: Theme.textOff
                    }
                }
            }
        }

        // Drop target that creates a new workspace; present only while a window is dragged.
        Tile {
            visible: root.dragging
            x: (root.spaces.length % root.cols) * (root.cellW + root.gap)
            y: Math.floor(root.spaces.length / root.cols) * (root.cellH + root.gap) + root.labelH
            width: root.cellW
            height: root.cellH - root.labelH
            radius: Theme.radiusSm
            borderWidth: root.dropIndex === root.spaces.length ? 2 : 1
            borderColor: root.dropIndex === root.spaces.length ? Theme.accent : Theme.border
            PanelIcon { anchors.centerIn: parent; name: "plus"; size: 24; color: Theme.textDim }
        }
    }

    // The dragged window follows the pointer as a small copy.
    Rectangle {
        visible: root.dragging
        x: root.mapFromItem(null, root.gx, root.gy).x - width / 2
        y: root.mapFromItem(null, root.gx, root.gy).y - height / 2
        width: 44
        height: 36
        radius: Theme.radiusSm
        color: Theme.accentContainer
        border.width: 1
        border.color: Theme.borderActive
        z: 10
        Image {
            anchors.centerIn: parent
            width: 22
            height: 22
            source: root.dragIcon
            sourceSize: Qt.size(44, 44)
        }
    }
}
