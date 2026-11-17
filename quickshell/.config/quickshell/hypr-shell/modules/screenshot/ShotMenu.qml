import QtQuick
import qs.theme
import qs.components

// Pop-up list above a chip. Entries: { id, label, hint?, icon? }; the one matching `current` is marked.
Surface {
    id: root

    property var entries: []
    property string current: ""
    signal chosen(string id)

    radius: Theme.radiusMd
    color: Theme.panelBase
    width: Math.max(180, col.implicitWidth + 12)
    height: col.height + 12

    MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.AllButtons }

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.entries

            Item {
                required property var modelData
                readonly property bool on: root.current === modelData.id

                width: Math.max(168, rowItems.implicitWidth + 24)
                height: 32

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusSm
                    color: parent.on ? Qt.alpha(Theme.accent, 0.16) : (area.containsMouse ? Theme.panelHigh : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                }

                Row {
                    id: rowItems
                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    spacing: 8

                    PanelIcon {
                        visible: modelData.icon !== undefined
                        anchors.verticalCenter: parent.verticalCenter
                        name: modelData.icon || ""
                        size: 15
                        color: parent.parent.on ? Theme.accent : Theme.textDim
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: parent.parent.on ? Theme.accent : Theme.text
                        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                    }

                    Text {
                        visible: modelData.hint !== undefined
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.hint || ""
                        color: Theme.textDim
                        font { family: Theme.fontMono; pixelSize: 11; weight: Theme.wBold }
                    }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.chosen(modelData.id)
                }
            }
        }
    }
}
