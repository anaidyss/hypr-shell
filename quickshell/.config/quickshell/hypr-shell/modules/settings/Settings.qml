import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.components

FloatingWindow {
    id: win

    readonly property var pages: SettingsSchema.pages
    readonly property var currentPage: {
        for (const p of pages) if (p.id === SettingsState.page) return p
        return pages[0]
    }

    title: "Settings"
    color: "transparent"
    implicitWidth: 980
    implicitHeight: 660
    minimumSize: Qt.size(760, 520)
    visible: false

    onVisibleChanged: SettingsState.open = visible

    // Development snapshot: the whole current page (not just the visible part) as a PNG.
    Connections {
        target: SettingsState
        function onSnapshotRequested(path, pageId) {
            if (pageId !== "") SettingsState.show(pageId)
            snapTimer.path = path
            snapTimer.restart()
        }
    }

    Timer {
        id: snapTimer
        property string path
        interval: 900
        onTriggered: {
            const page = pageLoader.item
            if (page && page.body) page.body.grabToImage(r => r.saveToFile(path))
        }
    }

    Connections {
        target: SettingsState
        function onOpenChanged() { win.visible = SettingsState.open }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface

        FocusScope {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: SettingsState.open = false
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Slash || (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier))) {
                    search.focusField()
                    event.accepted = true
                }
            }

            Column {
                id: sidebar
                x: 14
                y: 20
                width: 204
                spacing: 4

                Text {
                    leftPadding: 12
                    bottomPadding: 14
                    text: "Settings"
                    color: Theme.text
                    font { family: Theme.fontUi; pixelSize: 18; weight: Theme.wStrong }
                }

                SettingsSearch {
                    id: search
                    width: parent.width
                    onPicked: item => {
                        clear()
                        SettingsState.go(item.page, item.id)
                    }
                }

                Item { width: 1; height: 8 }

                Repeater {
                    model: win.pages

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool current: SettingsState.page === modelData.id

                        width: sidebar.width
                        height: 38
                        radius: Theme.radiusSm
                        color: current ? Qt.alpha(Theme.accent, 0.16) : (hover.hovered ? Qt.alpha(Theme.text, 0.06) : "transparent")
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }

                        Text {
                            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                            text: modelData.title
                            color: parent.current ? Theme.accent : Theme.text
                            font { family: Theme.fontUi; pixelSize: 14; weight: parent.current ? Theme.wStrong : Theme.wBold }
                        }

                        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: SettingsState.page = modelData.id }
                    }
                }
            }

            Rectangle {
                anchors { left: sidebar.right; leftMargin: 14; top: parent.top; bottom: parent.bottom; topMargin: 14; bottomMargin: 14 }
                width: 1
                color: Theme.border
            }

            Item {
                id: content
                anchors { left: sidebar.right; leftMargin: 15; right: parent.right; top: parent.top; bottom: parent.bottom }

                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    visible: search.query === ""
                    sourceComponent: win.currentPage.schema ? schemaPage : null
                    source: win.currentPage.schema ? "" : win.currentPage.source

                    onItemChanged: introAnim.restart()

                    ParallelAnimation {
                        id: introAnim
                        NumberAnimation { target: pageLoader; property: "opacity"; from: 0; to: 1; duration: Theme.durNormal; easing.type: Theme.easingCalm }
                        NumberAnimation { target: pageLoader; property: "y"; from: 8; to: 0; duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot }
                    }
                }

                Component {
                    id: schemaPage
                    SchemaPage { pageId: SettingsState.page }
                }

                Column {
                    anchors { fill: parent; margins: 32; topMargin: 28 }
                    visible: search.query !== ""
                    spacing: 6

                    Text {
                        text: search.results.length > 0 ? "Results" : "Nothing found"
                        bottomPadding: 10
                        color: Theme.text
                        font { family: Theme.fontUi; pixelSize: 26; weight: Theme.wStrong }
                    }

                    Repeater {
                        model: search.results

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: parent.width
                            height: 52
                            radius: Theme.radiusMd
                            color: index === search.current ? Qt.alpha(Theme.accent, 0.16) : (rowHover.hovered ? Qt.alpha(Theme.text, 0.06) : "transparent")
                            Behavior on color { ColorAnimation { duration: Theme.durFast } }

                            Column {
                                anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                                spacing: 2
                                Text {
                                    text: modelData.title
                                    color: Theme.text
                                    font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                                }
                                Text {
                                    text: SettingsSchema.pageTitle(modelData.page) + (modelData.type === "link" ? "" : "  ›  " + modelData.section)
                                    color: Theme.textDim
                                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                                }
                            }

                            HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    search.clear()
                                    SettingsState.go(modelData.page, modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
