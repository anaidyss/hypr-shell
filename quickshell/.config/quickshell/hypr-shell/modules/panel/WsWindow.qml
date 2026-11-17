import QtQuick
import Quickshell.Wayland
import qs.theme
import qs.components

// One window inside a workspace plate: a live thumbnail (captured rarely), or its icon when capture is not possible.
// Click focuses it, a drag moves it to another workspace (the menu owns the gesture), the corner button closes it.
Item {
    id: win

    required property var info
    property real scaleFactor: 1
    property bool held: false

    signal clicked()
    signal closeRequested()
    signal dragStarted(real px, real py)
    signal dragMoved(real px, real py)
    signal dragEnded()

    // Streams the window for a moment to take a fresh frame; the capture context is not ready for a single-shot request right away.
    function capture() {
        if (!view || !view.captureSource) return
        view.live = true
        stopLive.restart()
    }

    Timer { id: stopLive; interval: 450; onTriggered: view.live = false }

    x: info.x * scaleFactor
    y: info.y * scaleFactor
    width: Math.max(4, info.w * scaleFactor)
    height: Math.max(4, info.h * scaleFactor)
    opacity: held ? 0.4 : 1

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm * 0.6
        color: Theme.panelPill
        border.width: info.active ? 1 : 0
        border.color: Theme.borderActive
    }

    ScreencopyView {
        id: view
        anchors.fill: parent
        captureSource: win.info.top ? win.info.top.wayland : null
        live: false
        visible: hasContent
        Component.onCompleted: win.capture()
    }

    Image {
        anchors.centerIn: parent
        visible: !view.hasContent
        width: Math.min(24, parent.width - 6, parent.height - 6)
        height: width
        source: win.info.icon
        sourceSize: Qt.size(48, 48)
        fillMode: Image.PreserveAspectFit
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSm * 0.6
        color: Theme.hoverStrong
        opacity: area.containsMouse && !win.held ? 0.5 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
    }

    MouseArea {
        id: area
        property real px: 0
        property real py: 0
        property bool dragging: false

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => { px = mouse.x; py = mouse.y; dragging = false }
        onPositionChanged: mouse => {
            if (!pressed) return
            const p = mapToItem(null, mouse.x, mouse.y)
            if (!dragging && Math.hypot(mouse.x - px, mouse.y - py) > 6) {
                dragging = true
                win.dragStarted(p.x, p.y)
            }
            if (dragging) win.dragMoved(p.x, p.y)
        }
        onReleased: mouse => {
            if (dragging) { dragging = false; win.dragEnded() }
        }
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) win.closeRequested()
            else win.clicked()
        }
    }

    Rectangle {
        id: closeBtn
        readonly property bool shown: (area.containsMouse || closeArea.containsMouse) && !win.held && win.width >= 34 && win.height >= 26
        anchors { top: parent.top; right: parent.right; margins: 3 }
        width: 16
        height: 16
        radius: 8
        visible: opacity > 0
        opacity: shown ? 1 : 0
        color: closeArea.containsMouse ? Theme.danger : Theme.panelHigh
        Behavior on opacity { NumberAnimation { duration: Theme.durFast } }

        PanelIcon { anchors.centerIn: parent; name: "close"; size: 14; color: Theme.text }
        MouseArea {
            id: closeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: win.closeRequested()
        }
    }
}
