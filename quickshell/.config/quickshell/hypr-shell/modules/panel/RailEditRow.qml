import QtQuick
import qs.theme
import qs.services
import qs.components

// One strip item in the editor: a visibility switch, its name, and buttons that move it up or down
// (across the border of a zone into the next one).
Item {
    id: root

    required property string itemId
    readonly property var info: RailLayout.meta(itemId)
    readonly property bool on: RailLayout.visible(itemId)

    width: parent ? parent.width : 0
    height: 36

    Switch {
        id: sw
        anchors.verticalCenter: parent.verticalCenter
        checked: root.on
        onToggled: value => RailLayout.setVisible(root.itemId, value)
    }

    PanelIcon {
        id: icon
        x: sw.width + 12
        anchors.verticalCenter: parent.verticalCenter
        name: root.info ? root.info.icon : ""
        size: 16
        color: root.on ? Theme.text : Theme.textOff
    }

    Text {
        x: icon.x + 16 + 8
        anchors.verticalCenter: parent.verticalCenter
        width: moves.x - x - 8
        elide: Text.ElideRight
        text: root.info ? root.info.label : root.itemId
        color: root.on ? Theme.text : Theme.textOff
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
    }

    Row {
        id: moves
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: 4

        Repeater {
            model: [
                { up: true, can: RailLayout.canMoveUp(root.itemId) },
                { up: false, can: RailLayout.canMoveDown(root.itemId) }
            ]

            Rectangle {
                id: btn
                required property var modelData
                width: 28; height: 28
                radius: Theme.radiusSm
                color: area.containsMouse && modelData.can ? Theme.panelHigh : Theme.panelPill
                opacity: modelData.can ? 1 : Theme.disabledOpacity
                Behavior on color { ColorAnimation { duration: Theme.durFast } }

                PanelIcon {
                    anchors.centerIn: parent
                    name: "chevronDown"
                    size: 16
                    rotation: btn.modelData.up ? 180 : 0
                    color: Theme.text
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: btn.modelData.can
                    cursorShape: btn.modelData.can ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: btn.modelData.up ? RailLayout.moveUp(root.itemId) : RailLayout.moveDown(root.itemId)
                }
            }
        }
    }
}
