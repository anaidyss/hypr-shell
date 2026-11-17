import QtQuick
import qs.theme

Item {
    id: root

    property string title
    property string description
    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0.01
    property int decimals: 0
    property real displayScale: 1
    property string suffix: ""
    signal moved(real v)
    property bool dragging: false
    property var scroller: null

    // Stop an enclosing Flickable from stealing the drag when the pointer moves off the slider.
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

    readonly property real ratio: to > from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0

    width: parent ? parent.width : implicitWidth
    implicitHeight: 52

    function commit(x) {
        const r = Math.max(0, Math.min(1, x / track.width))
        let v = from + r * (to - from)
        v = Math.round(v / stepSize) * stepSize
        v = Math.max(from, Math.min(to, v))
        if (v !== value) moved(v)
    }

    Column {
        anchors { left: parent.left; right: slider.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 2
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.title
            color: Theme.text
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
        }
        Text {
            width: parent.width
            elide: Text.ElideRight
            visible: root.description !== ""
            text: root.description
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
    }

    Text {
        id: readout
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: 56
        horizontalAlignment: Text.AlignRight
        text: (root.value * root.displayScale).toFixed(root.decimals) + root.suffix
        color: Theme.textDim
        font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold }
    }

    Item {
        id: slider
        anchors { right: readout.left; rightMargin: 14; verticalCenter: parent.verticalCenter }
        width: Math.max(120, Math.min(220, root.width * 0.36))
        height: 24

        Rectangle {
            id: track
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
            height: Theme.solid ? 10 : 4
            radius: Theme.solid ? 4 : height / 2
            color: Theme.tile

            Rectangle {
                width: Theme.solid ? Math.max(0, Math.max(2, Math.min(track.width - 2, track.width * root.ratio)) - 6) : track.width * root.ratio
                height: parent.height
                radius: parent.radius
                color: Theme.accent
            }
        }

        Rectangle {
            x: (Theme.solid ? Math.max(2, Math.min(track.width - 2, track.width * root.ratio)) : track.width * root.ratio) - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.solid ? 4 : (drag.pressed ? 16 : 14)
            height: Theme.solid ? 22 : width
            radius: width / 2
            color: Theme.solid ? Theme.accent : Theme.text
            Behavior on width { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => { root.dragging = true; root.lockScroller(); root.commit(mouse.x - track.x) }
            onPositionChanged: mouse => { if (root.dragging) root.commit(mouse.x - track.x) }
            onReleased: { root.dragging = false; root.unlockScroller() }
            onCanceled: { root.dragging = false; root.unlockScroller() }
        }
    }
}
