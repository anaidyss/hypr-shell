import QtQuick
import qs.theme
import qs.services
import qs.components

// Pomodoro lengths in minutes: focus, short break and long break, each with a minus and a plus.
Row {
    id: root

    spacing: Theme.gapTile

    Repeater {
        model: [
            { id: "focus", label: "Focus" },
            { id: "break", label: "Break" },
            { id: "long", label: "Long" }
        ]

        Item {
            id: col
            required property var modelData
            readonly property int minutes: modelData.id === "focus" ? TimerService.pmFocus : (modelData.id === "break" ? TimerService.pmBreak : TimerService.pmLong)

            width: (root.width - 2 * root.spacing) / 3
            height: root.height

            StepButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: "minus"
                onClicked: TimerService.pmSetLength(col.modelData.id, col.minutes - 1)
            }
            Text {
                anchors.centerIn: parent
                text: col.modelData.label + " " + col.minutes + "m"
                color: Theme.text
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
            }
            StepButton {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                icon: "plus"
                onClicked: TimerService.pmSetLength(col.modelData.id, col.minutes + 1)
            }

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => TimerService.pmSetLength(col.modelData.id, col.minutes + (event.angleDelta.y > 0 ? 1 : -1))
            }
        }
    }
}
