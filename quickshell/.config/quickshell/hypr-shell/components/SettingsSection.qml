import QtQuick
import qs.theme

Column {
    id: root

    property string title
    property bool expanded: true
    property real progress: expanded ? 1 : 0
    default property alias content: card.data

    width: parent ? parent.width : implicitWidth
    spacing: 8

    Behavior on progress { NumberAnimation { duration: Theme.durSlow; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }

    Item {
        width: parent.width
        height: 22

        Text {
            anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
            text: root.title.toUpperCase()
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy; letterSpacing: 1.3 }
        }

        Text {
            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
            text: "›"
            rotation: 90 * root.progress
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    Item {
        width: parent.width
        height: (card.implicitHeight + 8) * root.progress
        visible: root.progress > 0.001
        opacity: Math.max(0, (root.progress - 0.15) / 0.85)
        clip: true

        Rectangle {
            width: parent.width
            height: card.implicitHeight + 8
            radius: Theme.radiusMd
            color: Theme.tile
            border.width: 1
            border.color: Theme.border

            Column {
                id: card
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16; topMargin: 4 }
            }
        }
    }
}
