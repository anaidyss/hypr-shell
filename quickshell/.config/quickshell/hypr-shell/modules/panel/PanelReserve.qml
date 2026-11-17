import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme

// Invisible strip that reserves space along one screen edge so windows do not go under the panel or the frame.
PanelWindow {
    id: win

    required property var modelData
    property string edge: "left"

    readonly property bool frame: Theme.cfg.panel.railFlush
    readonly property real size: {
        if (frame) return edge === "left" ? Theme.railWidth : Theme.frameWidth
        if (edge === "left") return Theme.gapsOut + Theme.railWidth
        if (edge === "bottom") return Theme.gapsOut + 48
        return 0
    }
    readonly property bool vertical: edge === "left" || edge === "right"

    screen: modelData
    anchors {
        left: edge !== "right"
        right: edge !== "left"
        top: edge !== "bottom"
        bottom: edge !== "top"
    }
    implicitWidth: vertical ? size : 1
    implicitHeight: vertical ? 1 : size
    visible: size > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: size
    WlrLayershell.namespace: "hs-reserve"
    WlrLayershell.layer: WlrLayer.Bottom
    mask: Region {}
}
