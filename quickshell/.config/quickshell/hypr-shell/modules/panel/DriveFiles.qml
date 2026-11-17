import QtQuick
import Quickshell.Io
import qs.theme
import qs.services
import qs.components

// Quick look inside the selected drive (mounted on demand). Folders open in place; a file opens in its app.
// Right click: on a folder a terminal there, on a file a terminal in the current folder.
Item {
    id: root

    property var disk: null
    property bool active: false
    property string sub: ""
    property var listing: null
    property string error: ""

    readonly property string dev: disk ? disk.dev : ""
    readonly property var crumbs: sub === "" || sub === "." ? [] : sub.split("/")

    function load() {
        if (!active || dev === "") return
        error = ""
        lsProc.command = ["hs-drives", "ls", dev, sub]
        lsProc.running = true
    }
    function go(path) { sub = path; listing = null; load() }
    function up() { go(crumbs.slice(0, -1).join("/")) }
    function join(name) { return sub === "" || sub === "." ? name : sub + "/" + name }

    onActiveChanged: if (active) load()
    onDevChanged: { sub = ""; listing = null; load() }
    // The mount state changes under us (mounted by this tab, or unmounted elsewhere): reload once it settles.
    readonly property bool mountedNow: disk ? disk.mounted : false
    onMountedNowChanged: if (active && !lsProc.running) load()

    Process {
        id: lsProc
        stdout: StdioCollector {
            onStreamFinished: {
                let r = { ok: false, msg: "Cannot read the drive" }
                try { r = JSON.parse(text) } catch (e) {}
                if (r.ok) { root.listing = r; root.error = "" }
                else { root.listing = null; root.error = r.msg || "Cannot read the drive" }
            }
        }
    }

    function iconFor(e) {
        if (e.dir) return "folder"
        const ext = (e.name.split(".").pop() || "").toLowerCase()
        if (["png", "jpg", "jpeg", "webp", "gif", "svg", "heic", "avif", "bmp"].indexOf(ext) >= 0) return "image"
        if (["mp3", "flac", "ogg", "opus", "wav", "m4a", "aac"].indexOf(ext) >= 0) return "music"
        if (["mp4", "mkv", "webm", "mov", "avi"].indexOf(ext) >= 0) return "play"
        if (["iso", "img"].indexOf(ext) >= 0) return "disk"
        if (["zip", "tar", "gz", "xz", "zst", "7z", "rar", "bz2"].indexOf(ext) >= 0) return "box"
        return "note"
    }
    readonly property var months: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    function day(ts) {
        const d = new Date(ts * 1000)
        const now = new Date()
        return d.getDate() + " " + months[d.getMonth()] + (d.getFullYear() !== now.getFullYear() ? " " + d.getFullYear() : "")
    }

    // ---- path bar ----
    Item {
        id: bar
        width: parent.width
        height: 30

        IconButton {
            id: back
            icon: "chevronLeft"
            enabled: root.crumbs.length > 0
            onClicked: root.up()
        }
        Text {
            anchors { left: back.right; leftMargin: Theme.gapTile; right: tools.left; rightMargin: Theme.gapTile
                verticalCenter: parent.verticalCenter }
            elide: Text.ElideMiddle
            text: (root.disk ? Drives.title(root.disk) : "") + (root.crumbs.length > 0 ? " / " + root.crumbs.join(" / ") : "")
            color: Theme.text
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
        }
        Row {
            id: tools
            anchors.right: parent.right
            spacing: 4
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.listing !== null
                rightPadding: 4
                text: root.listing ? root.listing.count + (root.listing.count === 1 ? " item" : " items") : ""
                color: Theme.textDim
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }
            IconButton { icon: "folder"; enabled: root.listing !== null; onClicked: Drives.open(root.dev, root.sub) }
            IconButton { icon: "terminal"; enabled: root.listing !== null; onClicked: Drives.terminal(root.dev, root.sub) }
        }
    }

    // ---- camera card ----
    readonly property bool camera: disk !== null && disk.camera && crumbs.length === 0
    Rectangle {
        id: cam
        anchors { left: parent.left; right: parent.right; top: bar.bottom; topMargin: Theme.gapTile }
        visible: root.camera
        height: visible ? 44 : 0
        radius: Theme.radiusMd
        color: Theme.panelPill

        PanelIcon {
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            name: "image"
            size: 18
            color: Theme.accent
        }
        Text {
            anchors { left: parent.left; leftMargin: 36; right: importBtn.left; rightMargin: Theme.gapTile
                verticalCenter: parent.verticalCenter }
            elide: Text.ElideRight
            text: "Camera card · import new photos"
            color: Theme.text
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
        ActionButton {
            id: importBtn
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            height: 30
            icon: "image"
            text: "Import"
            enabled: !Drives.busy
            onClicked: Drives.importPhotos(root.disk)
        }
    }

    // ---- list ----
    ListView {
        id: list
        anchors { left: parent.left; right: parent.right; top: root.camera ? cam.bottom : bar.bottom; topMargin: Theme.gapTile
            bottom: parent.bottom }
        clip: true
        spacing: 4
        boundsBehavior: Flickable.StopAtBounds
        model: root.listing ? root.listing.entries : []

        delegate: Item {
            id: row
            required property var modelData
            width: list.width
            height: 36

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusMd
                color: area.containsMouse ? Theme.panelHigh : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
            }
            PanelIcon {
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                name: root.iconFor(row.modelData)
                size: 18
                color: row.modelData.dir ? Theme.accent : Theme.textDim
            }
            Text {
                anchors { left: parent.left; leftMargin: 36; right: meta.left; rightMargin: Theme.gapTile
                    verticalCenter: parent.verticalCenter }
                elide: Text.ElideMiddle
                text: row.modelData.name
                color: row.modelData.hidden ? Theme.textDim : Theme.text
                font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
            }
            Text {
                id: meta
                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                text: (row.modelData.dir ? "" : Drives.size(row.modelData.size) + " · ") + root.day(row.modelData.mtime)
                color: Theme.textDim
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    const path = root.join(row.modelData.name)
                    if (mouse.button === Qt.RightButton) Drives.terminal(root.dev, row.modelData.dir ? path : root.sub)
                    else if (row.modelData.dir) root.go(path)
                    else Drives.open(root.dev, path)
                }
            }
        }
    }

    // ---- states ----
    Text {
        anchors.centerIn: list
        width: list.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        visible: text !== ""
        text: !root.disk ? "No drive"
            : root.error !== "" ? root.error
            : root.listing === null ? (root.disk.mounted ? "Loading…" : "Mounting…")
            : root.listing.count === 0 ? "Empty folder" : ""
        color: root.error !== "" ? Theme.danger : Theme.textDim
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
    }
}
