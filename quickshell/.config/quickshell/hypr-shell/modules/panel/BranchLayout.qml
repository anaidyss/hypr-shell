import QtQuick
import qs.theme
import qs.services
import qs.components

// Layout menu: the compositor's layout, the column width of the scrolling layout, live gaps and the focused window's actions.
Item {
    id: root

    readonly property real pad: 12
    readonly property real blockExtra: 54
    readonly property bool scrolling: WinCtl.layout === "scrolling"
    // Gaps as 0..1 of their slider ranges; a drag takes over from the compositor's values until the menu is reopened.
    property real vIn: WinCtl.gapsIn / 24
    property real vOut: WinCtl.gapsOut / 48

    implicitWidth: 380
    implicitHeight: col.height + 2 * pad

    onVisibleChanged: if (visible) {
        WinCtl.refresh()
        vIn = Qt.binding(() => WinCtl.gapsIn / 24)
        vOut = Qt.binding(() => WinCtl.gapsOut / 48)
    }
    Component.onCompleted: WinCtl.refresh()

    Timer {
        id: applyGaps
        interval: 60
        onTriggered: WinCtl.setGaps(Math.round(root.vIn * 24), Math.round(root.vOut * 48))
    }

    Column {
        id: col
        x: root.pad
        y: root.pad
        width: root.width - 2 * root.pad
        spacing: Theme.gapBlock

        Block {
            width: parent.width
            height: root.blockExtra + 36 + (root.scrolling ? Theme.gapTile + 36 : 0)
            title: "Layout"
            icon: "layout"
            tone: Theme.secondaryContainer

            Column {
                width: parent.width
                spacing: Theme.gapTile

                Row {
                    spacing: 4
                    Repeater {
                        model: ["scrolling", "dwindle", "master", "monocle"]
                        WinButton {
                            required property string modelData
                            width: (col.width - 2 * Theme.padBlock - 12) / 4
                            label: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                            active: WinCtl.layout === modelData
                            onClicked: WinCtl.setLayout(modelData)
                        }
                    }
                }

                Row {
                    visible: root.scrolling
                    spacing: 4
                    Repeater {
                        model: [{ l: "1/3", f: "0.33333" }, { l: "1/2", f: "0.5" }, { l: "2/3", f: "0.66667" }, { l: "Full", f: "1.0" }]
                        WinButton {
                            required property var modelData
                            width: (col.width - 2 * Theme.padBlock - 12) / 4
                            label: modelData.l
                            onClicked: WinCtl.columnWidth(modelData.f)
                        }
                    }
                }
            }
        }

        Block {
            width: parent.width
            height: root.blockExtra + 2 * 28 + Theme.gapTile
            title: "Gaps"
            icon: "box"
            tone: Theme.tertiaryContainer

            Column {
                width: parent.width
                spacing: Theme.gapTile

                GapRow {
                    label: "Between windows"
                    max: 24
                    value: root.vIn
                    onMoved: v => { root.vIn = v; applyGaps.restart() }
                }
                GapRow {
                    label: "From the edge"
                    max: 48
                    value: root.vOut
                    onMoved: v => { root.vOut = v; applyGaps.restart() }
                }
            }
        }

        Block {
            width: parent.width
            height: root.blockExtra + 36
            title: "Focused window"
            icon: "appWindow"
            tone: Theme.accentContainer

            Row {
                spacing: 4
                Repeater {
                    model: [
                        { a: "float", l: "Float" },
                        { a: "fullscreen", l: "Full" },
                        { a: "pin", l: "Pin" },
                        { a: "center", l: "Center" },
                        { a: "close", l: "Close" }
                    ]
                    WinButton {
                        required property var modelData
                        width: (col.width - 2 * Theme.padBlock - 16) / 5
                        label: modelData.l
                        onClicked: WinCtl.windowAction(modelData.a)
                    }
                }
            }
        }
    }

    component GapRow: Item {
        id: gap
        property string label
        property real max: 24
        property real value: 0
        signal moved(real v)

        width: parent ? parent.width : 0
        height: 28

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: gap.label
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
        Text {
            id: readout
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: 44
            horizontalAlignment: Text.AlignRight
            text: Math.round(gap.value * gap.max) + " px"
            color: Theme.text
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
        }
        PanelSlider {
            anchors { left: parent.left; leftMargin: 124; right: readout.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            value: gap.value
            onMoved: v => gap.moved(v)
        }
    }
}
