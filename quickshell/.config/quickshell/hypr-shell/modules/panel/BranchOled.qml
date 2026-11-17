import QtQuick
import qs.theme
import qs.services
import qs.components

// OLED care: how far the strip drifts, when it dims and how much, and when it fades out. Changes apply at once.
Item {
    id: root

    readonly property real pad: 12
    readonly property var shiftSteps: [0, 1, 2]
    readonly property var dimAfterSteps: [0, 1, 2, 5, 10, 15, 30]
    readonly property var hideAfterSteps: [0, 15, 30, 60, 120]

    implicitWidth: 340
    implicitHeight: col.implicitHeight + 2 * pad

    function ratioOf(steps, value) {
        const i = steps.indexOf(value)
        return (i < 0 ? 0 : i) / (steps.length - 1)
    }
    function pick(steps, ratio) { return steps[Math.round(ratio * (steps.length - 1))] }
    function minutes(m) { return m === 0 ? "Off" : (m >= 60 ? (m / 60) + " h" : m + " min") }

    Column {
        id: col
        x: root.pad
        y: root.pad
        width: root.width - 2 * root.pad
        spacing: Theme.gapTile

        Item {
            width: parent.width
            height: 32

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "OLED care"
                color: Theme.text
                font { family: Theme.fontUi; pixelSize: 18; weight: Theme.wStrong }
            }
            Text {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: OledCare.status
                color: OledCare.dimmed || OledCare.hidden ? Theme.accent : Theme.textDim
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }
        }

        Tile {
            id: tile
            width: col.width
            height: rows.implicitHeight + 2 * pad

            Column {
                id: rows
                x: tile.pad
                y: tile.pad
                width: tile.width - 2 * tile.pad
                spacing: 12

                SliderRow {
                    title: "Drift"
                    valueText: Theme.cfg.oled.shift === 0 ? "Off" : "±" + Theme.cfg.oled.shift + " px"
                    ratio: root.ratioOf(root.shiftSteps, Theme.cfg.oled.shift)
                    onMoved: r => Theme.set("oled", "shift", root.pick(root.shiftSteps, r))
                }
                SliderRow {
                    title: "Dim after"
                    valueText: root.minutes(Theme.cfg.oled.dimAfter)
                    ratio: root.ratioOf(root.dimAfterSteps, Theme.cfg.oled.dimAfter)
                    onMoved: r => Theme.set("oled", "dimAfter", root.pick(root.dimAfterSteps, r))
                }
                SliderRow {
                    title: "Dim level"
                    valueText: Math.round(Theme.cfg.oled.dimLevel * 100) + " %"
                    ratio: (Theme.cfg.oled.dimLevel - 0.1) / 0.8
                    onMoved: r => Theme.set("oled", "dimLevel", Math.round((0.1 + 0.8 * r) * 20) / 20)
                }
                SliderRow {
                    title: "Fade out after"
                    valueText: root.minutes(Theme.cfg.oled.hideAfter)
                    ratio: root.ratioOf(root.hideAfterSteps, Theme.cfg.oled.hideAfter)
                    onMoved: r => Theme.set("oled", "hideAfter", root.pick(root.hideAfterSteps, r))
                }
            }
        }

        Rectangle {
            width: col.width
            height: 32
            radius: Theme.radiusSm
            color: previewArea.containsMouse ? Theme.panelHigh : Theme.panelPill
            Behavior on color { ColorAnimation { duration: Theme.durFast } }

            Text {
                anchors.centerIn: parent
                text: OledCare.previewing ? "Dimmed, back in a moment" : "Preview dimming"
                color: Theme.text
                font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
            }
            MouseArea {
                id: previewArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: OledCare.preview()
            }
        }
    }

    component SliderRow: Item {
        id: sr
        property string title
        property string valueText
        property real ratio: 0
        signal moved(real r)

        width: parent ? parent.width : 0
        height: 40

        Text {
            text: sr.title
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
        Text {
            anchors.right: parent.right
            text: sr.valueText
            color: Theme.text
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
        }
        PanelSlider {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            value: sr.ratio
            onMoved: v => sr.moved(v)
        }
    }
}
