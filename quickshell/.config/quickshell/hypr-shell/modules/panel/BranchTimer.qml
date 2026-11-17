import QtQuick
import qs.theme
import qs.services
import qs.components

// Countdown, stopwatch and pomodoro behind three tabs. The page is always the same size.
Item {
    id: root

    readonly property real pad: 12
    readonly property var modes: ["countdown", "stopwatch", "pomodoro"]
    readonly property int tab: Math.max(0, modes.indexOf(TimerService.mode))
    readonly property string mode: modes[tab]

    readonly property bool running: mode === "countdown" ? TimerService.cdRunning : (mode === "stopwatch" ? TimerService.swRunning : TimerService.pmRunning)
    readonly property real total: mode === "countdown" ? TimerService.cdTotal : TimerService.pmTotal
    readonly property real remaining: mode === "countdown" ? TimerService.cdRemaining : TimerService.pmRemaining
    readonly property real progress: mode === "stopwatch" ? (TimerService.swElapsed % 60000) / 60000 : (total > 0 ? remaining / total : 0)
    readonly property string readout: mode === "stopwatch" ? TimerService.fmt(TimerService.swElapsed, true) : TimerService.fmt(remaining)
    readonly property string caption: {
        if (mode === "countdown") return TimerService.finished ? "Done" : "of " + TimerService.fmt(TimerService.cdTotal)
        if (mode === "stopwatch") return running ? "Running" : (TimerService.swElapsed > 0 ? "Paused" : "Ready")
        const phase = TimerService.pmPhase === "focus" ? "Focus" : (TimerService.pmPhase === "long" ? "Long break" : "Break")
        return phase + " · round " + (TimerService.pmRound + 1)
    }

    implicitWidth: 440
    implicitHeight: 396

    Component.onCompleted: TimerService.ack()
    onVisibleChanged: TimerService.watch = visible
    Component.onDestruction: TimerService.watch = false

    function toggle() {
        if (mode === "countdown") TimerService.cdToggle()
        else if (mode === "stopwatch") TimerService.swToggle()
        else TimerService.pmToggle()
    }

    function reset() {
        if (mode === "countdown") TimerService.cdReset()
        else if (mode === "stopwatch") TimerService.swReset()
        else TimerService.pmReset()
    }

    DashTabs {
        x: 0
        y: 6
        width: parent.width
        model: [{ icon: "timer", label: "Countdown" }, { icon: "clock", label: "Stopwatch" }, { icon: "tomato", label: "Pomodoro" }]
        current: root.tab
        onPicked: i => TimerService.setMode(root.modes[i])
    }

    Block {
        x: root.pad
        y: 54
        width: root.width - 2 * root.pad
        height: root.height - y - root.pad
        tone: Theme.secondaryContainer

        ProgressRing {
            id: ring
            x: (parent.width - width) / 2
            width: 188
            height: 188
            value: root.progress
            fillColor: TimerService.finished && root.mode !== "stopwatch" ? Theme.danger : Theme.accent

            Column {
                anchors.centerIn: parent
                spacing: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.readout
                    color: Theme.text
                    font { family: Theme.fontUi; pixelSize: root.readout.length > 5 ? 34 : (root.readout.length > 4 ? 44 : 54); weight: Theme.wHeavy }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.caption
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                }
            }

            WheelHandler {
                enabled: root.mode === "countdown"
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => TimerService.cdAdd(event.angleDelta.y > 0 ? 60000 : -60000)
            }
        }

        Row {
            y: ring.height + 12
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14
            height: 48

            RoundButton { icon: "restart"; onClicked: root.reset() }
            RoundButton { icon: root.running ? "pause" : "play"; big: true; onClicked: root.toggle() }
            RoundButton {
                icon: root.mode === "pomodoro" ? "next" : "plus"
                visible: root.mode !== "stopwatch"
                opacity: visible ? 1 : 0
                onClicked: root.mode === "pomodoro" ? TimerService.pmSkip() : TimerService.cdAdd(60000)
            }
            Item { width: 40; height: 40; visible: root.mode === "stopwatch" }
        }

        Item {
            id: bottom
            y: ring.height + 12 + 48 + 12
            width: parent.width
            height: 32

            Item {
                anchors.fill: parent
                visible: root.mode === "countdown"

                readonly property var presets: [60000, 300000, 600000, 1500000]

                SegmentedControl {
                    width: parent.width - 88
                    model: ["1 min", "5 min", "10 min", "25 min"]
                    current: parent.presets.indexOf(TimerService.cdTotal)
                    onPicked: i => TimerService.cdSet(parent.presets[i])
                }

                Rectangle {
                    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                    width: 80
                    radius: Theme.radiusSm
                    color: custom.activeFocus ? Theme.panelHigh : Theme.panelPill
                    border.width: 1
                    border.color: custom.activeFocus ? Theme.borderActive : Theme.border

                    Text {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        verticalAlignment: Text.AlignVCenter
                        visible: custom.text === "" && !custom.activeFocus
                        text: "Custom"
                        color: Theme.textOff
                        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                    }
                    TextInput {
                        id: custom
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.accentText
                        clip: true
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                        onActiveFocusChanged: { PanelState.typing = activeFocus; if (activeFocus) PanelState.typed() }
                        onTextChanged: PanelState.typed()
                        Keys.onEscapePressed: { custom.focus = false; PanelState.typing = false }
                        Keys.onReturnPressed: root.applyCustom(custom)
                        Keys.onEnterPressed: root.applyCustom(custom)
                    }
                    TapHandler { onTapped: custom.forceActiveFocus() }
                }
            }

            TimerConfig {
                anchors.fill: parent
                visible: root.mode === "pomodoro"
            }

            Text {
                anchors.centerIn: parent
                visible: root.mode === "stopwatch"
                text: "Counts up until you pause it"
                color: Theme.textDim
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }
        }
    }

    // "25" is minutes, "1:30" is minutes and seconds.
    function applyCustom(field) {
        const m = /^\s*(\d{1,3})(?::(\d{1,2}))?\s*$/.exec(field.text)
        if (m) TimerService.cdSet((+m[1] * 60 + (m[2] ? +m[2] : 0)) * 1000)
        field.text = ""
        field.focus = false
        PanelState.typing = false
    }

    component RoundButton: Item {
        id: btn
        property string icon
        property bool big: false
        signal clicked()

        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        width: big ? 48 : 40
        height: width

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: btn.big ? (tap.pressed ? Theme.accentContainer : Theme.accent) : (hover.hovered ? Theme.panelHigh : Theme.panelPill)
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }
        PanelIcon {
            anchors.centerIn: parent
            name: btn.icon
            size: btn.big ? 24 : 18
            color: btn.big ? Theme.accentText : (hover.hovered ? Theme.text : Theme.textDim)
        }
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: tap; onTapped: btn.clicked() }
    }
}
