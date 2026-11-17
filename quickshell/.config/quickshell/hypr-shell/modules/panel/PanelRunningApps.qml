import QtQuick
import qs.theme
import qs.components

// The app dock collapsed into a small pill: pinned apps on top, open (running) apps below.
// Collapsed it is a single stack tile with a badge for the number of running apps; hovering expands the list.
Item {
    id: root

    readonly property int count: dock.items.filter(i => i.windows.length > 0).length
    readonly property bool open: hov.hovered

    readonly property real pad: 5
    readonly property real chipH: 32
    readonly property real gap: 3

    width: 36
    implicitWidth: 36
    clip: true
    readonly property bool wanted: dock.items.length > 0
    visible: wanted
    implicitHeight: pad * 2 + chipH + (open ? gap + dock.implicitHeight : 0)
    Behavior on implicitHeight { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMd
        color: Theme.solid ? Theme.tertiaryContainer : Theme.panelPill
        border.width: 1
        border.color: color
    }

    Column {
        anchors { top: parent.top; topMargin: root.pad; horizontalCenter: parent.horizontalCenter }
        spacing: root.gap

        // Collapsed chip: a stack glyph with a count badge in the corner.
        Item {
            id: chip
            width: chipH
            height: chipH

            PanelIcon {
                anchors.centerIn: parent
                name: "layers"
                size: 18
                color: root.open ? Theme.text : Theme.textDim
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
            }

            Rectangle {
                visible: count > 0
                x: chip.width - 16 + 3
                y: -1
                width: count > 9 ? 18 : 16
                height: 16
                radius: 8
                color: Theme.accent
                Text {
                    anchors.centerIn: parent
                    text: count > 9 ? "9+" : count
                    color: Theme.accentText
                    font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy }
                }
            }
        }

        PanelDock {
            id: dock
            vertical: true
        }
    }

    HoverHandler { id: hov }
}