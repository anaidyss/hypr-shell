import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services
import qs.components

// Stealth Cast overlay: a light blue veil over the live screen with a floating toolbar. Drag to
// draw a blackout rectangle; Start switches the virtual camera on with the screen + blackouts.
PanelWindow {
    id: win

    required property var modelData

    readonly property bool showing: StealthCast.active && StealthCast.monitor === modelData.name

    // Drag state for drawing a rectangle (blackout while blackoutMode is on).
    property bool blackoutMode: false
    property bool drawing: false
    property real px0: 0
    property real py0: 0
    property real mx: 0
    property real my: 0

    readonly property rect dragRect: {
        if (!drawing) return Qt.rect(0, 0, 0, 0)
        return Qt.rect(Math.min(px0, mx), Math.min(py0, my), Math.abs(mx - px0), Math.abs(my - py0))
    }

    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: showing
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "hs-stealthcast"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) StealthCast.close()
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) StealthCast.commit()
            else if (event.key === Qt.Key_B) { blackoutMode = !blackoutMode; event.accepted = true }
        }
    }

    // The blue veil.
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.accent, 0.14)
    }

    // Selection surface: drag draws a rectangle. The toolbar sits above it.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        onPressed: mouse => { drawing = true; px0 = mouse.x; py0 = mouse.y; mx = mouse.x; my = mouse.y }
        onPositionChanged: mouse => { if (drawing) { mx = mouse.x; my = mouse.y } }
        onReleased: {
            if (drawing && dragRect.width >= 4 && dragRect.height >= 4)
                StealthCast.addRegion(dragRect.x, dragRect.y, dragRect.width, dragRect.height)
            drawing = false
        }
    }

    // The rectangle being drawn, tinted by what it will become.
    Rectangle {
        visible: drawing && dragRect.width >= 2 && dragRect.height >= 2
        x: dragRect.x; y: dragRect.y; width: dragRect.width; height: dragRect.height
        radius: Theme.radiusSm
        color: Qt.alpha(blackoutMode ? Theme.danger : Theme.accent, 0.28)
        border { color: blackoutMode ? Theme.danger : Theme.accent; width: 1 }
    }

    // The recorded blackout regions stay visible while the overlay is up.
    Repeater {
        model: StealthCast.regions
        delegate: Rectangle {
            required property var modelData
            x: modelData.x; y: modelData.y; width: modelData.w; height: modelData.h
            radius: Theme.radiusSm
            color: Qt.alpha(Theme.danger, 0.30)
            border { color: Theme.danger; width: 1 }
        }
    }

    // Floating toolbar, top center.
    Surface {
        id: bar
        anchors.horizontalCenter: parent.horizontalCenter
        y: 16
        radius: Theme.radiusMd
        color: Theme.panelFill
        width: childrenRow.width + 24
        height: 48

        Row {
            id: childrenRow
            anchors.centerIn: parent
            spacing: 8

            CastTool {
                icon: "marker"
                label: "Blackout"
                active: blackoutMode
                onClicked: { blackoutMode = !blackoutMode }
            }
            CastTool {
                icon: "trash"
                label: "Clear"
                onClicked: StealthCast.clearRegions()
            }

            Item { width: 8; height: 1 }

            CastTool {
                icon: StealthCast.streaming ? "pause" : "play"
                label: StealthCast.streaming ? "Stop" : "Start"
                primary: true
                onClicked: StealthCast.streaming ? StealthCast.stop() : StealthCast.commit()
            }
        }
    }

    // A compact button inside the floating toolbar; `active` paints it with the accent.
    component CastTool: Item {
        id: tool
        property string icon
        property string label
        property bool active: false
        property bool primary: false
        signal clicked()

        width: iconItem.width + textItem.implicitWidth + (tool.icon !== "" ? 20 : 16)
        height: 32

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusSm
            color: tool.active || tool.primary ? Qt.alpha(Theme.accent, 0.22) : (hover.hovered ? Theme.panelHigh : Theme.panelRaised)
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }
        Row {
            anchors.centerIn: parent
            spacing: 6
            PanelIcon {
                id: iconItem
                visible: tool.icon !== ""
                anchors.verticalCenter: parent.verticalCenter
                name: tool.icon
                size: 16
                color: tool.active || tool.primary ? Theme.accent : Theme.text
            }
            Text {
                id: textItem
                anchors.verticalCenter: parent.verticalCenter
                text: tool.label
                color: tool.active || tool.primary ? Theme.accent : Theme.text
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }
        }
        MouseArea {
            id: hover
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tool.clicked()
        }
    }
}
