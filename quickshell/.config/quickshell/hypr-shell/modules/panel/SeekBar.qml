import QtQuick
import qs.theme

// Horizontal progress bar; click or drag to seek. The thumb appears under the pointer.
Item {
    id: root

    property real ratio: 0
    property bool seekable: true
    signal seeked(real ratio)

    property bool dragging: false
    property real dragRatio: 0
    readonly property real shown: dragging ? dragRatio : ratio
    readonly property bool engaged: seekable && (hover.hovered || dragging)

    implicitHeight: 20

    function at(x) { return Math.max(0, Math.min(1, x / width)) }

    Rectangle {
        id: track
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        height: Theme.solid ? (root.engaged ? 10 : 8) : (root.engaged ? 6 : 4)
        radius: Theme.solid ? 4 : height / 2
        color: Theme.panelPill
        Behavior on height { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }

        Rectangle {
            width: Theme.solid ? Math.max(0, Math.max(2, Math.min(parent.width - 2, parent.width * root.shown)) - 6) : parent.width * root.shown
            height: parent.height
            radius: parent.radius
            color: Theme.accent
        }

        Rectangle {
            x: (Theme.solid ? Math.max(2, Math.min(parent.width - 2, parent.width * root.shown)) : parent.width * root.shown) - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.solid ? 4 : 12
            height: Theme.solid ? 18 : 12
            radius: width / 2
            color: Theme.solid ? Theme.accent : Theme.text
            opacity: Theme.solid || root.engaged ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
        }
    }

    HoverHandler { id: hover; cursorShape: root.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor }

    MouseArea {
        anchors.fill: parent
        enabled: root.seekable
        onPressed: mouse => { root.dragRatio = root.at(mouse.x); root.dragging = true }
        onPositionChanged: mouse => { if (pressed) root.dragRatio = root.at(mouse.x) }
        onReleased: { root.dragging = false; root.seeked(root.dragRatio) }
        onCanceled: root.dragging = false
    }
}
