import QtQuick
import qs.theme
import qs.services
import qs.components

// Night light: the switch, the color temperature and when it turns on by itself.
Item {
    id: root

    readonly property real pad: 12
    readonly property var schedules: ["manual", "hours", "sun"]
    readonly property real ratio: (NightLight.maxKelvin - NightLight.kelvin) / (NightLight.maxKelvin - NightLight.minKelvin)

    implicitWidth: 330
    implicitHeight: 2 * pad + 156 + Theme.gapBlock + 166

    function swatch(k) {
        const t = NightLight.tint(k)
        return Qt.rgba(t[0], t[1], t[2], 1)
    }

    Block {
        id: lightBlock
        x: root.pad
        y: root.pad
        width: root.width - 2 * root.pad
        height: 156
        title: "Night light"
        icon: "moon"
        tone: Theme.secondaryContainer

        Row {
            width: parent.width
            height: 40

            Column {
                width: parent.width - toggle.width
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: NightLight.kelvin + " K"
                    color: Theme.text
                    font { family: Theme.fontUi; pixelSize: 26; weight: Theme.wHeavy }
                }
                Text {
                    text: NightLight.warmth
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                }
            }
            Switch {
                id: toggle
                anchors.verticalCenter: parent.verticalCenter
                checked: NightLight.on
                onToggled: v => NightLight.setOn(v)
            }
        }

        Rectangle {
            y: 54
            width: parent.width
            height: 8
            radius: 4
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: root.swatch(NightLight.maxKelvin) }
                GradientStop { position: 1; color: root.swatch(NightLight.minKelvin) }
            }
        }
        PanelSlider {
            y: 66
            width: parent.width
            value: root.ratio
            onMoved: v => NightLight.setKelvin(NightLight.maxKelvin - v * (NightLight.maxKelvin - NightLight.minKelvin))
        }
    }

    Block {
        x: root.pad
        y: lightBlock.y + lightBlock.height + Theme.gapBlock
        width: root.width - 2 * root.pad
        height: 166
        title: "Schedule"
        icon: "clock"

        SegmentedControl {
            width: parent.width
            model: ["Manual", "Hours", "Sunset"]
            current: Math.max(0, root.schedules.indexOf(NightLight.schedule))
            onPicked: i => NightLight.setSchedule(root.schedules[i])
        }

        Column {
            y: 44
            width: parent.width
            spacing: Theme.gapTile
            visible: NightLight.schedule === "hours"

            ValueStepper {
                width: parent.width
                label: "From"
                value: NightLight.clock(NightLight.fromMinute)
                onStep: d => NightLight.setFrom(NightLight.fromMinute + d * 30)
            }
            ValueStepper {
                width: parent.width
                label: "Until"
                value: NightLight.clock(NightLight.toMinute)
                onStep: d => NightLight.setTo(NightLight.toMinute + d * 30)
            }
        }

        Text {
            y: 48
            width: parent.width
            visible: NightLight.schedule !== "hours"
            wrapMode: Text.WordWrap
            color: Theme.textDim
            text: NightLight.schedule === "manual" ? "Only the switch turns it on and off"
                : (Weather.has && Weather.data.sunset ? "From sunset at " + Weather.data.sunset + " until sunrise at " + Weather.data.sunrise : "Waiting for weather data")
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
    }
}
