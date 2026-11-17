import QtQuick
import qs.theme
import qs.services
import qs.components

// Notes menu of the strip: the list with search and "new note", and the editor of one note. The same notes
// (plain .md files) as the utility branch and the stickies; the editor is the utility branch's own.
Item {
    id: root

    implicitWidth: 380
    implicitHeight: 372

    property string query: ""
    property int index: 0
    // The note being edited, as a row of Notes.rows(); null while the list is shown.
    property var editing: null

    readonly property var rows: Notes.rows(query)

    onRowsChanged: index = Math.max(0, Math.min(index, rows.length - 1))

    function activate(row) {
        if (!row) return
        if (row.kind === "newnote") Notes.create(row.title)
        else openNote(row)
    }

    function openNote(row) {
        editing = row
        Notes.open(row.path)
        PanelState.typing = false
        editFocus.restart()
    }

    function leave() {
        editing = null
        Notes.flush()
        Notes.open("")
        Notes.reload()
    }

    Timer { id: editFocus; interval: 120; onTriggered: if (root.editing) editor.focusEdit() }

    Component.onCompleted: Notes.reload()

    Connections {
        target: Notes
        function onCreated(path) { root.openNote({ kind: "note", path: path, title: Notes.nameOf(path), mtime: Date.now() }) }
    }

    Block {
        anchors { fill: parent; margins: 12 }
        title: "Notes"
        icon: "note"
        tone: Theme.accentContainer

        ActionButton {
            visible: root.editing !== null
            anchors { right: parent.right; top: parent.top; topMargin: -34 }
            icon: "chevronLeft"
            text: "All notes"
            onClicked: root.leave()
        }

        Item {
            anchors.fill: parent
            visible: root.editing === null

            Surface {
                id: field
                width: parent.width
                height: 36
                radius: Theme.radiusLg
                color: Theme.panelPill
                borderColor: input.activeFocus ? Theme.borderActive : Theme.border

                PanelIcon { x: 12; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 16; color: Theme.textDim }

                Text {
                    anchors { left: parent.left; leftMargin: 38; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    visible: input.text === ""
                    text: "Search or type a new title"
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
                    onTextChanged: { root.query = text; PanelState.typed() }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) { PanelState.dismiss("notes"); event.accepted = true }
                        else if (event.key === Qt.Key_Down) { root.index = Math.min(root.rows.length - 1, root.index + 1); event.accepted = true }
                        else if (event.key === Qt.Key_Up) { root.index = Math.max(0, root.index - 1); event.accepted = true }
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.activate(root.rows[root.index]); event.accepted = true }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    onPressed: mouse => { PanelState.typing = true; PanelState.typed(); input.forceActiveFocus(); mouse.accepted = false }
                }
            }

            ListView {
                id: list
                y: field.height + Theme.gapsIn
                width: parent.width
                height: parent.height - y
                clip: true
                spacing: 4
                model: root.rows
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool selected: index === root.index

                    width: list.width
                    height: 34
                    radius: Theme.radiusSm
                    color: selected ? Theme.panelPill : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }

                    PanelIcon {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        name: row.modelData.kind === "newnote" ? "plus" : "note"
                        size: 16
                        color: row.selected ? Theme.text : Theme.textDim
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: 36; right: parent.right; rightMargin: 34; verticalCenter: parent.verticalCenter }
                        text: row.modelData.kind === "newnote"
                            ? (row.modelData.title !== "" ? "New note “" + row.modelData.title + "”" : "New note")
                            : row.modelData.title
                        color: row.selected ? Theme.text : Theme.textDim
                        elide: Text.ElideRight
                        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                    }
                    PanelIcon {
                        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        visible: row.modelData.kind === "note" && Notes.isPinned(row.modelData.path)
                        name: "pin"
                        size: 14
                        color: Theme.textDim
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: root.index = row.index
                        onClicked: root.activate(row.modelData)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: Notes.loading && root.rows.length === 0
                    text: "Loading…"
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                }
            }
        }

        PreviewNote {
            id: editor
            visible: root.editing !== null
            row: root.editing
            onBack: root.leave()
            onRemove: {
                Notes.trash(root.editing.path)
                root.leave()
            }
        }
    }
}
