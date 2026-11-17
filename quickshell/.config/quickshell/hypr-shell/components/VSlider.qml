import QtQuick
import qs.theme
import qs.components

// A vertical slider: a fat track that fills from the bottom, icon below. Drag, click or scroll.
Item {
    id: root

    property string icon
    property real value: 0
    property bool iconActive: false
    property bool dimIcon: false
    property bool showValue: false

    signal moved(real value)
    signal iconClicked()

    property bool dragging: false
    property var scroller: null
    readonly property bool active: area.pressed || dragging

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

    opacity: enabled ? 1 : 0.38

    Item {
        id: iconBox
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
        width: 22; height: 22

        Rectangle {
            anchors.fill: parent
            radius: 11
            color: Theme.panelPill
            opacity: iconTap.pressed ? 1 : (iconHover.hovered && root.iconActive ? 0.8 : 0)
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
        }
        PanelIcon { anchors.centerIn: parent; name: root.icon; size: 16; color: root.dimIcon ? Theme.textDim : Theme.text }

        HoverHandler { id: iconHover; cursorShape: root.iconActive ? Qt.PointingHandCursor : Qt.ArrowCursor }
        TapHandler { id: iconTap; enabled: root.iconActive; onTapped: root.iconClicked() }
    }

    Text {
        visible: root.showValue
        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
        text: Math.round(root.value * 100)
        color: root.dimIcon ? Theme.textDim : Theme.text
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
    }

    Item {
        id: track
        anchors { top: parent.top; topMargin: root.showValue ? 22 : 0; bottom: iconBox.top; bottomMargin: 10; horizontalCenter: parent.horizontalCenter }
        width: parent.width

        Rectangle {
            id: groove
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height
            width: 22
            // Solid: a rounded square body instead of a pill; the handle bar sits one small gap above the fill.
            readonly property real bodyRadius: Theme.solid ? 6 : 11
            readonly property real handlePos: Math.max(2, Math.min(height - 2, height * root.value))
            radius: bodyRadius
            color: root.active ? Theme.panelTrackHigh : Theme.panelTrack
            Behavior on color { ColorAnimation { duration: Theme.durFast } }

            Rectangle {
                id: fill
                anchors.bottom: parent.bottom
                width: parent.width
                height: Theme.solid ? Math.max(0, groove.handlePos - 6) : Math.max(groove.width, groove.height * root.value)
                radius: groove.bodyRadius
                color: Theme.accent
                Behavior on height { enabled: !root.active; NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
            }

            // Solid: the fill stops short of a handle bar (expressive slider).
            Rectangle {
                visible: Theme.solid
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height - groove.handlePos - 2
                width: groove.width + 8
                height: 4
                radius: 2
                color: Theme.accent
                Behavior on y { enabled: !root.active; NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => { root.dragging = true; root.lockScroller(); root.moved(Math.max(0, Math.min(1, 1 - mouse.y / height))) }
            onPositionChanged: mouse => { if (root.dragging) root.moved(Math.max(0, Math.min(1, 1 - mouse.y / height))) }
            onReleased: { root.dragging = false; root.unlockScroller() }
            onCanceled: { root.dragging = false; root.unlockScroller() }
            onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.04 : -0.04))))
        }
    }
}
