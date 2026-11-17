import QtQuick
import qs.theme

// A small status item: icon and a one-line label; dimmed when `on` is false.
Row {
    id: root

    property string icon
    property string label
    property bool on: true

    height: 20
    spacing: 6

    PanelIcon { anchors.verticalCenter: parent.verticalCenter; name: root.icon; size: 16; color: root.on ? Theme.text : Theme.textDim }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: root.width - 24
        text: root.label
        color: root.on ? Theme.text : Theme.textDim
        elide: Text.ElideRight
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
    }
}
