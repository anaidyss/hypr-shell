import QtQuick
import qs.theme
import qs.services
import qs.components

// Editor of the left strip: three zones of items with a visibility switch and up/down buttons, the tool-menu tabs
// as toggles, and a reset. The strip itself is the live preview.
Item {
    id: root

    readonly property real pad: 12

    implicitWidth: 372
    implicitHeight: col.implicitHeight + 2 * pad

    Column {
        id: col
        x: root.pad
        y: root.pad
        width: root.width - 2 * root.pad
        spacing: Theme.gapTile

        Item {
            width: parent.width
            height: 32

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Left strip"
                color: Theme.text
                font { family: Theme.fontUi; pixelSize: 18; weight: Theme.wStrong }
            }

            Rectangle {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                width: resetText.implicitWidth + 24
                height: 28
                radius: Theme.radiusSm
                color: resetArea.containsMouse && !RailLayout.isDefault ? Theme.panelHigh : Theme.panelPill
                opacity: RailLayout.isDefault ? Theme.disabledOpacity : 1
                Behavior on color { ColorAnimation { duration: Theme.durFast } }

                Text {
                    id: resetText
                    anchors.centerIn: parent
                    text: "Reset"
                    color: Theme.text
                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                }
                MouseArea {
                    id: resetArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !RailLayout.isDefault
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: RailLayout.reset()
                }
            }
        }

        Repeater {
            model: RailLayout.zones

            Tile {
                id: zoneTile
                required property string modelData
                readonly property var items: RailLayout.ids(modelData)

                width: col.width
                height: zoneCol.implicitHeight + 2 * pad

                Column {
                    id: zoneCol
                    x: zoneTile.pad
                    y: zoneTile.pad
                    width: zoneTile.width - 2 * zoneTile.pad
                    spacing: 2

                    Text {
                        text: RailLayout.zoneTitles[zoneTile.modelData].toUpperCase()
                        color: Theme.textDim
                        font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy; letterSpacing: 1.3 }
                    }
                    Item { width: 1; height: 4 }

                    Text {
                        visible: zoneTile.items.length === 0
                        height: 28
                        verticalAlignment: Text.AlignVCenter
                        text: "Nothing here"
                        color: Theme.textOff
                        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                    }

                    Repeater {
                        model: zoneTile.items
                        RailEditRow { required property string modelData; itemId: modelData; width: zoneCol.width }
                    }
                }
            }
        }

        Tile {
            id: tabsTile
            width: col.width
            height: tabsCol.implicitHeight + 2 * pad

            Column {
                id: tabsCol
                x: tabsTile.pad
                y: tabsTile.pad
                width: tabsTile.width - 2 * tabsTile.pad
                spacing: 8

                Text {
                    text: "TOOL MENU TABS"
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy; letterSpacing: 1.3 }
                }

                Flow {
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: RailMenus.categories

                        Rectangle {
                            id: tabChip
                            required property var modelData
                            readonly property bool on: RailLayout.tabVisible(modelData.id)
                            width: tabRow.width + 20
                            height: 28
                            radius: Theme.radiusSm
                            color: tabArea.containsMouse ? Theme.panelHigh : (on ? Theme.accentContainer : Theme.panelPill)
                            Behavior on color { ColorAnimation { duration: Theme.durFast } }

                            Row {
                                id: tabRow
                                anchors.centerIn: parent
                                spacing: 6
                                PanelIcon { anchors.verticalCenter: parent.verticalCenter; name: tabChip.modelData.icon; size: 16; color: tabChip.on ? Theme.text : Theme.textOff }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: tabChip.modelData.title
                                    color: tabChip.on ? Theme.text : Theme.textOff
                                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                                }
                            }
                            MouseArea {
                                id: tabArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: RailLayout.setTabVisible(tabChip.modelData.id, !tabChip.on)
                            }
                        }
                    }
                }
            }
        }
    }
}
