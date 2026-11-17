import QtQuick
import qs.theme
import qs.components

// Style of the next mark: color, line width and fill.
Surface {
    id: root

    required property var model

    readonly property var swatches: [Theme.accent.toString(), "#ff5a5f", "#ffb020", "#34c759", "#3d8bff", "#ffffff"]
    readonly property var widths: [2, 4, 7]

    radius: Theme.radiusMd
    color: Theme.panelBase
    width: row.width + 16
    height: 46

    // Keeps clicks on the card from reaching the selection underneath.
    MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.AllButtons }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            opacity: root.model.usesColor ? 1 : 0.35
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }

            Repeater {
                model: root.swatches

                Item {
                    required property string modelData
                    readonly property bool on: root.model.color.toLowerCase() === modelData.toLowerCase()

                    width: 24
                    height: 34

                    Rectangle {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        radius: 11
                        color: "transparent"
                        border.width: 2
                        border.color: parent.on ? Theme.text : "transparent"
                        Behavior on border.color { ColorAnimation { duration: Theme.durFast } }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        radius: 7
                        color: modelData
                        border.width: 1
                        border.color: Theme.hoverStrong
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.model.usesColor
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.model.color = modelData
                    }
                }
            }
        }

        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 22; color: Theme.border }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            opacity: root.model.usesWidth ? 1 : 0.35
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }

            Repeater {
                model: root.widths

                Item {
                    required property int modelData
                    required property int index
                    readonly property bool on: root.model.width === modelData

                    width: 30
                    height: 34

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusSm
                        color: parent.on ? Qt.alpha(Theme.accent, 0.18) : (area.containsMouse && root.model.usesWidth ? Theme.panelHigh : "transparent")
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 5 + index * 3
                        height: width
                        radius: width / 2
                        color: parent.on ? Theme.accent : Theme.textDim
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.model.usesWidth
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.model.width = modelData
                    }
                }
            }
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 34
            opacity: root.model.usesFill ? 1 : 0.35
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusSm
                color: fillArea.containsMouse && root.model.usesFill ? Theme.panelHigh : "transparent"
            }

            Rectangle {
                anchors.centerIn: parent
                width: 15
                height: 15
                radius: 4
                color: root.model.fill ? Qt.alpha(Theme.accent, 0.5) : "transparent"
                border.width: 1.7
                border.color: root.model.fill ? Theme.accent : Theme.textDim
            }

            MouseArea {
                id: fillArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.model.usesFill
                cursorShape: Qt.PointingHandCursor
                onClicked: root.model.fill = !root.model.fill
            }
        }
    }
}
