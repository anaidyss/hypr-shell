import QtQuick
import qs.theme
import qs.services
import qs.components

// The Tools tab: speed test, real-capacity check (fake sticks), backup to an image, Ventoy and secure erase.
// Everything that erases the drive goes through DriveConfirm first; the job itself shows in DriveJob.
Item {
    id: root

    property var disk: null
    property string confirm: ""   // probe · erase · ventoy

    readonly property bool has: disk !== null
    readonly property bool writableFs: has && disk.main !== "" && disk.fstype !== "iso9660" && disk.fstype !== ""
    readonly property var refill: Drives.refill(disk)

    onDiskChanged: confirm = ""

    Column {
        anchors.fill: parent
        visible: root.confirm === ""
        spacing: 4

        ToolRow {
            icon: "pulse"
            title: "Speed test"
            hint: root.writableFs ? "Writes and reads 256 MB, nothing is erased" : "Needs a writable filesystem on the drive"
            action: "Run"
            ok: root.writableFs
            onRun: Drives.speedTest(root.disk)
        }
        ToolRow {
            icon: "shieldCheck"
            title: "Real capacity"
            hint: "Finds fake sticks · erases the drive"
            action: "Check…"
            ok: root.has
            onRun: root.confirm = "probe"
        }
        ToolRow {
            icon: "save"
            title: "Back up"
            hint: IsoLibrary.missing ? "Create " + IsoLibrary.shownDir + " first" : "Whole drive into " + IsoLibrary.shownDir + " as .img.zst"
            action: "Back up"
            ok: root.has && !IsoLibrary.missing
            onRun: Drives.backup(root.disk)
        }
        ToolRow {
            icon: "layers"
            title: "Ventoy"
            hint: root.has && root.disk.ventoy ? "Installed · update keeps your images"
                : "Many ISOs on one stick · erases the drive"
            action: root.has && root.disk.ventoy ? "Update" : "Install…"
            ok: root.has
            onRun: root.disk.ventoy ? Drives.installVentoy(root.disk.dev, true) : root.confirm = "ventoy"
        }
        ToolRow {
            icon: "eraser"
            title: "Secure erase"
            hint: "Random data over every byte · erases"
            action: "Erase…"
            ok: root.has
            onRun: root.confirm = "erase"
        }
    }

    DriveConfirm {
        anchors.fill: parent
        visible: root.confirm !== "" && root.has
        icon: root.confirm === "probe" ? "shieldCheck" : root.confirm === "ventoy" ? "layers" : "eraser"
        heading: root.has ? "Erase " + Drives.title(root.disk) + "?" : ""
        actionText: root.confirm === "probe" ? "Erase and check" : root.confirm === "ventoy" ? "Install Ventoy" : "Erase"
        actionIcon: root.confirm === "ventoy" ? "layers" : "eraser"
        detail: {
            if (!root.has) return ""
            const lost = root.disk.parts.filter(p => p.fstype !== "")
                .map(p => (p.label !== "" ? p.label : p.name) + " (" + Drives.fsName(p.fstype) + ")")
            const what = lost.length > 0 ? "Everything on " + lost.join(", ") + " will be lost. " : ""
            if (root.confirm === "probe")
                return what + "Test blocks are written across all " + Drives.size(root.disk.size)
                    + " and read back. Afterwards the drive is formatted as " + Drives.fsName(root.refill.fs) + " “" + root.refill.label + "”."
            if (root.confirm === "ventoy")
                return what + "Ventoy is downloaded if needed and installed (GPT). Then copy any images onto the stick and pick one at boot. Asks for your password."
            return what + "Every byte of " + Drives.size(root.disk.size) + " is overwritten with random data, then the drive is formatted as "
                + Drives.fsName(root.refill.fs) + ". Flash keeps a few spare blocks the drive hides, so this is good, not forensic."
        }
        onCancelled: root.confirm = ""
        onAccepted: {
            const r = root.refill
            if (root.confirm === "probe") Drives.probe(root.disk, r.fs, r.label)
            else if (root.confirm === "ventoy") Drives.installVentoy(root.disk.dev, false)
            else Drives.wipe(root.disk, r.fs, r.label)
            root.confirm = ""
        }
    }

    component ToolRow: Item {
        id: row
        property string icon
        property string title
        property string hint
        property string action
        property bool ok: true
        signal run()

        width: parent ? parent.width : 0
        height: 48

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusMd
            color: hover.hovered ? Theme.panelHigh : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }
        HoverHandler { id: hover }

        PanelIcon {
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            name: row.icon
            size: 18
            color: Theme.textDim
        }
        Column {
            anchors { left: parent.left; leftMargin: 36; right: btn.left; rightMargin: Theme.gapTile; verticalCenter: parent.verticalCenter }
            spacing: 2
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: row.title
                color: Theme.text
                font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: row.hint
                color: Theme.textDim
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }
        }
        ActionButton {
            id: btn
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            width: 96
            text: row.action
            enabled: row.ok && !Drives.busy
            onClicked: row.run()
        }
    }
}
