import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.components

// Hour over minutes, small, for the thin left strip.
Item {
    id: root

    property string screenName: ""

    readonly property real gap: 5
    readonly property real pad: 11

    implicitWidth: 32
    implicitHeight: 2 * digitsH + gap + 2 * pad

    // Digits have no descenders, so centre by the glyph box (baseline to digit top), not the line box.
    readonly property real digitsH: Math.ceil(metrics.tightBoundingRect.height)

    TextMetrics {
        id: metrics
        text: "0"
        font { family: Theme.fontUi; pixelSize: 16; weight: Theme.wHeavy }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Column {
        anchors.centerIn: parent
        spacing: root.gap

        Repeater {
            model: ["HH", "mm"]
            delegate: Item {
                required property string modelData
                width: label.implicitWidth
                height: root.digitsH
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    id: label
                    y: root.digitsH - label.baselineOffset
                    text: Qt.formatTime(clock.date, modelData)
                    color: Theme.accent
                    font: metrics.font
                }
            }
        }
    }

    PanelTrigger {
        anchors.fill: parent
        kind: "dashboard"
        clickOpens: true
        vertical: true
        screenName: root.screenName
    }
}
