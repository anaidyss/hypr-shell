import QtQuick
import qs.theme

// A row of equal choices; the picked one sits on a filled pill.
Item {
    id: root

    property var model: []
    property int current: 0
    signal picked(int index)

    implicitHeight: 32

    Row {
        anchors.fill: parent
        spacing: Theme.gapTile

        Repeater {
            model: root.model

            Item {
                id: seg
                required property string modelData
                required property int index
                readonly property bool active: index === root.current

                width: (root.width - (root.model.length - 1) * Theme.gapTile) / root.model.length
                height: root.height

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusSm
                    color: seg.active ? (Theme.solid ? Theme.accentContainer : Qt.alpha(Theme.accent, 0.16))
                        : (hover.hovered ? Theme.panelHigh : Theme.panelPill)
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                }
                Text {
                    anchors.centerIn: parent
                    width: parent.width - 8
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: seg.modelData
                    color: seg.active ? Theme.text : Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 12; weight: seg.active ? Theme.wStrong : Theme.wBold }
                }

                HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.picked(seg.index) }
            }
        }
    }
}
