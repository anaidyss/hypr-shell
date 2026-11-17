import QtQuick
import qs.theme
import qs.services

// A one-line text field for panel branches: pill at rest, border on focus (rule 7.5), placeholder in textOff.
// While focused it holds the panel keyboard (PanelState.typing); Enter submits, Esc gives the keyboard back.
Item {
    id: root

    property alias text: input.text
    property string placeholder
    property int maximumLength: 64
    property bool error: false
    property real radius: Theme.radiusSm
    readonly property bool focused: input.activeFocus
    signal accepted()
    signal escaped()

    implicitWidth: 160
    implicitHeight: 32

    function focusField() { input.forceActiveFocus(); input.selectAll() }
    function release() { input.focus = false; PanelState.typing = false }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: input.activeFocus ? Theme.panelHigh : Theme.panelPill
        border.width: 1
        border.color: root.error ? Theme.danger : input.activeFocus ? Theme.borderActive : Theme.border
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    Text {
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        verticalAlignment: Text.AlignVCenter
        visible: input.text === ""
        text: root.placeholder
        elide: Text.ElideRight
        color: Theme.textOff
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
    }

    TextInput {
        id: input
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.accentText
        selectByMouse: true
        clip: true
        maximumLength: root.maximumLength
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        onActiveFocusChanged: PanelState.typing = activeFocus
        onTextChanged: PanelState.typed()
        Keys.onReturnPressed: root.accepted()
        Keys.onEnterPressed: root.accepted()
        Keys.onEscapePressed: { root.release(); root.escaped() }
    }

    HoverHandler { cursorShape: Qt.IBeamCursor }
    TapHandler { onTapped: input.forceActiveFocus() }
}
