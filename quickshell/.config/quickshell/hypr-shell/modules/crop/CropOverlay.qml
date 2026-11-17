import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services

// Fullscreen crop: the chosen wallpaper shown cover-scaled; dragging moves which region is visible.
PanelWindow {
    id: win

    required property var modelData
    readonly property bool showing: Crop.active && Crop.monitor === modelData.name

    // Cover scale and the pan offset (image top-left, clamped so the image always covers the screen).
    readonly property real s: Math.max(width / Math.max(1, Crop.srcW), height / Math.max(1, Crop.srcH))
    readonly property real minX: Math.min(0, width - Crop.srcW * s)
    readonly property real minY: Math.min(0, height - Crop.srcH * s)
    property real ix: 0
    property real iy: 0

    readonly property string wallcrop: Quickshell.env("HOME") + "/.local/bin/hs-wallcrop"

    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: showing
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "hs-crop"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onShowingChanged: if (showing) { ix = minX / 2; iy = minY / 2; keys.forceActiveFocus() }

    function clampX(v) { return Math.max(minX, Math.min(0, v)) }
    function clampY(v) { return Math.max(minY, Math.min(0, v)) }

    function apply() {
        const s = win.s
        const x = Math.round(-win.ix / s)
        const y = Math.round(-win.iy / s)
        const w = Math.round(win.width / s)
        const h = Math.round(win.height / s)
        Quickshell.execDetached([win.wallcrop, Crop.path, String(x), String(y), String(w), String(h)])
        Crop.close()
    }

    function cancel() { Crop.close() }

    Connections {
        target: Crop
        function onSnapshotRequested(path) {
            if (!win.showing) return
            snap.path = path
            snap.restart()
        }
    }

    Timer {
        id: snap
        property string path: ""
        interval: 200
        onTriggered: scene.grabToImage(result => {
            if (snap.path !== "") { result.saveToFile(snap.path); snap.path = "" }
        })
    }

    Item {
        id: scene
        anchors.fill: parent

        Image {
            id: img
            x: win.ix
            y: win.iy
            width: Crop.srcW * win.s
            height: Crop.srcH * win.s
            source: Crop.path !== "" ? "file://" + Crop.path : ""
            fillMode: Image.Stretch
            asynchronous: true
            smooth: true
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - 52
            width: hint.implicitWidth + 32
            height: 30
            radius: Theme.radiusSm
            color: Qt.rgba(0, 0, 0, 0.6)
            border.width: 1
            border.color: Theme.border

            Text {
                id: hint
                anchors.centerIn: parent
                text: "Drag to choose the visible area · Enter to apply · Esc to cancel"
                color: Theme.text
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }
        }

        Item {
            id: keys
            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) { win.cancel(); event.accepted = true }
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { win.apply(); event.accepted = true }
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            property real px: 0
            property real py: 0
            property real ix0: 0
            property real iy0: 0

            cursorShape: Qt.OpenHandCursor
            onPressed: m => { px = m.x; py = m.y; ix0 = win.ix; iy0 = win.iy }
            onPositionChanged: m => {
                if (!pressed) return
                win.ix = win.clampX(ix0 + m.x - px)
                win.iy = win.clampY(iy0 + m.y - py)
            }
            onDoubleClicked: win.apply()
        }
    }
}
