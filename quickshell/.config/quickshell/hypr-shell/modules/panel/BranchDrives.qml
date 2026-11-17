import QtQuick
import qs.theme
import qs.services
import qs.components

// Drives: the selected removable disk on top (left click opens it in the file manager, right click in a terminal,
// rename, eject), then four tabs of the same size: Files (quick look inside, photo import from camera cards), Write ISO
// (the image library, raw / Windows / Ventoy writing), Format (whole drive, any filesystem with its tool installed)
// and Tools (speed, real capacity, backup, Ventoy, secure erase). A running job covers the tabs with its progress.
// Behind "Show internal" the internal data partitions. Opens from the Files menu and from the strip icon that shows while a drive is plugged in.
Item {
    id: root

    property bool showAll: false
    property int tab: 0
    readonly property var disk: Drives.selected
    readonly property real bodyH: 300
    readonly property real innerW: width - 2 * Theme.padTile

    implicitWidth: 460
    implicitHeight: col.implicitHeight + 2 * Theme.padTile

    // Without a drive only the library makes sense.
    readonly property int shownTab: !disk ? 1 : tab
    readonly property bool jobShown: Drives.jobStage !== "" && (!disk || Drives.jobDev === disk.dev
        || Drives.drives.every(d => d.dev !== Drives.jobDev))

    // Rescan the ISO folder only while the library is on screen.
    Binding { target: IsoLibrary; property: "wanted"; value: root.shownTab === 1 || root.shownTab === 3 }
    // The mirror list is read (from its 12 h cache) when the library shows, for the "newer release" marks.
    Binding { target: IsoMirror; property: "wanted"; value: root.shownTab === 1 }

    Column {
        id: col
        x: Theme.padTile
        y: Theme.padTile
        width: root.innerW
        spacing: Theme.gapTile

        Item {
            width: parent.width
            height: 28

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                PanelIcon { anchors.verticalCenter: parent.verticalCenter; name: "usb"; size: 16; color: Theme.accent2 }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Drives".toUpperCase()
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy; letterSpacing: 1.3 }
                }
            }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Show internal"
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                }
                Switch { checked: root.showAll; onToggled: v => root.showAll = v }
            }
        }

        // Several sticks plugged in: pick which one the tabs work on.
        Row {
            visible: Drives.drives.length > 1
            width: parent.width
            spacing: Theme.gapTile
            Repeater {
                model: Drives.drives
                ActionButton {
                    required property var modelData
                    width: (col.width - (Drives.drives.length - 1) * Theme.gapTile) / Drives.drives.length
                    icon: "usb"
                    text: Drives.title(modelData)
                    active: root.disk !== null && root.disk.dev === modelData.dev
                    onClicked: Drives.selectedDev = modelData.dev
                }
            }
        }

        DriveHead { width: parent.width; disk: root.disk }

        SegmentedControl {
            width: parent.width
            model: ["Files", "Write ISO", "Format", "Tools"]
            current: root.shownTab
            onPicked: i => root.tab = i
        }

        Tile {
            width: parent.width
            height: root.bodyH
            radius: Theme.radiusLg
            clip: true

            DriveJob {
                anchors { fill: parent; margins: Theme.padTile }
                visible: root.jobShown
                disk: root.disk
            }
            DriveFiles {
                anchors { fill: parent; margins: Theme.padTile }
                visible: root.shownTab === 0 && !root.jobShown
                disk: root.disk
                active: visible
            }
            DriveIso {
                anchors { fill: parent; margins: Theme.padTile }
                visible: root.shownTab === 1 && !root.jobShown
                disk: root.disk
            }
            DriveFormat {
                anchors { fill: parent; margins: Theme.padTile }
                visible: root.shownTab === 2 && !root.jobShown
                disk: root.disk
            }
            DriveTools {
                anchors { fill: parent; margins: Theme.padTile }
                visible: root.shownTab === 3 && !root.jobShown
                disk: root.disk
            }
        }

        Column {
            visible: root.showAll
            width: parent.width
            spacing: Theme.gapTile

            Text {
                visible: Drives.internal.length === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "No internal data partitions"
                color: Theme.textDim
                font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
            }
            Repeater {
                model: Drives.internal
                DrivePartRow { required property var modelData; width: col.width; part: modelData }
            }
        }
    }
}
