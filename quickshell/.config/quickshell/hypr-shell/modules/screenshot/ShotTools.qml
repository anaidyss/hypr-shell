import QtQuick
import qs.theme
import qs.components

// Vertical tool card next to the selection: tools on top, history actions below.
Surface {
    id: root

    required property var model

    readonly property var tools: [
        { id: "move", icon: "pointer" },
        { id: "pen", icon: "pen" },
        { id: "marker", icon: "marker" },
        { id: "line", icon: "slash" },
        { id: "arrow", icon: "arrowUpRight" },
        { id: "rect", icon: "square" },
        { id: "ellipse", icon: "circle" },
        { id: "text", icon: "type" },
        { id: "num", icon: "numbered" },
        { id: "pixel", icon: "mosaic" },
        { id: "erase", icon: "eraser" }
    ]

    radius: Theme.radiusMd
    color: Theme.panelBase
    width: 46
    height: col.height + 12

    MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.AllButtons }

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.tools

            ShotButton {
                required property var modelData
                icon: modelData.icon
                active: root.model.tool === modelData.id
                onClicked: root.model.tool = modelData.id
            }
        }

        Rectangle {
            width: 34
            height: 1
            color: Theme.border
        }

        ShotButton { icon: "undo"; enabled: root.model.canUndo; onClicked: root.model.undo() }
        ShotButton { icon: "redo"; enabled: root.model.canRedo; onClicked: root.model.redo() }
        ShotButton { icon: "trash"; enabled: root.model.items.length > 0; onClicked: root.model.clear() }
    }
}
