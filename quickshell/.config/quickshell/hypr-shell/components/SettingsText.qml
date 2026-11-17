import QtQuick
import qs.theme

Item {
    id: root

    property string title
    property string value
    property bool allowEmpty: false
    property string placeholder: ""
    signal edited(string v)

    width: parent ? parent.width : implicitWidth
    implicitHeight: 52

    Text {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        text: root.title
        color: Theme.text
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
    }

    Rectangle {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: 260
        height: 34
        radius: Theme.radiusSm
        color: Theme.tile
        border.width: 1
        border.color: input.activeFocus ? Qt.alpha(Theme.accent, 0.6) : Theme.border

        TextInput {
            id: input
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            verticalAlignment: TextInput.AlignVCenter
            text: root.value
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentText
            clip: true
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
            onEditingFinished: if ((root.allowEmpty || text.trim() !== "") && text.trim() !== root.value) root.edited(text.trim())

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text === "" && root.placeholder !== ""
                text: root.placeholder
                color: Theme.textOff
                font: input.font
            }
        }
    }
}
