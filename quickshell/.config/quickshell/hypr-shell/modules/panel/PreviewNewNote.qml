import QtQuick
import qs.theme

// New note: Enter creates it.
Item {
    id: root

    property var row

    anchors.fill: parent

    Text {
        id: title
        anchors { left: parent.left; right: parent.right; top: parent.top }
        text: root.row && root.row.title !== "" ? root.row.title : "Untitled"
        color: Theme.text
        elide: Text.ElideRight
        font { family: Theme.fontUi; pixelSize: 18; weight: Theme.wStrong }
    }

    Text {
        anchors { left: parent.left; right: parent.right; top: title.bottom; topMargin: 8 }
        text: root.row && root.row.title !== "" ? "A new note with this title" : "Named by the date"
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
    }

    Text {
        anchors { left: parent.left; bottom: parent.bottom }
        text: "Enter to create"
        color: Theme.textOff
        font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
    }
}
