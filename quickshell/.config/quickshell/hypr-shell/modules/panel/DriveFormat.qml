import QtQuick
import qs.theme
import qs.services
import qs.components

// Format the whole selected drive: a new partition table with one partition. Filesystems whose mkfs tool is not
// installed are dimmed with the package to install. Erasing always goes through a confirmation that names what is lost.
Item {
    id: root

    property var disk: null
    property string fs: Drives.fsCaps.exfat ? "exfat" : "ext4"
    property int table: 0    // 0 MBR · 1 GPT
    property int erase: 0    // 0 quick · 1 zero fill
    property bool confirming: false

    readonly property var choices: [
        { fs: "exfat", hint: "Any system", pkg: "exfatprogs" },
        { fs: "vfat", hint: "Old devices", pkg: "dosfstools" },
        { fs: "ntfs", hint: "Windows", pkg: "ntfs-3g" },
        { fs: "ext4", hint: "Linux", pkg: "e2fsprogs" },
        { fs: "btrfs", hint: "Snapshots", pkg: "btrfs-progs" },
        { fs: "f2fs", hint: "Flash-friendly", pkg: "f2fs-tools" },
        { fs: "xfs", hint: "Large files", pkg: "xfsprogs" },
        { fs: "udf", hint: "Discs, TVs", pkg: "udftools" }
    ]
    readonly property var missing: choices.filter(c => Drives.fsCaps[c.fs] === false).map(c => c.pkg)
    readonly property bool busy: Drives.formatting && disk !== null && Drives.formatDev === disk.dev
    readonly property int labelMax: ({ vfat: 11, exfat: 15, xfs: 12, ext4: 16 })[fs] || 32

    onDiskChanged: {
        confirming = false
        labelField.text = disk && disk.label !== "" && disk.fstype !== "iso9660" ? disk.label : "USB"
    }
    onVisibleChanged: if (visible) Drives.refreshCaps()

    // ---- options ----
    Item {
        anchors.fill: parent
        visible: !root.confirming && !root.busy

        Grid {
            id: grid
            width: parent.width
            columns: 4
            spacing: Theme.gapTile

            Repeater {
                model: root.choices
                Item {
                    id: chip
                    required property var modelData
                    readonly property bool ok: Drives.fsCaps[modelData.fs] === true
                    readonly property bool on: root.fs === modelData.fs
                    width: (grid.width - 3 * Theme.gapTile) / 4
                    height: 48
                    opacity: ok ? 1 : Theme.disabledOpacity

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusMd
                        color: chip.on ? Theme.accentContainer : chipArea.containsMouse && chip.ok ? Theme.panelHigh : Theme.panelPill
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    }
                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 8
                        spacing: 2
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: Drives.fsName(chip.modelData.fs)
                            color: chip.on ? Theme.text : Theme.text
                            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
                        }
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: chip.ok ? chip.modelData.hint : "Not installed"
                            color: Theme.textDim
                            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
                        }
                    }
                    MouseArea {
                        id: chipArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: chip.ok
                        cursorShape: chip.ok ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.fs = chip.modelData.fs
                    }
                }
            }
        }

        FieldInput {
            id: labelField
            anchors { top: grid.bottom; topMargin: Theme.padTile; left: parent.left; right: parent.right }
            radius: Theme.radiusMd
            placeholder: "Drive name"
            maximumLength: root.labelMax
            onAccepted: release()
        }

        Row {
            id: opts
            anchors { top: labelField.bottom; topMargin: Theme.gapTile; left: parent.left; right: parent.right }
            spacing: Theme.gapTile
            SegmentedControl {
                width: (opts.width - Theme.gapTile) / 2
                model: ["MBR", "GPT"]
                current: root.table
                onPicked: i => root.table = i
            }
            SegmentedControl {
                width: (opts.width - Theme.gapTile) / 2
                model: ["Quick", "Zero fill"]
                current: root.erase
                onPicked: i => root.erase = i
            }
        }

        Item {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 32
            Text {
                anchors { left: parent.left; right: fmtBtn.left; rightMargin: Theme.gapTile; verticalCenter: parent.verticalCenter }
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Theme.textDim
                font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
                text: root.missing.length > 0 ? "More filesystems: pacman -S " + root.missing.join(" ")
                    : root.erase === 1 ? "Zero fill overwrites every byte and takes a while" : ""
            }
            ActionButton {
                id: fmtBtn
                anchors.right: parent.right
                text: "Format…"
                icon: "eraser"
                danger: true
                enabled: root.disk !== null && Drives.fsCaps[root.fs] === true && !Drives.writing && !Drives.formatting
                onClicked: { labelField.release(); root.confirming = true }
            }
        }
    }

    // ---- confirmation ----
    Column {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        visible: root.confirming && !root.busy
        spacing: Theme.gapTile

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.disk ? "Erase " + Drives.title(root.disk) + "?" : ""
            color: Theme.danger
            font { family: Theme.fontUi; pixelSize: 18; weight: Theme.wHeavy }
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            text: {
                if (!root.disk) return ""
                const lost = root.disk.parts.filter(p => p.fstype !== "")
                    .map(p => (p.label !== "" ? p.label : p.name) + " (" + Drives.fsName(p.fstype) + ", "
                        + (p.used ? Drives.size(p.used) + " used" : Drives.size(p.size)) + ")")
                return root.disk.model + " (" + Drives.size(root.disk.size) + ") becomes one " + Drives.fsName(root.fs)
                    + " partition “" + labelField.text + "” on " + (root.table === 0 ? "MBR" : "GPT") + "."
                    + (lost.length > 0 ? " Everything on " + lost.join(", ") + " will be lost." : " Everything on it will be lost.")
            }
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.gapTile
            ActionButton { text: "Cancel"; onClicked: root.confirming = false }
            ActionButton {
                text: "Erase"
                icon: "eraser"
                danger: true
                onClicked: {
                    Drives.format(root.disk.dev, root.fs, labelField.text, root.table === 0 ? "dos" : "gpt",
                        root.erase === 1 ? "zero" : "quick")
                    root.confirming = false
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.busy
        text: root.erase === 1 ? "Erasing and formatting…" : "Formatting…"
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
    }
}
