import QtQuick
import qs.theme
import qs.services
import qs.components

// Frame for the mini terminal. The terminal itself is a separate window that shows through `hole`.
Item {
    id: root

    // Gap between the cutout and the edge of the branch (right and bottom); the panel rounds the cutout concentrically with it.
    readonly property real holeGap: 12
    readonly property rect hole: Qt.rect(holeGap, 46, 464, 234)

    implicitWidth: 488
    implicitHeight: 292

    PanelIcon {
        x: 16
        y: 14
        size: 18
        name: "terminal"
        color: Theme.textDim
    }

    Text {
        x: 42
        y: 15
        text: "Terminal"
        color: Theme.text
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
    }

    Rectangle {
        visible: MiniTerm.busy
        x: 118
        y: 11
        width: runningLabel.width + 34
        height: 24
        radius: 12
        color: Theme.tile

        Item {
            x: 9
            anchors.verticalCenter: parent.verticalCenter
            width: 12
            height: 12

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: "transparent"
                border.width: 2
                border.color: Qt.alpha(Theme.accent, 0.25)
            }
            Canvas {
                id: spinner
                anchors.fill: parent
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.strokeStyle = Theme.accent
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    ctx.arc(6, 6, 5, 0, Math.PI * 0.7)
                    ctx.stroke()
                }
                RotationAnimator on rotation { from: 0; to: 360; duration: 900; loops: Animation.Infinite; running: MiniTerm.busy }
            }
        }

        Text {
            id: runningLabel
            x: 27
            anchors.verticalCenter: parent.verticalCenter
            text: "Running"
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
        }
    }

    Row {
        anchors { right: parent.right; rightMargin: 12; top: parent.top; topMargin: 6 }
        spacing: 4

        PanelButton {
            width: 34
            height: 34
            icon: "chevronDown"
            clickOpens: false
            vertical: false
            onClicked: PanelState.dismiss("term")
        }
        PanelButton {
            width: 34
            height: 34
            icon: "close"
            clickOpens: false
            vertical: false
            opacity: MiniTerm.busy ? 0.3 : 1
            onClicked: {
                if (MiniTerm.busy) return
                MiniTerm.close()
                PanelState.dismiss("term")
            }
        }
    }

    Text {
        anchors { left: parent.left; leftMargin: 16; bottom: parent.bottom; bottomMargin: 4 }
        visible: MiniTerm.busy
        text: "Something is running: close is disabled, minimize keeps it going"
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
    }
}
