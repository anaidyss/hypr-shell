import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.components

// The Workspaces tab: one tile per workspace with a schematic of its windows laid out as in the compositor.
Item {
    id: root

    property bool active: false

    readonly property real gap: 8
    readonly property int cols: 4
    readonly property real tw: (width - (cols - 1) * gap) / cols
    readonly property real th: 152
    // Nested radii: each inner shape is its parent's radius minus the gap between them.
    readonly property real plateR: Math.round(Theme.radiusSm * 0.7)
    readonly property real inset: 6
    readonly property real frameR: plateR - inset
    readonly property real winR: frameR - 2
    readonly property int cellCount: spaces.length + (dragging ? 1 : 0)
    readonly property int shownRows: Math.min(2, Math.max(1, Math.ceil(cellCount / cols)))
    readonly property real wanted: shownRows * th + (shownRows - 1) * gap

    // The model is only replaced when something visible changed, and never during a drag,
    // otherwise every refresh would recreate the delegates and abort the gesture.
    property var spaces: []
    readonly property var live: build()
    property string sig: ""

    property var dragTop: null
    property string dragAddr: ""
    property string dragIcon: ""
    property int dragSrc: -1
    property real dragW: 0
    property real dragH: 0
    property real gx: 0
    property real gy: 0
    property int dropIndex: -1
    readonly property bool dragging: dragAddr !== ""
    readonly property int nextId: spaces.reduce((m, c) => Math.max(m, c.id), 0) + 1

    function iconFor(cls) {
        const entry = DesktopEntries.heuristicLookup(cls)
        const name = entry && entry.icon ? entry.icon : cls
        return name.startsWith("/") ? "file://" + name : Quickshell.iconPath(name, true)
    }

    function build() {
        const loaded = DesktopEntries.applications.values.length
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
                wins.push({
                    top: t,
                    title: t.title || o.title || o.class,
                    icon: root.iconFor(o.class || ""),
                    x: o.at[0], y: o.at[1], w: o.size[0], h: o.size[1],
                    active: t.activated
                })
            }
            out.push({
                ws: ws, id: ws.id, focused: ws.focused,
                mw: mon ? mon.width / scale : 1560, mh: mon ? mon.height / scale : 1040,
                windows: wins
            })
        }
        out.sort((a, b) => a.id - b.id)
        return out
    }

    function sync() {
        if (dragging) return
        const sg = JSON.stringify(live.map(c => [c.id, c.focused, c.mw, c.mh,
            c.windows.map(w => [w.top.address, w.title, w.icon, w.x, w.y, w.w, w.h, w.active])]))
        if (sg === sig) return
        sig = sg
        spaces = live
    }

    function refresh() {
        Hyprland.refreshWorkspaces()
        Hyprland.refreshToplevels()
    }

    function beginDrag(win, srcId, w, h) {
        dragTop = win.top
        dragAddr = win.top.address
        dragIcon = win.icon
        dragSrc = srcId
        dragW = w
        dragH = h
    }

    function dragMove(px, py) {
        gx = px
        gy = py
        let idx = -1
        if (px >= 0 && py >= 0 && py < height) {
            const col = Math.floor(px / (tw + gap))
            const row = Math.floor((py + flick.contentY) / (th + gap))
            if (col < cols) idx = row * cols + col
        }
        if (idx >= cellCount) idx = -1
        if (idx >= 0 && idx < spaces.length && spaces[idx].id === dragSrc) idx = -1
        dropIndex = idx
    }

    function endDrag() {
        const top = dragTop
        const idx = dropIndex
        const id = idx < 0 ? -1 : (idx < spaces.length ? spaces[idx].id : nextId)
        dragTop = null
        dragAddr = ""
        dropIndex = -1
        if (top && id > 0) moveWindow(top, id)
        Qt.callLater(sync)
    }

    function moveWindow(top, id) {
        const a = top.address.startsWith("0x") ? top.address : "0x" + top.address
        Quickshell.execDetached(["hyprctl", "dispatch",
            'hl.dsp.window.move({ workspace = ' + id + ', window = "address:' + a + '", follow = false })'])
        refreshSoon.restart()
    }

    function closeWindow(top) {
        if (top.wayland) top.wayland.close()
        refreshSoon.restart()
    }

    onLiveChanged: sync()
    Component.onCompleted: sync()
    onActiveChanged: {
        if (active) refresh()
        else { dragTop = null; dragAddr = ""; dropIndex = -1 }
    }

    Timer {
        id: refreshSoon
        interval: 350
        onTriggered: root.refresh()
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.active
        onTriggered: root.refresh()
    }

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: Math.max(height, Math.ceil(root.cellCount / root.cols) * (root.th + root.gap) - root.gap)
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Repeater {
            model: root.spaces

            delegate: Item {
                id: cell

                required property var modelData
                required property int index

                readonly property real labelH: 20
                property string hoverTitle: ""

                x: (index % root.cols) * (root.tw + root.gap)
                y: Math.floor(index / root.cols) * (root.th + root.gap)
                width: root.tw
                height: root.th

                Text {
                    id: num
                    x: 4
                    height: cell.labelH
                    verticalAlignment: Text.AlignVCenter
                    text: cell.modelData.id
                    color: cell.modelData.focused ? Theme.accent : Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
                }

                Text {
                    anchors { left: num.right; leftMargin: 8; right: parent.right; verticalCenter: num.verticalCenter }
                    elide: Text.ElideRight
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
                    text: cell.hoverTitle
                }

                DashTile {
                    id: plate
                    tone: cell.modelData.focused ? Theme.accentContainer : "transparent"

                    order: cell.index
                    y: cell.labelH
                    width: parent.width
                    height: parent.height - cell.labelH
                    radius: root.plateR
                    border.color: cell.modelData.focused ? Qt.alpha(Theme.accent, 0.55) : Theme.separator
                    Behavior on border.color { ColorAnimation { duration: Theme.durFast } }

                    MouseArea {
                        id: tileArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cell.modelData.ws.activate()
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: plate.radius
                        color: Theme.tile
                        opacity: tileArea.containsMouse ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
                    }

                    Item {
                        id: view

                        readonly property var wins: cell.modelData.windows
                        readonly property real mw: cell.modelData.mw
                        readonly property real mh: cell.modelData.mh
                        readonly property var box: {
                            let x0 = 0, y0 = 0, x1 = mw, y1 = mh
                            for (const w of wins) {
                                x0 = Math.min(x0, w.x)
                                y0 = Math.min(y0, w.y)
                                x1 = Math.max(x1, w.x + w.w)
                                y1 = Math.max(y1, w.y + w.h)
                            }
                            return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 }
                        }
                        readonly property real s: Math.min(width / box.w, height / box.h)
                        readonly property real ox: (width - box.w * s) / 2 - box.x * s
                        readonly property real oy: (height - box.h * s) / 2 - box.y * s

                        x: root.inset; y: root.inset
                        width: parent.width - 2 * root.inset
                        height: parent.height - 2 * root.inset

                        Rectangle {
                            x: view.ox; y: view.oy
                            width: view.mw * view.s
                            height: view.mh * view.s
                            radius: root.frameR
                            color: cell.modelData.focused ? Theme.panelPill : Theme.separator
                        }

                        Repeater {
                            model: view.wins

                            delegate: Rectangle {
                                id: win

                                required property var modelData

                                readonly property real iconSize: Math.min(22, width - 8, height - 8)

                                x: view.ox + modelData.x * view.s
                                y: view.oy + modelData.y * view.s
                                width: Math.max(6, modelData.w * view.s)
                                height: Math.max(6, modelData.h * view.s)
                                radius: root.winR
                                opacity: root.dragAddr === modelData.top.address ? 0.3 : 1
                                color: winArea.containsMouse ? Theme.hoverStrong : Theme.panelHigh
                                border.width: 1
                                border.color: modelData.active ? Theme.accent : Theme.panelPill
                                Behavior on color { ColorAnimation { duration: Theme.durFast } }

                                Image {
                                    anchors.centerIn: parent
                                    width: win.iconSize
                                    height: win.iconSize
                                    visible: win.iconSize >= 12 && status === Image.Ready
                                    sourceSize.width: 48
                                    sourceSize.height: 48
                                    smooth: true
                                    mipmap: true
                                    source: win.modelData.icon
                                }

                                MouseArea {
                                    id: winArea

                                    property point press
                                    property bool moved: false

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    preventStealing: true
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                    cursorShape: moved ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                    onContainsMouseChanged: cell.hoverTitle = containsMouse ? win.modelData.title : ""
                                    onClicked: mouse => {
                                        if (mouse.button === Qt.MiddleButton) { root.closeWindow(win.modelData.top); return }
                                        if (moved) return
                                        cell.modelData.ws.activate()
                                        if (win.modelData.top.wayland) win.modelData.top.wayland.activate()
                                    }
                                    onPressed: mouse => {
                                        moved = false
                                        press = mapToItem(root, mouse.x, mouse.y)
                                    }
                                    onPositionChanged: mouse => {
                                        if (!(pressedButtons & Qt.LeftButton)) return
                                        const p = mapToItem(root, mouse.x, mouse.y)
                                        if (!moved) {
                                            if (Math.hypot(p.x - press.x, p.y - press.y) < 6) return
                                            moved = true
                                            root.beginDrag(win.modelData, cell.modelData.id, win.width, win.height)
                                        }
                                        root.dragMove(p.x, p.y)
                                    }
                                    onReleased: if (moved && root.dragging) root.endDrag()
                                }

                                Rectangle {
                                    id: closeBtn

                                    readonly property bool shown: (winArea.containsMouse || closeArea.containsMouse)
                                        && !root.dragging && win.width >= 34 && win.height >= 26

                                    x: win.width - width - 4
                                    y: 4
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: closeArea.containsMouse ? Theme.danger : Qt.rgba(0, 0, 0, 0.55)
                                    opacity: shown ? 1 : 0
                                    visible: opacity > 0
                                    Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
                                    Behavior on color { ColorAnimation { duration: Theme.durFast } }

                                    PanelIcon { anchors.centerIn: parent; name: "close"; size: 10; color: Theme.text }

                                    MouseArea {
                                        id: closeArea
                                        anchors { fill: parent; margins: -3 }
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.closeWindow(win.modelData.top)
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: plate.radius
                        color: Qt.alpha(Theme.accent, 0.12)
                        border.width: 1
                        border.color: Theme.accent
                        opacity: root.dropIndex === cell.index ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
                    }
                }
            }
        }

        // Drop target that creates a new workspace; only present while a window is being dragged.
        Item {
            id: newCell

            readonly property int index: root.spaces.length

            x: (index % root.cols) * (root.tw + root.gap)
            y: Math.floor(index / root.cols) * (root.th + root.gap)
            width: root.tw
            height: root.th
            opacity: root.dragging ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easingCalm } }

            Text {
                x: 4
                height: 20
                verticalAlignment: Text.AlignVCenter
                text: root.nextId
                color: root.dropIndex === newCell.index ? Theme.accent : Theme.textDim
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
            }

            Rectangle {
                y: 20
                width: parent.width
                height: parent.height - 20
                radius: root.plateR
                color: root.dropIndex === newCell.index ? Qt.alpha(Theme.accent, 0.12) : "transparent"
                border.width: 1
                border.color: root.dropIndex === newCell.index ? Theme.accent : Theme.panelTrackHigh
                Behavior on color { ColorAnimation { duration: Theme.durFast } }

                PanelIcon {
                    anchors.centerIn: parent
                    name: "plus"
                    size: 22
                    color: root.dropIndex === newCell.index ? Theme.accent : Theme.textDim
                }
            }
        }
    }

    // The dragged window follows the pointer above everything else.
    Rectangle {
        z: 20
        visible: root.dragging
        width: Math.max(40, Math.min(root.dragW, 96))
        height: Math.max(30, Math.min(root.dragH, 72))
        x: root.gx - width / 2
        y: root.gy - height / 2
        radius: root.winR
        color: Theme.panelHigh
        border.width: 1
        border.color: Theme.accent
        opacity: 0.92

        Image {
            anchors.centerIn: parent
            width: 22
            height: 22
            visible: status === Image.Ready
            sourceSize.width: 48
            sourceSize.height: 48
            smooth: true
            mipmap: true
            source: root.dragIcon
        }
    }
}
