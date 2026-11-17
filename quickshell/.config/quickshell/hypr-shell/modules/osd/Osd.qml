import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.components

PanelWindow {
    id: win

    required property var modelData

    readonly property bool onFocused: Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === modelData.name
    readonly property bool showing: !Theme.solid && OsdState.shown && onFocused

    screen: modelData
    anchors.bottom: true
    margins.bottom: 80
    implicitWidth: 260
    implicitHeight: 52
    color: "transparent"
    visible: pill.opacity > 0.01
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "hs-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {}

    Surface {
        id: pill

        anchors.horizontalCenter: parent.horizontalCenter
        y: win.showing ? 4 : 12
        width: 224
        height: 44
        radius: height / 2
        power: 2
        color: Theme.island
        opacity: win.showing ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easingCalm } }
        Behavior on y { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }

        OsdIcon {
            anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
            kind: OsdState.kind
            muted: OsdState.muted
            level: OsdState.value
        }

        Rectangle {
            id: track
            anchors { left: parent.left; leftMargin: 50; right: parent.right; rightMargin: 56; verticalCenter: parent.verticalCenter }
            height: 5
            radius: 2.5
            color: Theme.panelTrack

            Rectangle {
                width: track.width * Math.max(0, Math.min(1, OsdState.muted ? 0 : OsdState.value))
                height: parent.height
                radius: parent.radius
                color: Theme.accent
                Behavior on width { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
            }
        }

        Text {
            anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
            width: 30
            horizontalAlignment: Text.AlignRight
            text: OsdState.muted ? "—" : Math.round(OsdState.value * 100)
            color: Theme.text
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
    }
}
