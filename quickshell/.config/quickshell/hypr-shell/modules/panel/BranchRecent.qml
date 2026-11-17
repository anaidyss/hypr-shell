import QtQuick
import qs.theme
import qs.services
import qs.components

// Recently used or changed folders. Left click opens one in the file manager, right click in a terminal; the star
// pins a folder to the top.
Item {
    id: root

    readonly property real listMax: 360
    readonly property int rowH: 44

    implicitWidth: 380
    implicitHeight: 2 * Theme.padTile + 28 + 8 + body.height + 8 + 16

    Component.onCompleted: RecentFolders.refresh()

    Item {
        id: header
        x: Theme.padTile
        y: Theme.padTile
        width: root.width - 2 * Theme.padTile
        height: 28

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            PanelIcon { anchors.verticalCenter: parent.verticalCenter; name: "folder"; size: 16; color: Theme.accent2 }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "RECENT FOLDERS"
                color: Theme.textDim
                font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy; letterSpacing: 1.3 }
            }
        }
        Item {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: 28; height: 28
            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusSm
                color: refreshHover.hovered ? Theme.panelHigh : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
            }
            PanelIcon {
                anchors.centerIn: parent
                name: "restart"
                size: 16
                color: refreshHover.hovered ? Theme.text : Theme.textDim
                rotation: RecentFolders.loading ? 360 : 0
                Behavior on rotation { NumberAnimation { duration: Theme.durSlow; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
            }
            HoverHandler { id: refreshHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: RecentFolders.refresh() }
        }
    }

    Item {
        id: body
        x: Theme.padTile
        y: header.y + header.height + 8
        width: root.width - 2 * Theme.padTile
        height: RecentFolders.rows.length === 0 ? 72 : Math.min(root.listMax, list.height)
        clip: true

        Text {
            anchors.centerIn: parent
            visible: RecentFolders.rows.length === 0
            text: RecentFolders.loading ? "Loading folders…" : "Nothing recent"
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
        }

        Flickable {
            anchors.fill: parent
            contentHeight: list.height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list
                width: parent.width
                spacing: 4

                Repeater {
                    model: RecentFolders.rows

                    Item {
                        id: row
                        required property var modelData
                        readonly property bool pinned: RecentFolders.isPinned(modelData.path)

                        width: list.width
                        height: root.rowH

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radiusSm
                            color: rowHover.hovered ? Theme.panelHigh : Theme.panelRaised
                            Behavior on color { ColorAnimation { duration: Theme.durFast } }
                        }

                        PanelIcon { x: 12; anchors.verticalCenter: parent.verticalCenter; name: "folder"; size: 18; color: row.pinned ? Theme.accent : Theme.textDim }

                        Column {
                            x: 12 + 18 + 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - x - 8 - ageText.width - 8 - 28
                            spacing: 2
                            Text {
                                width: parent.width
                                text: row.modelData.name
                                elide: Text.ElideRight
                                color: Theme.text
                                font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
                            }
                            Text {
                                width: parent.width
                                text: row.modelData.parent
                                elide: Text.ElideMiddle
                                color: Theme.textDim
                                font { family: Theme.fontMono; pixelSize: 11; weight: Theme.wBold }
                            }
                        }

                        Text {
                            id: ageText
                            anchors { right: star.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            text: RecentFolders.age(row.modelData.ts)
                            color: Theme.textDim
                            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                        }

                        Item {
                            id: star
                            anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                            width: 28; height: 28
                            PanelIcon {
                                anchors.centerIn: parent
                                name: "star"
                                size: 16
                                color: row.pinned ? Theme.accent : (starHover.hovered ? Theme.text : Theme.textOff)
                            }
                            HoverHandler { id: starHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: RecentFolders.togglePin(row.modelData.path) }
                        }

                        HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: RecentFolders.openFiles(row.modelData.path)
                        }
                        TapHandler {
                            acceptedButtons: Qt.RightButton
                            onTapped: RecentFolders.openTerminal(row.modelData.path)
                        }
                    }
                }
            }
        }
    }

    Text {
        x: Theme.padTile
        y: body.y + body.height + 8
        width: root.width - 2 * Theme.padTile
        horizontalAlignment: Text.AlignHCenter
        text: "Click: file manager · Right click: terminal"
        color: Theme.textOff
        font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
    }
}
