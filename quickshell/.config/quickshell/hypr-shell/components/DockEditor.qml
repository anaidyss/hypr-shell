import QtQuick
import Quickshell
import qs.theme

// Pinned apps of the dock (theme.json: dock.pinned): reorder, remove, and add from the installed applications.
Item {
    id: root

    readonly property var pinned: {
        const out = []
        for (const id of Theme.cfg.dock.pinned) out.push(id)
        return out
    }
    readonly property var pinnedKeys: {
        const keys = {}
        for (const id of pinned) {
            const e = DesktopEntries.heuristicLookup(id)
            keys[id.toLowerCase()] = true
            if (e) keys[e.id.toLowerCase()] = true
        }
        return keys
    }
    readonly property var candidates: {
        const q = search.text.trim().toLowerCase()
        const out = []
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay || pinnedKeys[e.id.toLowerCase()]) continue
            if (q !== "" && e.name.toLowerCase().indexOf(q) < 0 && e.id.toLowerCase().indexOf(q) < 0) continue
            out.push(e)
        }
        out.sort((a, b) => a.name.localeCompare(b.name))
        return out.slice(0, 6)
    }

    width: parent ? parent.width : implicitWidth
    implicitHeight: 12 + tiles.height + 14 + 34 + 8 + addGrid.height + 12

    function iconFor(entry, id) {
        const name = entry ? entry.icon : id
        if (!name) return ""
        return name.startsWith("/") ? "file://" + name : Quickshell.iconPath(name, true)
    }

    function write(list) { Theme.set("dock", "pinned", list) }

    function move(i, d) {
        const j = i + d
        if (j < 0 || j >= pinned.length) return
        const list = pinned.slice()
        const t = list[i]; list[i] = list[j]; list[j] = t
        write(list)
    }

    function remove(i) {
        const list = pinned.slice()
        list.splice(i, 1)
        write(list)
    }

    function add(entry) {
        const list = pinned.slice()
        list.push(entry.id)
        write(list)
        search.text = ""
    }

    component MiniButton: Rectangle {
        id: btn
        property string icon
        property bool enabled: true
        signal clicked()
        width: 28; height: 28; radius: 14
        color: hover.hovered && enabled ? Theme.panelHigh : Theme.panelPill
        opacity: enabled ? 1 : Theme.disabledOpacity
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
        PanelIcon { anchors.centerIn: parent; name: btn.icon; size: 14; color: Theme.text }
        HoverHandler { id: hover; cursorShape: btn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
        TapHandler { enabled: btn.enabled; onTapped: btn.clicked() }
    }

    Flow {
        id: tiles
        y: 12
        width: parent.width
        spacing: 8

        Repeater {
            model: root.pinned

            delegate: Item {
                id: cell

                required property string modelData
                required property int index
                readonly property var entry: DesktopEntries.heuristicLookup(modelData)

                width: 96
                height: 96

                Surface {
                    id: tile
                    x: (parent.width - width) / 2
                    width: 56; height: 56
                    radius: Theme.radiusSm
                    color: cellHover.hovered ? Theme.panelPill : Theme.panelRaised

                    Image {
                        id: icon
                        anchors.centerIn: parent
                        width: 36; height: 36
                        sourceSize: Qt.size(72, 72)
                        smooth: true; mipmap: true
                        source: root.iconFor(cell.entry, cell.modelData)
                        visible: status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: !icon.visible
                        text: (cell.entry ? cell.entry.name : cell.modelData).charAt(0).toUpperCase()
                        color: Theme.accent
                        font { family: Theme.fontUi; pixelSize: 18; weight: Theme.wStrong }
                    }
                }

                Text {
                    y: 62
                    width: parent.width
                    height: 28
                    visible: !cellHover.hovered
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: cell.entry ? cell.entry.name : cell.modelData
                    color: Theme.text
                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                }

                Row {
                    y: 62
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: cellHover.hovered
                    spacing: 4
                    MiniButton { icon: "chevronLeft"; enabled: cell.index > 0; onClicked: root.move(cell.index, -1) }
                    MiniButton { icon: "close"; onClicked: root.remove(cell.index) }
                    MiniButton { icon: "chevronRight"; enabled: cell.index < root.pinned.length - 1; onClicked: root.move(cell.index, 1) }
                }

                HoverHandler { id: cellHover }
            }
        }
    }

    Text {
        y: 12
        height: 56
        visible: root.pinned.length === 0
        verticalAlignment: Text.AlignVCenter
        text: "No pinned apps"
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
    }

    Rectangle {
        id: field
        y: 12 + Math.max(tiles.height, 56) + 14
        width: parent.width
        height: 34
        radius: Theme.radiusSm
        color: Theme.tile
        border.width: 1
        border.color: search.activeFocus ? Qt.alpha(Theme.accent, 0.6) : Theme.border

        PanelIcon { x: 12; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 14; color: Theme.textDim }
        TextInput {
            id: search
            anchors { fill: parent; leftMargin: 34; rightMargin: 12 }
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentText
            clip: true
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: search.text === ""
                text: "Add app"
                color: Theme.textOff
                font: search.font
            }
        }
    }

    Grid {
        id: addGrid
        y: field.y + field.height + 8
        width: parent.width
        columns: 2
        spacing: 8

        Repeater {
            model: root.candidates

            delegate: Rectangle {
                id: row
                required property var modelData
                width: (addGrid.width - 8) / 2
                height: 36
                radius: Theme.radiusSm
                color: rowHover.hovered ? Theme.panelPill : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.durFast } }

                Image {
                    id: rowIcon
                    x: 8; anchors.verticalCenter: parent.verticalCenter
                    width: 24; height: 24
                    sourceSize: Qt.size(48, 48)
                    smooth: true; mipmap: true
                    source: root.iconFor(row.modelData, "")
                }
                Text {
                    anchors { left: rowIcon.right; leftMargin: 8; right: plus.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    elide: Text.ElideRight
                    text: row.modelData.name
                    color: Theme.text
                    font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                }
                PanelIcon {
                    id: plus
                    anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    name: "plus"; size: 14
                    color: rowHover.hovered ? Theme.accent : Theme.textDim
                }
                HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.add(row.modelData) }
            }
        }
    }

    Text {
        y: field.y + field.height + 8
        height: 36
        visible: root.candidates.length === 0
        verticalAlignment: Text.AlignVCenter
        text: "Nothing found"
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
    }
}
