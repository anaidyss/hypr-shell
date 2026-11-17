import QtQuick
import QtQuick.Effects
import Quickshell
import qs.theme
import qs.services
import qs.components

// The lock screen of one display: blurred wallpaper, the login card in the middle and info blocks on both sides.
FocusScope {
    id: root

    property bool isPreview: false

    readonly property bool dimmed: LockState.dimmed

    focus: true
    Component.onCompleted: { forceActiveFocus(); Weather.ensure() }

    Rectangle { anchors.fill: parent; color: "black" }

    Image {
        id: wall
        anchors.fill: parent
        visible: false
        asynchronous: true
        source: LockState.wallpaper !== "" ? "file://" + LockState.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(Math.max(640, root.width), Math.max(400, root.height))
    }

    // A strongly blurred copy of the background under the plain one: the frosted blocks take their glass from it.
    MultiEffect {
        id: frostFx
        anchors.fill: parent
        source: wall
        opacity: wall.status === Image.Ready ? 1 : 0
        blurEnabled: true
        blurMax: 24
        blur: 1
        brightness: 0.05
    }

    MultiEffect {
        id: wallFx
        anchors.fill: parent
        source: wall
        opacity: wall.status === Image.Ready ? 1 : 0
        blurEnabled: true
        blurMax: 64
        blur: Theme.lockBlur
        saturation: 0
        brightness: root.dimmed ? -0.9 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durSlow * 2; easing.type: Theme.easingCalm } }
        Behavior on brightness { NumberAnimation { duration: 1200; easing.type: Theme.easingCalm } }
    }

    // Any movement or key wakes the screen from the OLED dimming.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: LockState.markActive()
        onPressed: { LockState.markActive(); root.forceActiveFocus() }
    }

    Keys.onPressed: event => {
        LockState.markActive()
        const mods = event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) LockState.submit()
        else if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier) LockState.clear()
            else LockState.backspace()
        }
        else if (event.key === Qt.Key_Escape) {
            if (LockState.password !== "") LockState.clear()
            else if (root.isPreview) LockState.preview = false
        }
        else if (event.key === Qt.Key_U && (event.modifiers & Qt.ControlModifier)) LockState.clear()
        else if (!mods && event.text.length === 1 && event.text.charCodeAt(0) >= 32) { LockState.noteTyped(event.text); LockState.type(event.text) }
        else return
        event.accepted = true
    }

    Item {
        id: stage

        readonly property int blockW: 300
        readonly property int gap: 14

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: LockState.shift.x
        anchors.verticalCenterOffset: LockState.shift.y
        width: blockW * 2 + 460 + gap * 2
        height: 432
        scale: Math.min(1, (root.width - 60) / width, (root.height - 60) / height)
        opacity: root.dimmed ? 0.3 : 1

        Behavior on anchors.horizontalCenterOffset { NumberAnimation { duration: 2000; easing.type: Easing.InOutSine } }
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 2000; easing.type: Easing.InOutSine } }
        Behavior on opacity { NumberAnimation { duration: 1200; easing.type: Theme.easingCalm } }

        Column {
            x: 0
            width: stage.blockW
            spacing: stage.gap

            WeatherBlock { glass: true; backdrop: frostFx; width: parent.width; height: 270 }

            Row {
                spacing: stage.gap

                LockEvents { backdrop: frostFx; width: stage.blockW - controls.width - stage.gap; height: 148 }
                ControlsBlock { id: controls; glass: true; backdrop: frostFx; width: 104; height: 148 }
            }
        }

        LockCard {
            x: stage.blockW + stage.gap
            width: 460
            height: stage.height
            isPreview: root.isPreview
            focused: root.activeFocus
            backdrop: frostFx
        }

        Column {
            x: stage.blockW + 460 + stage.gap * 2
            width: stage.blockW
            spacing: stage.gap

            LockStatus { backdrop: frostFx; width: parent.width; height: 162 }
            LockNotes { backdrop: frostFx; width: parent.width; height: 134 }
            LockMedia { backdrop: frostFx; width: parent.width; height: 108 }
        }
    }

    Connections {
        target: LockState
        function onSnapshotRequested(path) {
            if (root.isPreview && root.visible && root.width > 0) root.grabToImage(r => r.saveToFile(path))
        }
    }
}
