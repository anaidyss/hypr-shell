import QtQuick
import qs.theme
import qs.services
import qs.components

// The Write ISO tab: the library of images in `drives.isoDir` (pick one, rename it, check its SHA-256), then the
// confirmation before writing it onto the selected drive (the progress is DriveJob, shown by the branch). Linux
// images are written raw; Windows installers are copied as files onto GPT + FAT32 (a raw copy of them does not boot
// from USB); on a Ventoy stick an image is just copied next to the others, nothing is erased.
Item {
    id: root

    property var disk: null
    property string mode: "list"   // list · edit · confirm · store
    property string selFile: ""
    property string editFile: ""

    readonly property var sel: IsoLibrary.items.find(x => x.file === selFile) || null
    readonly property var editing: IsoLibrary.items.find(x => x.file === editFile) || null
    readonly property bool ventoy: disk !== null && disk.ventoy
    readonly property bool fits: sel !== null && disk !== null
        && (ventoy ? disk.total - disk.used >= sel.size : sel.compressed !== "" || sel.size <= disk.size)
    readonly property bool winReady: Drives.hasWinTools && Drives.fsCaps.vfat === true
    readonly property bool canWrite: fits && !Drives.busy && (!sel.windows || ventoy || winReady)

    onDiskChanged: if (mode === "confirm" && !disk) mode = "list"

    // ---- list ----
    Item {
        anchors.fill: parent
        visible: root.mode === "list"

        Item {
            id: head
            width: parent.width
            height: 30
            IsoDownloadBar {
                anchors { left: parent.left; right: headTools.left; rightMargin: Theme.gapTile; verticalCenter: parent.verticalCenter }
                visible: IsoMirror.dlStage !== ""
            }
            Text {
                anchors { left: parent.left; right: headTools.left; rightMargin: Theme.gapTile; verticalCenter: parent.verticalCenter }
                visible: IsoMirror.dlStage === ""
                elide: Text.ElideMiddle
                text: IsoLibrary.shownDir + (IsoLibrary.items.length > 0 ? " · " + IsoLibrary.items.length
                    + (IsoLibrary.items.length === 1 ? " image" : " images") : "")
                color: Theme.textDim
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }
            Row {
                id: headTools
                anchors.right: parent.right
                spacing: 4
                IconButton { icon: "download"; onClicked: root.mode = "store" }
                IconButton { icon: "folder"; enabled: !IsoLibrary.missing; onClicked: IsoLibrary.openDir() }
            }
        }

        ListView {
            id: list
            anchors { top: head.bottom; topMargin: Theme.gapTile; left: parent.left; right: parent.right
                bottom: foot.top; bottomMargin: Theme.gapTile }
            clip: true
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds
            model: IsoLibrary.items
            delegate: IsoRow {
                required property var modelData
                width: list.width
                item: modelData
                selected: modelData.file === root.selFile
                onPicked: root.selFile = modelData.file
                onEdit: { root.editFile = modelData.file; root.mode = "edit" }
            }
        }

        Column {
            anchors.centerIn: list
            width: list.width
            spacing: Theme.padTile
            visible: !IsoLibrary.loaded || IsoLibrary.missing || IsoLibrary.items.length === 0 || IsoLibrary.error !== ""

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: IsoLibrary.error !== "" ? Theme.danger : Theme.textDim
                font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                text: !IsoLibrary.loaded ? "Loading…"
                    : IsoLibrary.error !== "" ? IsoLibrary.error
                    : IsoLibrary.missing ? "No folder " + IsoLibrary.shownDir
                    : "Put .iso files into " + IsoLibrary.shownDir
            }
            ActionButton {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: IsoLibrary.loaded && (IsoLibrary.missing || IsoLibrary.items.length === 0)
                icon: "folder"
                text: IsoLibrary.missing ? "Create folder" : "Open folder"
                onClicked: IsoLibrary.missing ? IsoLibrary.createDir() : IsoLibrary.openDir()
            }
        }

        Item {
            id: foot
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 32

            Text {
                anchors { left: parent.left; right: writeBtn.left; rightMargin: Theme.gapTile; verticalCenter: parent.verticalCenter }
                elide: Text.ElideRight
                color: Theme.textDim
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                text: !root.disk ? "Plug in a drive to write"
                    : !root.sel ? (root.ventoy ? "Ventoy stick: pick images to copy" : "Pick an image")
                    : !root.fits ? (root.ventoy ? "Not enough free space on the stick" : "The image is larger than the drive")
                    : root.sel.windows && !root.ventoy && !root.winReady ? "Windows needs: pacman -S 7zip wimlib dosfstools"
                    : root.sel.name + " → " + Drives.title(root.disk)
            }
            ActionButton {
                id: writeBtn
                anchors.right: parent.right
                icon: root.ventoy ? "copy" : "bolt"
                text: root.ventoy ? "Copy" : "Write"
                primary: enabled
                enabled: root.canWrite
                onClicked: root.ventoy ? Drives.copyToVentoy(root.sel, root.disk.dev) : root.mode = "confirm"
            }
        }
    }

    // ---- images from the mirror ----
    Loader {
        anchors.fill: parent
        active: root.mode === "store"
        sourceComponent: IsoStore { onDone: root.mode = "list" }
    }

    // ---- rename ----
    Loader {
        anchors.fill: parent
        active: root.mode === "edit" && root.editing !== null
        sourceComponent: IsoEdit {
            item: root.editing
            onDone: root.mode = "list"
        }
    }

    // ---- confirm ----
    DriveConfirm {
        anchors.fill: parent
        visible: root.mode === "confirm" && root.sel !== null && root.disk !== null
        logo: root.sel ? root.sel.logo : ""
        logoName: root.sel ? root.sel.name : ""
        heading: root.disk ? "Erase " + Drives.title(root.disk) + "?" : ""
        actionText: "Erase and write"
        actionIcon: "bolt"
        showVerify: root.sel !== null && !root.sel.windows
        detail: {
            if (!root.disk || !root.sel) return ""
            const now = root.disk.parts.filter(p => p.fstype !== "")
                .map(p => (p.label !== "" ? p.label : p.name) + " (" + Drives.fsName(p.fstype) + ", " + Drives.size(p.size) + ")")
            return "Everything on " + root.disk.model + " (" + Drives.size(root.disk.size) + ") is replaced by "
                + root.sel.name + (root.sel.version !== "" ? " " + root.sel.version : "") + "."
                + (now.length > 0 ? " Lost: " + now.join(", ") + "." : "")
                + (root.sel.windows ? " Copied as files onto FAT32 (GPT, UEFI boot)."
                    : !root.sel.hybrid ? " This image has no USB boot record and may not start." : "")
        }
        onCancelled: root.mode = "list"
        onAccepted: { Drives.writeImage(root.sel, root.disk.dev); root.mode = "list" }
    }
}
