import QtQuick
import Quickshell.Hyprland
import qs.theme

// Workspace dots. Glass mode stretches the focused dot into a pill; solid mode keeps the dots still
// (filled when the workspace has windows, dim when empty) and slides one pill indicator between them.
Item {
    id: root

    property bool vertical: false

    readonly property bool solid: Theme.solid
    readonly property real dot: 8
    readonly property real pillLength: 22
    property Item focusedSlot: null

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    Grid {
        id: grid

        columns: root.vertical ? 1 : 32
        spacing: 6
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Repeater {
            model: Hyprland.workspaces

            delegate: Item {
                id: slot

                required property var modelData

                readonly property bool focused: modelData.focused
                readonly property bool occupied: modelData.toplevels.values.length > 0
                readonly property real longSide: focused ? root.pillLength : root.dot

                visible: modelData.id > 0
                width: visible ? (root.vertical ? root.dot : longSide) : 0
                height: visible ? (root.vertical ? longSide : root.dot) : 0

                onFocusedChanged: if (focused) root.focusedSlot = slot
                Component.onCompleted: if (focused) root.focusedSlot = slot

                Behavior on width { enabled: !root.solid; NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
                Behavior on height { enabled: !root.solid; NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }

                Rectangle {
                    anchors.centerIn: parent
                    width: root.solid ? root.dot : parent.width
                    height: root.solid ? root.dot : parent.height
                    radius: 4
                    visible: !(root.solid && slot.focused)
                    color: root.solid
                        ? (slot.occupied ? Theme.text : Theme.textOff)
                        : (slot.focused ? Theme.accent : Theme.textDim)
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                }

                MouseArea {
                    anchors { fill: parent; margins: -5 }
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.activate()
                }
            }
        }
    }

    // The sliding indicator of solid mode.
    Rectangle {
        id: pill

        readonly property bool ready: root.solid && root.focusedSlot !== null && root.focusedSlot.visible

        visible: ready
        x: root.focusedSlot ? grid.x + root.focusedSlot.x : 0
        y: root.focusedSlot ? grid.y + root.focusedSlot.y : 0
        width: root.vertical ? root.dot : root.pillLength
        height: root.vertical ? root.pillLength : root.dot
        radius: root.dot / 2
        color: Theme.accent

        Behavior on x { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easingOpen; easing.overshoot: Theme.overshoot } }
        Behavior on y { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easingOpen; easing.overshoot: Theme.overshoot } }
    }
}
