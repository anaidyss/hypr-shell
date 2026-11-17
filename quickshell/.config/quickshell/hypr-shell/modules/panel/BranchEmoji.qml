import QtQuick
import qs.theme
import qs.services
import qs.components

// Emoji menu of the strip: search (English or Russian), categories and the recently used; a click copies the
// emoji (and types it into the previous window when `wtype` is installed).
Item {
    id: root

    implicitWidth: 392
    implicitHeight: 404

    // -1 is "recent", 0.. are the groups.
    property int group: Emoji.recent.length > 0 ? -1 : 0
    property string query: ""
    property string hovered: ""

    readonly property var items: Emoji.view(group, query)

    Block {
        anchors { fill: parent; margins: 12 }
        title: "Emoji"
        icon: "smile"
        tone: Theme.secondaryContainer

        Column {
            anchors.fill: parent
            spacing: Theme.gapsIn

            Surface {
                width: parent.width
                height: 36
                radius: Theme.radiusLg
                color: Theme.panelPill
                borderColor: input.activeFocus ? Theme.borderActive : Theme.border

                PanelIcon { x: 12; anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 16; color: Theme.textDim }

                Text {
                    anchors { left: parent.left; leftMargin: 38; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    visible: input.text === ""
                    text: "Search emoji"
                    color: Theme.textOff
                    font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                }

                TextInput {
                    id: input
                    anchors { left: parent.left; leftMargin: 38; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    height: 28
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentText
                    clip: true
                    font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                    onTextChanged: { root.query = text; PanelState.typed() }
                    Keys.onEscapePressed: PanelState.dismiss("emoji")
                    Keys.onReturnPressed: if (root.items.length > 0) Emoji.pick(root.items[0][0])
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    onPressed: mouse => { PanelState.typing = true; PanelState.typed(); input.forceActiveFocus(); mouse.accepted = false }
                }
            }

            Row {
                id: tabs
                width: parent.width
                height: 32
                spacing: 2
                opacity: root.query === "" ? 1 : Theme.disabledOpacity

                Repeater {
                    model: [{ icon: "clock", i: -1 }].concat(Emoji.groups.map((g, i) => ({ glyph: g.icon, i: i })))

                    Item {
                        id: tab
                        required property var modelData
                        readonly property bool on: root.query === "" && root.group === modelData.i

                        width: (tabs.width - 2 * 9) / 10
                        height: tabs.height

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radiusSm
                            color: tab.on ? Theme.accentContainer : (tabHover.hovered ? Theme.panelHigh : "transparent")
                            Behavior on color { ColorAnimation { duration: Theme.durFast } }
                        }
                        PanelIcon {
                            anchors.centerIn: parent
                            visible: tab.modelData.glyph === undefined
                            name: "clock"
                            size: 16
                            color: tab.on ? Theme.text : Theme.textDim
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: tab.modelData.glyph !== undefined
                            text: tab.modelData.glyph || ""
                            font { family: "Noto Color Emoji"; pixelSize: 18 }
                        }

                        HoverHandler { id: tabHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: { input.text = ""; root.group = tab.modelData.i } }
                    }
                }
            }

            GridView {
                id: grid
                width: parent.width
                height: parent.height - 36 - 32 - 24 - 3 * Theme.gapsIn
                cellWidth: width / 9
                cellHeight: 38
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.items

                delegate: Item {
                    id: cell
                    required property var modelData
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors { fill: parent; margins: 1 }
                        radius: Theme.radiusSm
                        color: cellHover.hovered ? Theme.panelHigh : "transparent"
                    }
                    Text {
                        anchors.centerIn: parent
                        text: cell.modelData[0]
                        font { family: "Noto Color Emoji"; pixelSize: 26 }
                    }

                    HoverHandler {
                        id: cellHover
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: if (hovered) root.hovered = cell.modelData[1]
                    }
                    TapHandler { onTapped: Emoji.pick(cell.modelData[0]) }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.items.length === 0
                    text: !Emoji.loaded ? "Loading…" : (root.query !== "" ? "Nothing found" : "Nothing used yet")
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                }
            }

            Text {
                width: parent.width
                height: 24
                verticalAlignment: Text.AlignVCenter
                text: root.hovered !== "" ? root.hovered : "Click to copy"
                color: Theme.textDim
                elide: Text.ElideRight
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }
        }
    }
}
