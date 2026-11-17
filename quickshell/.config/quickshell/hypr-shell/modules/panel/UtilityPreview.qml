import QtQuick
import qs.theme
import qs.services
import qs.components

// Right block of the utility branch: the selected row shown large. Each kind of row has its own view.
Block {
    id: root

    property var current

    signal back()
    signal remove()

    readonly property string kind: current ? current.kind : ""

    order: 1
    title: kind === "app" ? "Application" : (kind === "calc" ? "Result" : (kind === "newnote" ? "New note" : (kind === "note" ? "Note" : (kind === "clip" ? "Clipboard" : "Preview"))))
    icon: kind === "app" ? "appWindow" : (kind === "calc" ? "calculator" : (kind === "newnote" ? "plus" : (kind === "note" ? "note" : (kind === "clip" ? "clipboard" : "search"))))

    Text {
        anchors.centerIn: parent
        visible: root.current === null
        text: Omnibox.mode === "clip" ? (Omnibox.clipsLoading ? "Loading …" : (Omnibox.clips.length === 0 ? "Clipboard is empty" : "No matches"))
            : (Omnibox.query.trim() === "" ? "Type to search or calculate" : "No matches")
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
    }

    PreviewApp { row: root.current; visible: root.kind === "app" }
    PreviewCalc { row: root.current; visible: root.kind === "calc" }
    PreviewNewNote { row: root.current; visible: root.kind === "newnote" }
    PreviewNote { row: root.current; visible: root.kind === "note"; onBack: root.back(); onRemove: root.remove() }
    PreviewClip { row: root.current; visible: root.kind === "clip"; onRemove: root.remove() }
}
