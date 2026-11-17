import QtQuick
import qs.theme

// Settings preview of the solid design: a miniature screen with frame, a left strip, a tinted block and a tile, built
// from the chosen options (frame color, layer toning, outlines) whatever the current mode is.
Item {
    id: root

    readonly property var pal: Theme.colors
    readonly property bool tonal: Theme.cfg.design.layers === "tonal"
    readonly property bool lines: Theme.cfg.design.outlines === "subtle"
    readonly property color frameCol: Theme.solidColor
    readonly property color veil: tonal ? Qt.tint(pal.surface2, Qt.rgba(1, 1, 1, 0.1)) : "#ffffff"
    readonly property color raised: Qt.alpha(veil, tonal ? 0.5 : 0.085)
    readonly property color pill: Qt.alpha(veil, tonal ? 0.6 : 0.115)
    readonly property color line: lines ? Qt.rgba(1, 1, 1, Theme.cfg.border.inactive * 0.5) : "transparent"
    readonly property int rad: Math.round(Theme.rounding * 1.5 * 1.25)

    width: parent ? parent.width : implicitWidth
    implicitHeight: 204

    Rectangle {
        id: screen
        anchors.fill: parent
        radius: Theme.radiusLg
        color: root.frameCol

        Rectangle {
            id: hole
            x: 36
            y: 10
            width: parent.width - 46
            height: parent.height - 20
            radius: Math.min(root.rad, height / 2)
            color: pal.crust
            border.width: 1
            border.color: root.line

            Row {
                x: 14
                y: 14
                spacing: 8
                height: 26

                Rectangle {
                    width: 78; height: 26; radius: Theme.radiusSm
                    color: Theme.accentContainer
                    Text { anchors.centerIn: parent; text: "Dashboard"; color: Theme.text; font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold } }
                }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "Media"; color: Theme.textDim; font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold } }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "Performance"; color: Theme.textDim; font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold } }
            }

            Rectangle {
                id: card
                x: 14
                y: 50
                width: Math.min(220, parent.width * 0.42)
                height: parent.height - 64
                radius: Math.round(root.rad * 0.6)
                color: Qt.tint(root.frameCol, root.raised)
                border.width: 1
                border.color: root.line

                Text { x: 12; y: 10; text: "Weather"; color: Theme.textDim; font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy } }
                Text { x: 12; y: 28; text: "18°"; color: Theme.text; font { family: Theme.fontUi; pixelSize: 26; weight: Theme.wStrong } }

                Rectangle {
                    x: 12
                    anchors { bottom: parent.bottom; bottomMargin: 12 }
                    width: parent.width - 24
                    height: 28
                    radius: Theme.radiusSm
                    color: Qt.tint(Qt.tint(root.frameCol, root.raised), root.pill)
                    border.width: 1
                    border.color: root.line
                    Text { anchors.centerIn: parent; text: "H 20°  L 15°"; color: Theme.textDim; font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold } }
                }
            }

            Rectangle {
                x: card.x + card.width + 12
                y: card.y
                width: 56
                height: card.height
                radius: Math.round(root.rad * 0.6)
                color: Qt.tint(root.frameCol, root.raised)
                border.width: 1
                border.color: root.line

                Rectangle {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 12; bottom: parent.bottom; bottomMargin: 12 }
                    width: 16
                    radius: 8
                    color: Qt.alpha(Theme.text, 0.12)
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: parent.height * 0.62
                        radius: 8
                        color: Theme.accent
                    }
                }
            }
        }

        Column {
            x: 9
            y: 14
            spacing: 8
            Repeater {
                model: 3
                Rectangle {
                    required property int index
                    width: 18; height: 18; radius: 9
                    color: index === 0 ? Theme.accentContainer : Qt.tint(root.frameCol, root.pill)
                }
            }
        }
    }
}
