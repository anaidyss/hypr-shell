import QtQuick
import qs.theme
import qs.services
import qs.components

// Terminal button with a spinning ring while something runs in the mini terminal.
Item {
    id: root

    property string screenName: ""
    property bool vertical: false
    property real size: 32
    property real iconSize: 18

    width: size
    height: size

    PanelButton {
        anchors.fill: parent
        icon: "terminal"
        iconSize: root.iconSize
        kind: "term"
        clickOpens: false
        vertical: root.vertical
        screenName: root.screenName
    }

    Canvas {
        anchors.centerIn: parent
        width: root.size - 4
        height: root.size - 4
        visible: MiniTerm.busy
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = Theme.accent
            ctx.lineWidth = 2
            ctx.lineCap = "round"
            ctx.beginPath()
            ctx.arc(width / 2, height / 2, width / 2 - 2, 0, Math.PI * 0.75)
            ctx.stroke()
        }
        RotationAnimator on rotation { from: 0; to: 360; duration: 1100; loops: Animation.Infinite; running: MiniTerm.busy }
    }
}
