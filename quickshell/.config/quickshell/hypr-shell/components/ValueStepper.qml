import QtQuick
import qs.theme

// A caption, a value and two buttons (minus, plus). A wheel over the value steps too.
Item {
    id: root

    property string label
    property string value
    signal step(int direction)

    implicitHeight: 32

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
    }

    Row {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: Theme.gapTile

        StepButton { icon: "minus"; onClicked: root.step(-1) }
        Text {
            width: 52
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            text: root.value
            color: Theme.text
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
        }
        StepButton { icon: "plus"; onClicked: root.step(1) }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => root.step(event.angleDelta.y > 0 ? 1 : -1)
    }
}
