import QtQuick
import qs.theme
import qs.services

// Paint mode of the color picker, over the panel window: highlights the part of the shell under the pointer (a card,
// a tile, a pill, the strip, text, an accent fill) and applies the picked color to its role on click (right click
// clears that role). The pointer still hovers the items below, so branches keep opening while painting.
Item {
    id: root

    // The item whose subtree is searched, and the strip (a click on its bare background paints the frame).
    required property Item scene
    property Item rail: null

    property string role: ""
    property Item target: null

    visible: ColorPicker.painting

    function roleOf(it) {
        if (typeof it.paintRole === "string" && it.paintRole !== "") return it.paintRole
        const c = it.color
        if (c !== undefined && c !== null && c.a > 0.3) {
            if (Qt.colorEqual(c, Theme.accent)) return "accent"
            if (Qt.colorEqual(c, Theme.text) || Qt.colorEqual(c, Theme.textDim)) return "text"
        }
        return ""
    }

    // The topmost visible descendant of `item` at (x, y) (in item coordinates) that has a role.
    function find(item, x, y) {
        const kids = item.children
        for (let i = kids.length - 1; i >= 0; i--) {
            const c = kids[i]
            if (c === root || !c.visible || c.opacity < 0.05) continue
            const p = item.mapToItem(c, x, y)
            const inside = p.x >= 0 && p.y >= 0 && p.x <= c.width && p.y <= c.height
            const flat = c.width === 0 && c.height === 0
            if (!inside && !flat) continue
            const r = find(c, p.x, p.y)
            if (r) return r
            if (inside) {
                const role = roleOf(c)
                if (role !== "") return { item: c, role: role }
            }
        }
        return null
    }

    function update(x, y) {
        let hit = find(scene, x, y)
        if (!hit && rail) {
            const p = scene.mapToItem(rail, x, y)
            if (p.x >= 0 && p.y >= 0 && p.x <= rail.width && p.y <= rail.height) hit = { item: rail, role: "frame" }
        }
        role = hit ? hit.role : ""
        target = hit ? hit.item : null
        ColorPicker.hoverRole = role
    }

    Connections {
        target: ColorPicker
        function onProbeRequested(x, y) { root.update(x, y) }
    }

    HoverHandler {
        id: hover
        enabled: root.visible
        onPointChanged: root.update(point.position.x, point.position.y)
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.visible
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.role === "" ? Qt.ArrowCursor : Qt.CrossCursor
        onPressed: mouse => {
            root.update(mouse.x, mouse.y)
            if (root.role === "") return
            if (mouse.button === Qt.RightButton) ColorPicker.clear(root.role)
            else ColorPicker.apply(root.role)
        }
    }

    Rectangle {
        readonly property point origin: root.target ? root.mapFromItem(root.target, 0, 0) : Qt.point(0, 0)
        visible: root.target !== null && root.role !== ""
        x: origin.x
        y: origin.y
        width: root.target ? root.target.width : 0
        height: root.target ? root.target.height : 0
        radius: Theme.radiusSm
        color: Qt.alpha(ColorPicker.current === "" ? Theme.accent : ColorPicker.current, 0.35)
        border { width: 2; color: Theme.borderActive }
    }

    Rectangle {
        visible: root.role !== ""
        x: Math.min(root.width - width - 8, hover.point.position.x + 16)
        y: Math.max(8, hover.point.position.y - height - 8)
        width: tip.implicitWidth + 20
        height: 26
        radius: Theme.radiusSm
        color: Theme.panelBase
        border { width: 1; color: Theme.borderActive }

        Text {
            id: tip
            anchors.centerIn: parent
            text: ColorPicker.labelOf(root.role)
            color: Theme.text
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
        }
    }
}
