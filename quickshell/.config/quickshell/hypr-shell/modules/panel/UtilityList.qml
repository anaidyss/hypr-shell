import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.components

// Left block of the utility branch: the input and the result list. `ctl` is the branch that owns the selection.
Block {
    id: root

    required property var ctl

    readonly property real rowH: 34
    readonly property bool subMode: Omnibox.mode !== "main"

    order: 0

    function focusInput() {
        PanelState.typing = true
        PanelState.typed()
        input.forceActiveFocus()
    }

    Connections {
        target: root.ctl
        function onIndexChanged() {
            if (root.ctl.keyNav) list.positionViewAtIndex(root.ctl.index, root.ctl.index === 0 ? ListView.Beginning : ListView.Contain)
        }
    }

    Surface {
        id: field
        width: parent.width
        height: 40
        radius: Theme.radiusLg
        color: Theme.panelPill
        borderColor: input.activeFocus ? Theme.borderActive : Theme.border

        Behavior on borderColor { ColorAnimation { duration: Theme.durFast } }

        PanelIcon {
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            name: "search"
            size: 16
            color: Theme.textDim
        }

        Text {
            anchors { left: parent.left; leftMargin: 38; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            visible: input.text === ""
            text: Omnibox.mode === "clip" ? "Filter history" : (Omnibox.mode === "note" ? "Search notes or type a new title" : "Search apps or calculate")
            color: Theme.textOff
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
        }

        TextInput {
            id: input
            anchors { left: parent.left; leftMargin: 38; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            height: 28
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentText
            clip: true
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }

            text: Omnibox.query
            onTextChanged: {
                if (Omnibox.query !== text) Omnibox.query = text
                PanelState.typed()
            }

            Connections {
                target: Omnibox
                function onQueryChanged() { if (input.text !== Omnibox.query) input.text = Omnibox.query }
            }

            Keys.onPressed: event => {
                const ctrl = event.modifiers & Qt.ControlModifier
                if (event.key === Qt.Key_Escape) { PanelState.dismiss("utility"); event.accepted = true }
                else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || (ctrl && (event.key === Qt.Key_N || event.key === Qt.Key_J))) { root.ctl.move(1); event.accepted = true }
                else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && (event.key === Qt.Key_P || event.key === Qt.Key_K))) { root.ctl.move(-1); event.accepted = true }
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { Omnibox.activate(root.ctl.current); event.accepted = true }
                else if (event.key === Qt.Key_Delete && Omnibox.mode === "clip") { root.ctl.removeCurrent(); event.accepted = true }
                else if (event.key === Qt.Key_Backspace && text === "" && root.subMode) { Omnibox.leaveMode(); event.accepted = true }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onPressed: mouse => { root.focusInput(); mouse.accepted = false }
        }
    }

    ListView {
        id: list
        y: field.height + Theme.gapTile
        width: parent.width
        height: parent.height - y
        clip: true
        spacing: 4
        model: root.ctl.rows
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            id: row

            required property var modelData
            required property int index
            readonly property bool selected: index === root.ctl.index
            readonly property string kind: modelData.kind

            width: list.width
            height: root.rowH
            radius: Theme.radiusSm
            color: selected ? Theme.panelPill : "transparent"

            Behavior on color { ColorAnimation { duration: Theme.durFast } }

            Item {
                id: lead
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22

                Image {
                    anchors.fill: parent
                    visible: row.kind === "app" && status === Image.Ready
                    sourceSize: Qt.size(44, 44)
                    smooth: true
                    mipmap: true
                    source: row.kind !== "app" ? "" : (row.modelData.entry.icon.startsWith("/") ? "file://" + row.modelData.entry.icon : Quickshell.iconPath(row.modelData.entry.icon, true))
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    visible: row.kind === "clip" && row.modelData.ctype === "color"
                    radius: Theme.radiusSm * 0.6
                    color: row.modelData.color || "transparent"
                    border { width: 1; color: Theme.border }
                }
                PanelIcon {
                    anchors.centerIn: parent
                    visible: row.kind !== "app" && !(row.kind === "clip" && row.modelData.ctype === "color")
                    name: row.kind === "calc" ? (row.modelData.recent ? "clock" : "calculator")
                        : (row.kind === "note" ? "note" : (row.kind === "newnote" ? "plus" : (row.modelData.ctype === "image" ? "image" : "clipboard")))
                    size: 18
                    color: row.selected ? Theme.text : Theme.textDim
                }
            }

            PanelIcon {
                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                visible: row.kind === "note" && Notes.isPinned(row.modelData.path)
                name: "pin"
                size: 14
                color: Theme.textDim
            }

            Text {
                anchors { left: lead.right; leftMargin: 10; right: parent.right; rightMargin: row.kind === "note" && Notes.isPinned(row.modelData.path) ? 32 : 10; verticalCenter: parent.verticalCenter }
                text: row.kind === "calc" ? (row.modelData.sub + " = " + row.modelData.title)
                    : (row.kind === "newnote" ? (row.modelData.title !== "" ? "New note “" + row.modelData.title + "”" : "New note")
                    : (row.kind === "clip" && row.modelData.ctype === "image" ? "Image · " + row.modelData.meta : row.modelData.title))
                color: row.selected ? Theme.text : Theme.textDim
                elide: Text.ElideRight
                font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: { root.ctl.keyNav = false; root.ctl.index = row.index }
                onClicked: Omnibox.activate(row.modelData)
            }
        }
    }
}
