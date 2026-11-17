import QtQuick
import qs.theme
import qs.services
import qs.components

// Clipboard entry: text, image or color, with remove and clear.
Item {
    id: root

    property var row

    signal remove()

    readonly property bool on: row !== null && row !== undefined && row.kind === "clip"
    readonly property string ctype: on ? row.ctype : ""
    readonly property bool fresh: on && Omnibox.previewId === row.id
    property bool confirmClear: false

    anchors.fill: parent

    onVisibleChanged: confirmClear = false

    Timer { id: confirmTimer; interval: 3000; onTriggered: root.confirmClear = false }

    Text {
        id: meta
        anchors { left: parent.left; right: parent.right; top: parent.top }
        text: root.ctype === "image" ? root.row.meta
            : (root.ctype === "color" ? "Color"
            : (root.fresh && Omnibox.previewText !== "" ? (Omnibox.previewText.length >= 4000 ? "4000+" : Omnibox.previewText.length) + " characters" : "Text"))
        color: Theme.textDim
        elide: Text.ElideRight
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
    }

    Item {
        anchors { left: parent.left; right: parent.right; top: meta.bottom; topMargin: 8; bottom: bar.top; bottomMargin: 8 }
        clip: true

        Text {
            anchors.fill: parent
            visible: root.ctype === "text"
            text: root.fresh ? Omnibox.previewText : (root.on ? root.row.title : "")
            color: Theme.text
            wrapMode: Text.WrapAnywhere
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }

        Image {
            anchors.fill: parent
            visible: root.ctype === "image"
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignLeft
            verticalAlignment: Image.AlignTop
            smooth: true
            mipmap: true
            source: root.ctype === "image" && root.fresh && Omnibox.previewImage !== "" ? "file://" + Omnibox.previewImage : ""
        }

        Column {
            visible: root.ctype === "color"
            spacing: 12

            Rectangle {
                width: 96
                height: 32
                radius: Theme.radiusSm
                color: root.on && root.row.color ? root.row.color : "transparent"
                border { width: 1; color: Theme.border }
            }
            Text {
                text: root.on ? root.row.title : ""
                color: Theme.text
                font { family: Theme.fontUi; pixelSize: 26; weight: Theme.wStrong }
            }
        }
    }

    Item {
        id: bar
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 28

        Text {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: "Enter to copy"
            color: Theme.textOff
            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 4

            Item {
                width: clearLabel.width + 16
                height: 28

                Text {
                    id: clearLabel
                    anchors.centerIn: parent
                    text: root.confirmClear ? "Delete all?" : "Clear all"
                    color: root.confirmClear ? Theme.danger : Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.confirmClear) {
                            root.confirmClear = false
                            Omnibox.clearClips()
                        } else {
                            root.confirmClear = true
                            confirmTimer.restart()
                        }
                    }
                }
            }

            Rectangle {
                width: 28
                height: 28
                radius: Theme.radiusSm
                color: trashHover.hovered ? Theme.panelPill : "transparent"

                PanelIcon { anchors.centerIn: parent; name: "trash"; size: 16; color: Theme.textDim }
                HoverHandler { id: trashHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.remove() }
            }
        }
    }
}
