import QtQuick
import QtQuick.Effects
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.theme
import qs.components

SettingsPage {
    id: root

    readonly property string dir: Quickshell.env("HS_WALLPAPER_DIR") || (Theme.configDir + "/wallpapers")
    readonly property string tool: Quickshell.env("HOME") + "/.local/bin/hs-wallpaper"
    readonly property string wallset: Quickshell.env("HOME") + "/.local/bin/hs-wallset"
    readonly property string ws: Quickshell.env("HOME") + "/.local/bin/hs-wallsearch"
    property string current: ""
    property string session: ""
    readonly property string searchThumbs: Theme.stateDir + "/wallsearch/search_thumbs"
    readonly property string sessionDir: searchThumbs + "/" + session

    title: "Wallpapers"

    function runSearch(query) {
        if (query === "") return
        Quickshell.execDetached([root.ws, "search", query])
    }

    FileView {
        path: Theme.stateDir + "/wallpaper"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.current = text().trim()
    }

    FileView {
        path: Theme.stateDir + "/wallsearch/current_search_session"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.session = text().trim()
    }

    FolderListModel {
        id: folder
        folder: "file://" + root.dir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    FolderListModel {
        id: results
        folder: "file://" + root.sessionDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    Row {
        spacing: 8
        SettingsButton { text: "Next"; onClicked: Quickshell.execDetached([root.tool, "next"]) }
        SettingsButton { text: "Random"; onClicked: Quickshell.execDetached([root.tool, "random"]) }
    }

    Text {
        visible: folder.count === 0
        text: "No images in " + root.dir
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
    }

    Flow {
        id: grid

        readonly property int columns: Math.max(2, Math.floor(width / 220))
        readonly property real cellW: (width - (columns - 1) * spacing) / columns

        width: parent.width
        spacing: 12

        Repeater {
            model: folder

            delegate: Item {
                id: cell

                required property string filePath
                required property url fileUrl
                required property string fileName
                readonly property bool selected: root.current.split("/").pop() === fileName

                width: grid.cellW
                height: width * 0.62

                Image {
                    id: img
                    anchors.fill: parent
                    source: cell.fileUrl
                    asynchronous: true
                    sourceSize.width: 480
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                }

                Item {
                    id: mask
                    anchors.fill: parent
                    layer.enabled: true
                    visible: false
                    Rectangle { anchors.fill: parent; radius: Theme.rounding }
                }

                MultiEffect {
                    anchors.fill: parent
                    source: img
                    maskEnabled: true
                    maskSource: mask
                    opacity: img.status === Image.Ready ? 1 : 0
                    scale: area.containsMouse ? 1.02 : 1
                    Behavior on opacity { NumberAnimation { duration: Theme.durNormal } }
                    Behavior on scale { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.rounding
                    color: "transparent"
                    border.width: cell.selected ? 2 : 1
                    border.color: cell.selected ? Theme.accent : Theme.border
                }

                WallpaperDragArea {
                    id: area
                    anchors.fill: parent
                    source: cell
                    dropArgs: ["file", cell.filePath]
                    onClicked: Quickshell.execDetached([root.wallset, cell.filePath])
                }
            }
        }
    }

    Text {
        text: "Online search"
        color: Theme.text
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
    }

    Flow {
        width: parent.width
        spacing: 8

        Rectangle {
            width: 240
            height: 34
            radius: Theme.radiusSm
            color: Theme.tile
            border.width: 1
            border.color: input.activeFocus ? Qt.alpha(Theme.accent, 0.6) : Theme.border

            TextInput {
                id: input
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                selectionColor: Theme.accent
                selectedTextColor: Theme.accentText
                clip: true
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                onEditingFinished: root.runSearch(text.trim())

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text === "" && !input.activeFocus
                    text: "Search DuckDuckGo…"
                    color: Theme.textDim
                    font: input.font
                }
            }
        }

        SettingsButton { text: "Search"; primary: true; onClicked: root.runSearch(input.text.trim()) }
        SettingsButton { text: "Pause"; onClicked: Quickshell.execDetached([root.ws, "pause"]) }
        SettingsButton { text: "Resume"; onClicked: Quickshell.execDetached([root.ws, "resume"]) }
        SettingsButton { text: "Stop"; onClicked: Quickshell.execDetached([root.ws, "stop"]) }
    }

    Text {
        visible: root.session === ""
        text: "Enter a query to search for wallpapers online. Applied images are saved to the wallpapers folder."
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
        wrapMode: Text.WordWrap
        width: parent.width
    }

    Flow {
        id: resultGrid
        visible: root.session !== "" && results.count > 0

        readonly property int columns: Math.max(2, Math.floor(width / 220))
        readonly property real cellW: (width - (columns - 1) * spacing) / columns

        width: parent.width
        spacing: 12

        Repeater {
            model: results

            delegate: Item {
                id: rcell

                required property url fileUrl
                required property string fileName

                width: resultGrid.cellW
                height: width * 0.62

                Image {
                    id: rimg
                    anchors.fill: parent
                    source: rcell.fileUrl
                    asynchronous: true
                    sourceSize.width: 480
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                }

                Item {
                    id: rmask
                    anchors.fill: parent
                    layer.enabled: true
                    visible: false
                    Rectangle { anchors.fill: parent; radius: Theme.rounding }
                }

                MultiEffect {
                    anchors.fill: parent
                    source: rimg
                    maskEnabled: true
                    maskSource: rmask
                    opacity: rimg.status === Image.Ready ? 1 : 0
                    scale: rarea.containsMouse ? 1.02 : 1
                    Behavior on opacity { NumberAnimation { duration: Theme.durNormal } }
                    Behavior on scale { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.rounding
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.border
                }

                WallpaperDragArea {
                    id: rarea
                    anchors.fill: parent
                    source: rcell
                    dropArgs: ["search", rcell.fileName]
                    onClicked: Quickshell.execDetached([root.ws, "apply", rcell.fileName])
                }
            }
        }
    }
}