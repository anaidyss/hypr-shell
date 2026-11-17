import QtQuick
import qs.theme
import qs.components

// Region / Window / Screen switch above the selection.
Surface {
    id: root

    property string mode: "region"
    signal picked(string mode)

    readonly property var entries: [
        { id: "region", icon: "selection", label: "Region" },
        { id: "window", icon: "appWindow", label: "Window" },
        { id: "screen", icon: "monitor", label: "Screen" }
    ]

    radius: Theme.radiusMd
    color: Theme.panelBase
    width: row.width + 12
    height: 46

    // Keeps clicks on the card from reaching the selection underneath.
    MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.AllButtons }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root.entries

            Item {
                required property var modelData
                readonly property bool on: root.mode === modelData.id

                width: label.implicitWidth + 44
                height: 34

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusSm
                    color: parent.on ? Qt.alpha(Theme.accent, 0.18) : (area.containsMouse ? Theme.panelHigh : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                }

                PanelIcon {
                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    name: modelData.icon
                    size: 16
                    color: parent.on ? Theme.accent : Theme.textDim
                }

                Text {
                    id: label
                    anchors { left: parent.left; leftMargin: 34; verticalCenter: parent.verticalCenter }
                    text: modelData.label
                    color: parent.on ? Theme.accent : Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(modelData.id)
                }
            }
        }
    }
}
