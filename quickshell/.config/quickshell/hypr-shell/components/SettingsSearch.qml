import QtQuick
import qs.theme
import qs.services

Item {
    id: root

    readonly property string query: input.text
    readonly property var results: SettingsSchema.search(query)
    property int current: 0
    signal picked(var item)

    implicitHeight: 34

    function focusField() { input.forceActiveFocus(); input.selectAll() }
    function clear() { input.text = ""; input.focus = false }

    onResultsChanged: current = 0

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm
        color: Theme.tile
        border.width: 1
        border.color: input.activeFocus ? Qt.alpha(Theme.accent, 0.6) : Theme.border
        Behavior on border.color { ColorAnimation { duration: Theme.durFast } }

        TextInput {
            id: input
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentText
            clip: true
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }

            Keys.onDownPressed: root.current = Math.min(root.results.length - 1, root.current + 1)
            Keys.onUpPressed: root.current = Math.max(0, root.current - 1)
            Keys.onReturnPressed: if (root.results.length > 0) root.picked(root.results[root.current])
            Keys.onEscapePressed: event => { if (text !== "") root.clear(); else event.accepted = false }
        }

        Text {
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            visible: input.text === "" && !input.activeFocus
            text: "Search settings"
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
        }
    }
}
