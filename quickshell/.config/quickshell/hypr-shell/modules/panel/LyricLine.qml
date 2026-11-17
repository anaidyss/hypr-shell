import QtQuick
import QtQuick.Effects
import qs.theme
import qs.services

// One line of synced lyrics. The sung line is full size and fills from left to right as it is sung (row by row when
// it wraps); the others are smaller, dimmer and, further away, slightly blurred. An empty line is a pause: three
// dots that light up through it and breathe while playing.
Item {
    id: root

    required property var modelData
    required property int index

    // Set by the list
    property int current: -1
    property real progress: 0       // of the current line, 0..1
    property bool free: false       // scrolled by hand: everything sharp and readable
    property bool playing: false

    readonly property bool now: index === current
    readonly property bool past: index < current
    readonly property int dist: Math.abs(index - current)
    readonly property bool gap: modelData.text === ""

    signal picked(int index)

    property real s: now ? 1 : 0.78
    Behavior on s { NumberAnimation { duration: Theme.durOpen; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }

    implicitHeight: body.height * s + 12
    opacity: free ? (hover.hovered ? 1 : 0.7) : (now ? 1 : (dist === 1 ? 0.6 : (past ? 0.3 : 0.42)))
    Behavior on opacity { NumberAnimation { duration: Theme.durSlow; easing.type: Theme.easingCalm } }

    Item {
        id: body
        y: 6
        width: root.width
        height: root.gap ? 24 : label.implicitHeight
        scale: root.s
        transformOrigin: Item.TopLeft

        layer.enabled: !root.free && root.dist >= 2
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 16
            blur: Math.min(0.8, (root.dist - 1) * 0.25)
        }

        // Unsung part (the whole line when it is not the current one)
        Text {
            id: label
            visible: !root.gap
            width: parent.width
            wrapMode: Text.WordWrap
            text: root.modelData.text
            color: Theme.text
            opacity: root.now ? 0.38 : 1
            font { family: Theme.fontUi; pixelSize: 18; weight: Theme.wStrong }
            Behavior on opacity { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easingCalm } }

            // Width of every laid out row, so the fill runs over the words and not over empty space.
            property var rows: []
            onTextChanged: rows = []
            onLineLaidOut: line => {
                const r = rows.slice()
                r[line.number] = line.implicitWidth !== undefined ? line.implicitWidth : width
                rows = r
            }
        }

        // Sung part: per row, a copy of the line clipped to how far that row has been sung, with a soft half-lit tail.
        Item {
            id: wipe
            visible: root.now && !root.gap
            width: label.width
            height: label.height

            readonly property int rowCount: Math.max(1, label.lineCount)
            readonly property real rowH: label.height / rowCount
            readonly property real soft: 20

            Repeater {
                model: wipe.visible ? wipe.rowCount : 0

                Item {
                    id: row
                    required property int index
                    readonly property real rowW: label.rows[index] !== undefined ? label.rows[index] : label.width
                    readonly property real part: Math.max(0, Math.min(1, root.progress * wipe.rowCount - index))
                    readonly property real edge: part * rowW
                    y: index * wipe.rowH
                    width: label.width
                    height: wipe.rowH

                    Item {
                        width: row.edge
                        height: parent.height
                        clip: true
                        Text {
                            y: -row.y
                            width: label.width
                            wrapMode: Text.WordWrap
                            text: label.text
                            color: Theme.text
                            font: label.font
                        }
                    }
                    Item {
                        x: row.edge
                        width: row.part > 0 && row.part < 1 ? Math.min(wipe.soft, row.rowW - row.edge) : 0
                        height: parent.height
                        clip: true
                        opacity: 0.5
                        Text {
                            x: -row.edge
                            y: -row.y
                            width: label.width
                            wrapMode: Text.WordWrap
                            text: label.text
                            color: Theme.text
                            font: label.font
                        }
                    }
                }
            }
        }

        // A pause: three dots
        Row {
            id: dots
            visible: root.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            transformOrigin: Item.Left

            Repeater {
                model: 3

                Rectangle {
                    required property int index
                    width: 12; height: 12
                    radius: 6
                    color: Theme.text
                    opacity: root.now ? 0.25 + 0.75 * Math.max(0, Math.min(1, root.progress * 3 - index)) : 0.5
                }
            }

            SequentialAnimation on scale {
                running: root.now && root.gap && root.playing
                loops: Animation.Infinite
                alwaysRunToEnd: true
                NumberAnimation { to: 1.15; duration: Theme.durOpen * 2; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: Theme.durOpen * 2; easing.type: Easing.InOutSine }
            }
        }
    }

    HoverHandler { id: hover; cursorShape: Players.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor }
    TapHandler { onTapped: root.picked(root.index) }
}
