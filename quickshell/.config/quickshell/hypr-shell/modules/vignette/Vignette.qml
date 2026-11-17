import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.theme

// A faint dark falloff toward the screen edges, under the windows: the wallpaper dims smoothly where the display ends,
// so the frame and the dashboards that cling to the edges read as part of the same light.
PanelWindow {
    id: win

    required property var modelData

    screen: modelData
    anchors { left: true; right: true; top: true; bottom: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: Theme.vignetteStrength > 0.005
    WlrLayershell.namespace: "hs-vignette"
    WlrLayershell.layer: WlrLayer.Bottom
    mask: Region {}

    Shape {
        anchors.fill: parent
        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: win.width / 2
                centerY: win.height / 2
                centerRadius: Math.hypot(win.width, win.height) / 2
                focalX: centerX
                focalY: centerY
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.55; color: "transparent" }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, Theme.vignetteStrength) }
            }
            PathRectangle { x: 0; y: 0; width: win.width; height: win.height }
        }
    }
}
