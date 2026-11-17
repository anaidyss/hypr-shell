import QtQuick
import qs.theme
import qs.components

// One-line text popup used for choosing a folder and for "Save as".
Surface {
    id: root

    property string text: ""
    property string hint: ""
    signal accepted(string text)
    signal dismissed()

    radius: Theme.radiusMd
    color: Theme.panelBase
    width: 580
    height: 74

    onVisibleChanged: {
        if (!visible) return
        input.text = root.text
        input.forceActiveFocus()
        input.selectAll()
    }

    MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.AllButtons }

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
        height: 34
        radius: Theme.radiusSm
        color: Theme.panelRaised
        border.width: 1
        border.color: input.activeFocus ? Qt.alpha(Theme.accent, 0.6) : "transparent"

        TextInput {
            id: input
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            color: Theme.text
            selectionColor: Qt.alpha(Theme.accent, 0.4)
            selectByMouse: true
            font { family: Theme.fontMono; pixelSize: 14; weight: Theme.wBold }
            onAccepted: root.accepted(text)
            Keys.onEscapePressed: root.dismissed()
        }
    }

    Text {
        anchors { left: parent.left; leftMargin: 14; bottom: parent.bottom; bottomMargin: 10 }
        text: root.hint
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
    }
}
