import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.components

// Keyboard layout OSD: a short pill with the layout code and its name, shown for a moment after a switch.
// Solid mode: a bulge of the bottom frame band (same material, its lower half behind the screen edge);
// glass: a floating island above the bottom edge, like the volume OSD.
PanelWindow {
    id: win

    required property var modelData

    readonly property bool onFocused: Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === modelData.name
    property bool shown: false
    readonly property bool showing: shown && onFocused && !LockState.showing
    readonly property bool bulge: Theme.solid && Theme.cfg.panel.railFlush
    readonly property int pillH: 56
    readonly property int pillW: Math.max(176, label.implicitWidth + 96)

    Connections {
        target: Keyboard
        function onSwitched() {
            win.shown = true
            hideTimer.restart()
        }
    }
    Timer { id: hideTimer; interval: 1200; onTriggered: win.shown = false }

    screen: modelData
    anchors.bottom: true
    margins.bottom: bulge ? 0 : 80
    implicitWidth: 320
    implicitHeight: bulge ? pillH + Theme.frameWidth : pillH + 16
    color: "transparent"
    visible: pill.opacity > 0.01
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "hs-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {}

    Surface {
        id: pill

        // Hidden: below the window (bulge) or a little lower and faded (island).
        readonly property real restY: win.bulge ? 0 : 8
        readonly property real awayY: win.bulge ? win.height : 20

        anchors.horizontalCenter: parent.horizontalCenter
        y: win.showing ? restY : awayY
        width: win.pillW
        height: win.bulge ? win.height + win.pillH / 2 : win.pillH
        radius: win.pillH / 2
        power: 2
        color: win.bulge ? Theme.panelFill : Theme.island
        borderWidth: win.bulge ? 0 : 1
        opacity: win.showing ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: win.showing ? Theme.durNormal : Theme.durFast; easing.type: Theme.easingCalm } }
        Behavior on y {
            NumberAnimation {
                duration: win.showing ? Theme.durOpen : Theme.durFast
                easing.type: win.showing ? Theme.easingOpen : Easing.InCubic
                easing.overshoot: Theme.overshoot
            }
        }

        Row {
            id: content
            anchors.horizontalCenter: parent.horizontalCenter
            y: (win.pillH - height) / 2
            spacing: 12

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 32
                radius: Theme.radiusSm
                color: Theme.accentContainer
                Text {
                    anchors.centerIn: parent
                    text: Keyboard.code
                    color: Theme.text
                    font { family: Theme.fontUi; pixelSize: 15; weight: Theme.wHeavy; letterSpacing: 0.5 }
                }
            }
            Text {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                text: Keyboard.name
                color: Theme.text
                font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
            }
        }
    }
}
