import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.components

// Solid-mode OSD: a vertical slider pill that grows out of the right frame edge, centered vertically.
PanelWindow {
    id: win

    required property var modelData

    readonly property bool onFocused: Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === modelData.name
    readonly property bool showing: Theme.solid && OsdState.shown && onFocused
    readonly property int pillW: 56
    readonly property int pillH: 232
    readonly property real level: Math.max(0, Math.min(1, OsdState.muted ? 0 : OsdState.value))

    screen: modelData
    anchors.right: true
    implicitWidth: pillW + Theme.frameWidth
    implicitHeight: pillH
    color: "transparent"
    visible: Theme.solid && pill.opacity > 0.01
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "hs-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {}

    // Same material as the frame, so the pill reads as a bulge of it; its right half stays behind the screen edge.
    Surface {
        id: pill

        x: win.showing ? 0 : win.width
        width: win.width + win.pillW / 2
        height: win.pillH
        radius: win.pillW / 2
        power: 2
        color: Theme.panelFill
        opacity: win.showing ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: win.showing ? Theme.durOpen : Theme.durFast; easing.type: Theme.easingCalm } }
        Behavior on x {
            NumberAnimation {
                duration: win.showing ? Theme.durOpen : Theme.durFast
                easing.type: win.showing ? Theme.easingOpen : Theme.easing
                easing.overshoot: Theme.overshoot
            }
        }

        Item {
            width: win.pillW
            height: parent.height

            Text {
                anchors { top: parent.top; topMargin: 16; horizontalCenter: parent.horizontalCenter }
                text: OsdState.muted ? "—" : Math.round(OsdState.value * 100)
                color: Theme.text
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }

            Rectangle {
                id: groove
                anchors { top: parent.top; topMargin: 44; bottom: parent.bottom; bottomMargin: 52; horizontalCenter: parent.horizontalCenter }
                width: 12
                radius: 6
                color: Theme.panelTrack

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(parent.width, parent.height * win.level)
                    radius: parent.radius
                    color: Theme.accent
                    Behavior on height { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
                }
            }

            OsdIcon {
                anchors { bottom: parent.bottom; bottomMargin: 16; horizontalCenter: parent.horizontalCenter }
                kind: OsdState.kind
                muted: OsdState.muted
                level: OsdState.value
            }
        }
    }
}
