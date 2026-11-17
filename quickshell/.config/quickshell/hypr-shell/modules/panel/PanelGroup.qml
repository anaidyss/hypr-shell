import QtQuick
import qs.theme

// A soft raised pill that holds a group of related controls on the left strip.
Item {
    id: root

    default property alias content: col.data
    property real padding: 5
    property real spacing: 2
    // Solid mode: a tinted container instead of the plain pill.
    property color tone: "transparent"
    property string paintRole: "pill"

    implicitWidth: 36
    implicitHeight: col.implicitHeight + 2 * padding
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMd
        color: Theme.ovPill.a > 0 ? Theme.ovPill : (Theme.solid && root.tone.a > 0 ? root.tone : Theme.panelPill)
        border.width: 1
        border.color: color
    }

    Column {
        id: col
        anchors { top: parent.top; topMargin: root.padding; horizontalCenter: parent.horizontalCenter }
        spacing: root.spacing
    }
}
