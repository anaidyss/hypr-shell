import QtQuick
import qs.theme
import qs.services
import qs.components

// Note: the editor. Changes are saved to the .md file shortly after typing stops.
Item {
    id: root

    property var row

    signal back()
    signal remove()

    readonly property bool on: row !== null && row !== undefined && row.kind === "note"
    readonly property bool ready: on && Notes.loadedPath === row.path

    anchors.fill: parent

    function focusEdit() {
        PanelState.typing = true
        PanelState.typed()
        edit.forceActiveFocus()
    }

    function ago(ms) {
        const s = Math.max(0, (Date.now() - ms) / 1000)
        if (s < 60) return "just now"
        if (s < 3600) return Math.floor(s / 60) + " min ago"
        if (s < 86400) return Math.floor(s / 3600) + " h ago"
        return Math.floor(s / 86400) + " d ago"
    }

    Connections {
        target: Notes
        function onLoadedPathChanged() {
            edit.loading = true
            edit.text = Notes.loadedPath === "" ? "" : Notes.loaded
            edit.loading = false
        }
    }

    Connections {
        target: Omnibox
        function onEditRequested() {
            if (!root.visible) return
            PanelState.typing = true
            PanelState.typed()
            edit.forceActiveFocus()
        }
    }

    Text {
        id: title
        anchors { left: parent.left; right: parent.right; top: parent.top }
        text: root.on ? root.row.title : ""
        color: Theme.text
        elide: Text.ElideRight
        font { family: Theme.fontUi; pixelSize: 18; weight: Theme.wStrong }
    }

    Text {
        id: meta
        anchors { left: parent.left; right: parent.right; top: title.bottom; topMargin: 2 }
        text: root.on ? "Edited " + root.ago(root.row.mtime) : ""
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
    }

    Flickable {
        anchors { left: parent.left; right: parent.right; top: meta.bottom; topMargin: 8; bottom: bar.top; bottomMargin: 8 }
        contentWidth: width
        contentHeight: Math.max(height, edit.contentHeight + 4)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        TextEdit {
            id: edit
            property bool loading: false
            width: parent.width
            height: Math.max(parent.height, contentHeight + 4)
            readOnly: !root.ready
            wrapMode: TextEdit.Wrap
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentText
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }

            onTextChanged: {
                if (loading || !root.ready) return
                Notes.edit(text)
                PanelState.typed()
            }
            onActiveFocusChanged: if (activeFocus) { PanelState.typing = true; PanelState.typed() }
            Keys.onEscapePressed: root.back()
        }
    }

    Item {
        id: bar
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 28

        Text {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: edit.activeFocus ? "Esc to go back" : "Enter to edit"
            color: Theme.textOff
            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 4

            Rectangle {
                width: 28
                height: 28
                radius: Theme.radiusSm
                color: pinHover.hovered ? Theme.panelPill : "transparent"

                PanelIcon { anchors.centerIn: parent; name: "pin"; size: 16; color: root.on && Notes.isPinned(root.row.path) ? Theme.accent : Theme.textDim }
                HoverHandler { id: pinHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: if (root.on) Notes.togglePin(root.row.path, PanelState.screenName) }
            }

            Rectangle {
                width: 28
                height: 28
                radius: Theme.radiusSm
                color: trashHover.hovered ? Theme.panelPill : "transparent"

                PanelIcon { anchors.centerIn: parent; name: "trash"; size: 16; color: Theme.textDim }
                HoverHandler { id: trashHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.remove() }
            }
        }
    }
}
