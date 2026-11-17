import QtQuick
import qs.theme

// Calculation: the expression and the result as the hero.
Item {
    id: root

    property var row
    readonly property bool on: row !== null && row !== undefined && row.kind === "calc"

    anchors.fill: parent

    Text {
        id: expr
        anchors { left: parent.left; right: parent.right; top: parent.top }
        text: root.on ? root.row.sub : ""
        color: Theme.textDim
        elide: Text.ElideRight
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
    }

    Text {
        anchors { left: parent.left; right: parent.right; top: expr.bottom; topMargin: 12; bottom: hint.top; bottomMargin: 8 }
        text: root.on ? root.row.title : ""
        color: Theme.text
        wrapMode: Text.WrapAnywhere
        elide: Text.ElideRight
        verticalAlignment: Text.AlignTop
        font { family: Theme.fontUi; pixelSize: text.length > 12 ? 26 : 38; weight: Theme.wStrong }
    }

    Text {
        id: hint
        anchors { left: parent.left; bottom: parent.bottom }
        text: "Enter to copy"
        color: Theme.textOff
        font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
    }
}
