import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services
import qs.components

// A small bar at the bottom of the screen while paint mode is on: the color being painted, what is under the pointer,
// Undo, Reset all and Done. It lives in its own window so it stays while branches of the panel come and go.
PanelWindow {
    id: win

    required property var modelData

    screen: modelData
    anchors { bottom: true }
    margins { bottom: Theme.frameWidth + Theme.gapsOut }
    implicitWidth: hud.width
    implicitHeight: hud.height
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: ColorPicker.painting
    WlrLayershell.namespace: "hs-picker-hud"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Surface {
        id: hud
        width: row.implicitWidth + 24
        height: 56
        radius: Theme.radiusMd
        color: Theme.panelBase

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 12

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                radius: Theme.radiusSm
                color: ColorPicker.current === "" ? "transparent" : ColorPicker.current
                border { width: 1; color: Theme.borderActive }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: 150
                spacing: 2

                Text {
                    width: parent.width
                    text: ColorPicker.hoverRole === "" ? "Click a part to paint it" : "Paint " + ColorPicker.labelOf(ColorPicker.hoverRole).toLowerCase()
                    color: Theme.text
                    elide: Text.ElideRight
                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
                }
                Text {
                    text: ColorPicker.current + "  ·  right click clears"
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
                }
            }

            ActionButton { anchors.verticalCenter: parent.verticalCenter; icon: "restart"; text: "Undo"; enabled: ColorPicker.canUndo; onClicked: ColorPicker.undo() }
            ActionButton { anchors.verticalCenter: parent.verticalCenter; text: "Reset all"; enabled: ColorPicker.hasOverrides; onClicked: ColorPicker.resetAll() }
            ActionButton { anchors.verticalCenter: parent.verticalCenter; icon: "check"; text: "Done"; primary: true; onClicked: ColorPicker.stopPaint() }
        }
    }
}
