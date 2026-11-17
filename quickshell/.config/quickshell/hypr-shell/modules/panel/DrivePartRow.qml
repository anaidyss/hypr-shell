import QtQuick
import qs.theme
import qs.services
import qs.components

// An internal data partition behind "Show internal": left click opens it (mounting first), right click opens a
// terminal there, the button mounts or unmounts. Internal partitions are never renamed or formatted from here.
Tile {
    id: root

    required property var part

    radius: Theme.radiusLg
    height: 56

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) Drives.terminal(root.part.dev, "")
            else Drives.open(root.part.dev, "")
        }
    }

    PanelIcon {
        x: Theme.padTile
        anchors.verticalCenter: parent.verticalCenter
        name: "disk"
        size: 20
        color: root.part.mounted ? Theme.text : Theme.textDim
    }

    Column {
        anchors { left: parent.left; leftMargin: Theme.padTile + 32; right: btn.left; rightMargin: Theme.gapTile
            verticalCenter: parent.verticalCenter }
        spacing: 2
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.part.label !== "" ? root.part.label : root.part.name
            color: Theme.text
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
        }
        Text {
            width: parent.width
            elide: Text.ElideMiddle
            text: [Drives.fsName(root.part.fstype), Drives.size(root.part.size),
                root.part.mounted ? root.part.mountpoint : "not mounted"].join(" · ")
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
    }

    IconButton {
        id: btn
        anchors { right: parent.right; rightMargin: Theme.padTile; verticalCenter: parent.verticalCenter }
        radius: Theme.radiusMd
        icon: root.part.mounted ? "eject" : "play"
        onClicked: root.part.mounted ? Drives.unmount(root.part.dev) : Drives.mount(root.part.dev)
    }
}
