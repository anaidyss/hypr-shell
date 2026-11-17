import QtQuick
import qs.theme
import qs.services
import qs.components

// The selected removable disk: name, model, size, filesystem and free space. Left click anywhere opens it in the
// file manager, right click in a terminal (both mount it first). A stick with a written ISO shows the distribution
// logo. Rename edits the label of its main partition in place.
Tile {
    id: root

    property var disk: null
    property bool renaming: false

    readonly property bool has: disk !== null
    readonly property real ratio: has && disk.mounted && disk.total > 0 ? Math.min(1, disk.used / disk.total) : 0
    readonly property bool busy: has && ((Drives.jobRunning && Drives.jobDev === disk.dev) || Drives.formatDev === disk.dev)
    readonly property string bootDistro: has && disk.iso ? IsoLibrary.detect(disk.label, "") : ""
    readonly property var bootInfo: bootDistro !== "" ? IsoLibrary.distro(bootDistro) : null

    radius: Theme.radiusLg
    height: 76
    onDiskChanged: if (!has) renaming = false

    MouseArea {
        anchors.fill: parent
        enabled: root.has && !root.renaming && !root.busy
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) Drives.terminal(root.disk.dev, "")
            else Drives.open(root.disk.dev, "")
        }
    }

    Rectangle {
        id: badge
        x: Theme.padTile
        anchors.verticalCenter: parent.verticalCenter
        width: 52
        height: 52
        radius: Theme.radiusMd
        color: Theme.panelPill

        PanelIcon {
            anchors.centerIn: parent
            visible: root.bootInfo === null
            name: "usb"
            size: 24
            color: root.has ? Theme.accent : Theme.textDim
        }
        DistroLogo {
            anchors.centerIn: parent
            visible: root.bootInfo !== null
            path: root.bootInfo ? root.bootInfo.path : ""
            name: root.bootInfo ? root.bootInfo.name : ""
            size: 26
            color: Theme.accent
        }
    }

    Column {
        visible: !root.renaming
        anchors { left: badge.right; leftMargin: Theme.padTile; right: actions.left; rightMargin: Theme.gapTile
            verticalCenter: parent.verticalCenter }
        spacing: 4

        Row {
            width: parent.width
            spacing: 8
            Text {
                id: titleText
                width: Math.min(implicitWidth, parent.width - (modelText.visible ? Math.min(modelText.implicitWidth, parent.width / 2) + 8 : 0))
                text: root.has ? Drives.title(root.disk) : "No drive"
                elide: Text.ElideRight
                color: root.has ? Theme.text : Theme.textDim
                font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
            }
            Text {
                id: modelText
                anchors.baseline: titleText.baseline
                width: Math.min(implicitWidth, parent.width - titleText.width - 8)
                visible: root.has && root.disk.label !== ""
                text: root.has ? root.disk.model : ""
                elide: Text.ElideRight
                color: Theme.textDim
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }
        }
        Text {
            width: parent.width
            elide: Text.ElideRight
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            text: {
                if (!root.has) return "Plug in a USB stick or a card"
                if (root.busy) return Drives.formatDev === root.disk.dev ? "Formatting…" : Drives.jobTitle + " · " + Drives.jobLabel
                const bits = []
                if (root.disk.ventoy) bits.push("Ventoy")
                else if (root.bootInfo) bits.push("Boot drive")
                else if (root.disk.fstype !== "") bits.push(Drives.fsName(root.disk.fstype))
                else bits.push("No filesystem")
                if (root.disk.mounted && root.disk.total > 0)
                    bits.push(Drives.size(root.disk.total - root.disk.used) + " free of " + Drives.size(root.disk.size))
                else
                    bits.push(Drives.size(root.disk.size) + (root.disk.main !== "" && !root.disk.mounted ? " · not mounted" : ""))
                return bits.join(" · ")
            }
        }
        Item {
            width: parent.width
            height: 8
            visible: root.has && root.disk.mounted && root.disk.total > 0

            Rectangle {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                height: 4
                radius: 2
                color: Theme.panelTrack
            }
            Rectangle {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                width: parent.width * root.ratio
                height: 4
                radius: 2
                color: root.ratio > 0.9 ? Theme.danger : Theme.accent
                Behavior on width { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
            }
        }
    }

    FieldInput {
        id: nameField
        visible: root.renaming
        anchors { left: badge.right; leftMargin: Theme.padTile; right: actions.left; rightMargin: Theme.gapTile
            verticalCenter: parent.verticalCenter }
        radius: Theme.radiusMd
        placeholder: "Drive name"
        maximumLength: ({ vfat: 11, exfat: 15, xfs: 12, ext4: 16 })[root.has ? root.disk.fstype : ""] || 32
        onAccepted: root.commitRename()
        onEscaped: root.renaming = false
    }

    function startRename() {
        nameField.text = disk.label
        renaming = true
        nameField.focusField()
    }
    function commitRename() {
        nameField.release()
        if (nameField.text !== disk.label) Drives.rename(disk.dev, nameField.text)
        renaming = false
    }

    Row {
        id: actions
        anchors { right: parent.right; rightMargin: Theme.padTile; verticalCenter: parent.verticalCenter }
        spacing: 4
        visible: root.has

        IconButton {
            visible: root.renaming
            icon: "check"
            radius: Theme.radiusMd
            onClicked: root.commitRename()
        }
        IconButton {
            visible: root.renaming
            icon: "close"
            radius: Theme.radiusMd
            onClicked: { nameField.release(); root.renaming = false }
        }
        IconButton {
            visible: !root.renaming
            icon: "pen"
            radius: Theme.radiusMd
            enabled: !root.busy && root.has && root.disk.main !== "" && root.disk.fstype !== "iso9660"
            onClicked: root.startRename()
        }
        IconButton {
            visible: !root.renaming
            icon: "terminal"
            radius: Theme.radiusMd
            enabled: !root.busy && root.has && root.disk.main !== ""
            onClicked: Drives.terminal(root.disk.dev, "")
        }
        IconButton {
            visible: !root.renaming
            icon: "eject"
            radius: Theme.radiusMd
            enabled: !root.busy
            onClicked: Drives.eject(root.disk.dev)
        }
    }
}
