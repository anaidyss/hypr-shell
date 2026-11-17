import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.theme
import qs.services
import qs.components

// A note pinned to the desktop: a small draggable card over the windows. Editing saves to the same .md file.
PanelWindow {
    id: win

    required property string modelData
    readonly property string path: modelData
    readonly property var pos: Notes.positions[path] || { x: 120, y: 90, screen: "" }

    property real px: pos.x
    property real py: pos.y

    screen: Quickshell.screens.find(s => s.name === pos.screen) || Quickshell.screens[0]
    anchors { left: true; top: true }
    margins { left: Math.round(px); top: Math.round(py) }
    implicitWidth: 260
    implicitHeight: 240
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "hs-sticky"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    function clamp(v, max) { return Math.max(0, Math.min(max, v)) }

    Component.onDestruction: if (saveTimer.running) { saveTimer.stop(); save() }

    function save() { Quickshell.execDetached(["hs-notes", "write", win.path, edit.text]) }

    Timer { id: saveTimer; interval: 600; onTriggered: win.save() }

    FileView {
        path: win.path
        printErrors: false
        onLoaded: {
            edit.loading = true
            edit.text = text()
            edit.loading = false
        }
    }

    Surface {
        anchors.fill: parent
        radius: Theme.radiusLg
        color: Theme.panelBase
        borderColor: Theme.border

        Item {
            id: head
            width: parent.width
            height: 36

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeAllCursor
                property real sx: 0
                property real sy: 0
                onPressed: mouse => { sx = mouse.x; sy = mouse.y }
                onPositionChanged: mouse => {
                    if (!pressed) return
                    win.px = win.clamp(win.px + mouse.x - sx, win.screen.width - win.width)
                    win.py = win.clamp(win.py + mouse.y - sy, win.screen.height - win.height)
                }
                onReleased: Notes.setPos(win.path, win.px, win.py)
            }

            PanelIcon { x: 14; anchors.verticalCenter: parent.verticalCenter; name: "pin"; size: 14; color: Theme.textDim }

            Text {
                anchors { left: parent.left; leftMargin: 36; right: parent.right; rightMargin: 40; verticalCenter: parent.verticalCenter }
                text: Notes.nameOf(win.path)
                color: Theme.textDim
                elide: Text.ElideRight
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }

            Rectangle {
                anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                width: 28
                height: 28
                radius: Theme.radiusSm
                color: closeHover.hovered ? Theme.panelPill : "transparent"

                PanelIcon { anchors.centerIn: parent; name: "close"; size: 14; color: Theme.textDim }
                HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Notes.unpin(win.path) }
            }
        }

        Flickable {
            anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom; leftMargin: 14; rightMargin: 14; bottomMargin: 14 }
            contentWidth: width
            contentHeight: Math.max(height, edit.contentHeight + 4)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            TextEdit {
                id: edit
                property bool loading: false
                width: parent.width
                height: Math.max(parent.height, contentHeight + 4)
                wrapMode: TextEdit.Wrap
                color: Theme.text
                selectionColor: Theme.accent
                selectedTextColor: Theme.accentText
                font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                onTextChanged: if (!loading) saveTimer.restart()
            }
        }
    }
}
