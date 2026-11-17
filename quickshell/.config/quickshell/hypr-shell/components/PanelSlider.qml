import QtQuick
import qs.theme

Item {
    id: root

    property real value: 0
    signal moved(real value)
    property bool dragging: false
    property var scroller: null

    function lockScroller() {
        let p = parent
        while (p) {
            if (p.flicking !== undefined) { scroller = p; p.interactive = false; break }
            p = p.parent
        }
    }
    function unlockScroller() {
        if (scroller) { scroller.interactive = true; scroller = null }
    }

    implicitHeight: 24

    function setFromX(x) {
        root.moved(Math.max(0, Math.min(1, x / width)))
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Theme.solid ? 12 : 6
        radius: Theme.solid ? 5 : height / 2
        color: Theme.panelTrack

        Rectangle {
            // Solid: a gap separates the fill from the handle bar (expressive slider).
            width: Theme.solid ? Math.max(0, Math.max(2, Math.min(track.width - 2, track.width * root.value)) - 6) : track.width * root.value
            height: parent.height
            radius: parent.radius
            color: Theme.accent
            Behavior on width { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
        }

        Rectangle {
            visible: Theme.solid
            x: Math.max(2, Math.min(track.width - 2, track.width * root.value)) - 2
            anchors.verticalCenter: parent.verticalCenter
            width: 4
            height: track.height + 8
            radius: 2
            color: Theme.accent
            Behavior on x { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => { root.dragging = true; root.lockScroller(); root.setFromX(mouse.x) }
        onPositionChanged: mouse => { if (root.dragging) root.setFromX(mouse.x) }
        onReleased: { root.dragging = false; root.unlockScroller() }
        onCanceled: { root.dragging = false; root.unlockScroller() }
        onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.04 : -0.04))))
    }
}
