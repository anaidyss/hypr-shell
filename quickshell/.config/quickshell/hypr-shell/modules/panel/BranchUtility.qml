import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components

// Utility branch that grows up from the bottom frame band. Same layout as the dashboard on top: a tab strip
// (Search, Clipboard, Notes) and two blocks, the list with the input on the left and the selected row on the right.
Item {
    id: root

    readonly property real pad: 12
    readonly property real tabsH: 40
    readonly property real areaH: 304
    readonly property var modes: ["main", "clip", "note"]
    readonly property var rows: Omnibox.results
    readonly property var current: rows.length > 0 ? rows[Math.min(index, rows.length - 1)] : null
    property int index: 0
    // Index to return to after the list changes under the selection (a deleted entry), -1 for the top.
    property int keep: -1
    // True while the selection moves by keyboard: the list then scrolls to it.
    property bool keyNav: false

    readonly property real maxW: Window.window ? Window.window.width - 160 : 800

    implicitWidth: Math.min(800, maxW)
    implicitHeight: pad / 2 + tabsH + 8 + areaH + pad

    onRowsChanged: {
        index = keep >= 0 ? Math.max(0, Math.min(keep, rows.length - 1)) : 0
        keep = -1
        applySelect()
    }
    onCurrentChanged: Omnibox.loadPreview(current)

    function applySelect() {
        if (Omnibox.selectKey === "") return
        const i = rows.findIndex(r => r.key === Omnibox.selectKey)
        if (i < 0) return
        keyNav = true
        index = i
        Omnibox.selectKey = ""
    }

    function move(delta) {
        if (rows.length === 0) return
        keyNav = true
        index = (index + delta + rows.length) % rows.length
    }

    function removeCurrent() {
        if (!current) return
        if (current.kind === "clip") {
            keep = index
            Omnibox.removeClip(current.id)
        } else if (current.kind === "note") {
            keep = index
            Notes.trash(current.path)
        }
    }

    Component.onCompleted: if (PanelState.typing) list.focusInput()

    Connections {
        target: PanelState
        function onTypingChanged() { if (PanelState.typing) list.focusInput() }
    }

    Connections {
        target: Omnibox
        function onSelectKeyChanged() { root.applySelect() }
    }

    DashTabs {
        x: root.pad
        y: root.pad / 2
        width: parent.width - 2 * root.pad
        height: root.tabsH
        current: root.modes.indexOf(Omnibox.mode)
        model: [
            { label: "Search", icon: "search" },
            { label: "Clipboard", icon: "clipboard" },
            { label: "Notes", icon: "note" }
        ]
        onPicked: i => Omnibox.setMode(root.modes[i])
    }

    RowLayout {
        x: root.pad
        y: root.pad / 2 + root.tabsH + 8
        width: parent.width - 2 * root.pad
        height: root.areaH
        spacing: Theme.gapBlock

        UtilityList {
            id: list
            ctl: root
            Layout.fillWidth: true
            Layout.preferredWidth: 380
            Layout.fillHeight: true
        }

        UtilityPreview {
            current: root.current
            Layout.fillWidth: true
            Layout.preferredWidth: 382
            Layout.fillHeight: true
            onBack: list.focusInput()
            onRemove: root.removeCurrent()
        }
    }
}
