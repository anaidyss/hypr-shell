import QtQuick
import Quickshell
import qs.theme

// Application: icon, name and description.
Item {
    id: root

    property var row
    readonly property bool on: row !== null && row !== undefined && row.kind === "app"

    anchors.fill: parent

    Image {
        id: bigIcon
        width: 54
        height: 54
        sourceSize: Qt.size(108, 108)
        smooth: true
        mipmap: true
        visible: status === Image.Ready
        source: root.on ? (root.row.entry.icon.startsWith("/") ? "file://" + root.row.entry.icon : Quickshell.iconPath(root.row.entry.icon, true)) : ""
    }

    Text {
        anchors { left: parent.left; right: parent.right; top: bigIcon.visible ? bigIcon.bottom : parent.top; topMargin: 12 }
        text: root.on ? root.row.entry.name : ""
        color: Theme.text
        elide: Text.ElideRight
        font { family: Theme.fontUi; pixelSize: 18; weight: Theme.wStrong }
    }

    Text {
        anchors { left: parent.left; right: parent.right; bottom: hint.top; bottomMargin: 8 }
        text: root.on ? (root.row.entry.genericName || root.row.entry.comment || "") : ""
        color: Theme.textDim
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
    }

    Text {
        id: hint
        anchors { left: parent.left; bottom: parent.bottom }
        text: "Enter to open"
        color: Theme.textOff
        font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
    }
}
