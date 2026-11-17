import QtQuick
import qs.theme
import qs.services

SettingsPage {
    id: root

    required property string pageId

    title: SettingsSchema.pageTitle(pageId)

    readonly property var sections: {
        const order = []
        const map = {}
        for (const it of SettingsSchema.items) {
            if (it.page !== pageId || it.type === "link") continue
            if (!SettingsSchema.shown(it)) continue
            if (!map[it.section]) { map[it.section] = { title: it.section, items: [] }; order.push(map[it.section]) }
            map[it.section].items.push(it)
        }
        return order
    }

    function tryReveal() {
        const id = SettingsState.pendingId
        if (id === "") return
        for (let i = 0; i < sections.length; i++) {
            if (sections[i].items.some(it => it.id === id)) {
                SettingsState.pendingId = ""
                reveal(i, id)
                return
            }
        }
    }

    function reveal(sectionIndex, id) {
        const sec = repeater.itemAt(sectionIndex)
        if (!sec) return
        const wasOpen = sec.expanded
        sec.expanded = true
        revealTimer.sec = sec
        revealTimer.id = id
        revealTimer.interval = wasOpen ? 30 : 280
        revealTimer.restart()
    }

    Timer {
        id: revealTimer
        property var sec
        property string id
        onTriggered: {
            for (let i = 0; i < sec.rows.count; i++) {
                const row = sec.rows.itemAt(i)
                if (row.item.id !== id) continue
                const y = row.mapToItem(root.contentItem, 0, 0).y
                scrollAnim.to = Math.max(0, Math.min(root.contentHeight - root.height, y - root.height / 2 + row.height / 2))
                scrollAnim.restart()
                row.highlight()
                return
            }
        }
    }

    NumberAnimation { id: scrollAnim; target: root; property: "contentY"; duration: 320; easing.type: Easing.OutCubic }

    Connections {
        target: SettingsState
        function onPendingIdChanged() { root.tryReveal() }
    }

    Component.onCompleted: Qt.callLater(tryReveal)

    Repeater {
        id: repeater
        model: root.sections

        delegate: SettingsSection {
            required property var modelData
            property alias rows: rowRepeater

            title: modelData.title
            expanded: SettingsSchema.collapsedSections.indexOf(modelData.title) < 0

            Repeater {
                id: rowRepeater
                model: modelData.items
                delegate: SettingsRow {
                    required property var modelData
                    item: modelData
                }
            }
        }
    }
}
