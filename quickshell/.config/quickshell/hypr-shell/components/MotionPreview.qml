import QtQuick
import QtQuick.Shapes
import qs.theme

// Animation speeds: a dot per speed runs once with its own duration and the shell easing; the curve shows the easing.
Item {
    id: root

    readonly property var speeds: [
        { label: "Fast", ms: Theme.durFast },
        { label: "Normal", ms: Theme.durNormal },
        { label: "Smooth", ms: Theme.durSlow }
    ]
    readonly property real graphW: 132

    width: parent ? parent.width : implicitWidth
    implicitHeight: 148

    function play() {
        replay.stop()
        for (let i = 0; i < rows.count; i++) rows.itemAt(i).run()
    }

    // Changing a duration replays once after the slider settles.
    Connections {
        target: Theme
        function onDurFastChanged() { replay.restart() }
        function onDurNormalChanged() { replay.restart() }
        function onDurSlowChanged() { replay.restart() }
    }
    Timer { id: replay; interval: 400; onTriggered: root.play() }

    Rectangle {
        id: playButton
        width: 84; height: 28
        radius: 14
        color: playHover.hovered ? Theme.panelHigh : Theme.panelPill
        Behavior on color { ColorAnimation { duration: Theme.durFast } }

        Row {
            anchors.centerIn: parent
            spacing: 4
            PanelIcon { anchors.verticalCenter: parent.verticalCenter; name: "play"; size: 14; color: Theme.accent }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Play"
                color: Theme.text
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
            }
        }
        HoverHandler { id: playHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.play() }
    }

    Column {
        id: list
        y: 40
        width: parent.width - root.graphW - 24
        spacing: 4

        Repeater {
            id: rows
            model: root.speeds

            delegate: Item {
                id: row
                required property var modelData
                property real t: 1

                function run() { anim.restart() }
                NumberAnimation { id: anim; target: row; property: "t"; from: 0; to: 1; duration: row.modelData.ms; easing.type: Theme.easing; easing.overshoot: Theme.overshoot }

                width: list.width
                height: 32

                Text {
                    width: 56
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.label
                    color: Theme.text
                    font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                }
                Text {
                    x: 60
                    width: 56
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.ms + " ms"
                    color: Theme.textDim
                    font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold }
                }
                Rectangle {
                    id: track
                    x: 124
                    width: parent.width - x
                    height: 4; radius: 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.panelPill
                    Rectangle { width: dot.x + dot.width / 2; height: parent.height; radius: 2; color: Theme.accent; opacity: Theme.disabledOpacity }
                    Rectangle {
                        id: dot
                        x: row.t * (track.width - width)
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14; height: 14; radius: 7
                        color: Theme.accent
                    }
                }
            }
        }
    }

    // Easing curve
    Rectangle {
        id: graph
        x: parent.width - root.graphW
        y: 8
        width: root.graphW
        height: 132
        radius: Theme.radiusSm
        color: Theme.panelRaised
        border.width: 1
        border.color: Theme.border

        Rectangle { x: 16; y: parent.height - 16; width: parent.width - 32; height: 1; color: Theme.separator }
        Rectangle { x: 16; y: 16; width: 1; height: parent.height - 32; color: Theme.separator }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Theme.accent
                strokeWidth: 2
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathPolyline {
                    path: {
                        const w = graph.width - 32, h = graph.height - 32, pts = []
                        for (let i = 0; i <= 24; i++) {
                            const t = i / 24
                            pts.push(Qt.point(16 + t * w, graph.height - 16 - (1 - Math.pow(1 - t, 3)) * h))
                        }
                        return pts
                    }
                }
            }
        }
        Text {
            anchors { right: parent.right; rightMargin: 8; bottom: parent.bottom; bottomMargin: 20 }
            text: "ease-out"
            color: Theme.textDim
            font { family: Theme.fontMono; pixelSize: 11; weight: Theme.wBold }
        }
    }
}
