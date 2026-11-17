import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.components

// The center card: clock, who is locked out and the password field.
Surface {
    id: root

    property bool isPreview: false
    property bool focused: false

    radius: Theme.radiusLg
    color: glassFill ? Theme.panelRaised : Theme.blockGlass
    borderColor: Theme.border
    glassFill: backdrop !== null && !Theme.solid
    glassTint: Theme.panelBase
    glassTintAlpha: Theme.panelAlpha

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // The card rises in once, then stays put.
    property real appear: 0
    NumberAnimation on appear { from: 0; to: 1; duration: Theme.durSlow * 2; easing.type: Theme.easing; easing.overshoot: Theme.overshoot }
    opacity: appear
    transform: Translate { y: (1 - root.appear) * 14 }

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -17
        width: parent.width - 56
        spacing: 16

        Column {
            width: parent.width
            spacing: 2

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(clock.date, "HH:mm")
                color: Theme.text
                lineHeightMode: Text.FixedHeight
                lineHeight: 92
                font { family: Theme.fontUi; pixelSize: 104; weight: Theme.wHeavy }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.locale("en_US").toString(clock.date, "dddd, d MMMM")
                color: Theme.text
                opacity: 0.7
                font { family: Theme.fontUi; pixelSize: 18; weight: Theme.wBold }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14

            Cover {
                id: avatar
                anchors.verticalCenter: parent.verticalCenter
                width: 52; height: 52
                source: SysInfo.avatar
                fallback: SysInfo.user.charAt(0).toUpperCase()
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: SysInfo.user
                    color: Theme.text
                    font { family: Theme.fontUi; pixelSize: 21; weight: Theme.wHeavy }
                }
                Text {
                    text: SysInfo.host + (SysInfo.distro !== "" ? "  ·  " + SysInfo.distro : "")
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                }
            }
        }

        // Password field: dots instead of text, the keyboard layout on the right.
        Item {
            id: fieldBox
            width: parent.width
            height: 52

        Surface {
            id: field

            width: parent.width
            height: parent.height
            radius: height / 2
            power: 2
            color: Theme.lockTile
            borderColor: LockState.messageIsError ? Qt.alpha(Theme.danger, 0.8)
                : LockState.busy ? Qt.alpha(Theme.accent, 0.8)
                : root.focused ? Theme.borderActive : Theme.border

            Behavior on borderColor { ColorAnimation { duration: Theme.durFast } }

            transform: Translate { id: shake }
            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: shake; property: "x"; to: -9; duration: 50 }
                NumberAnimation { target: shake; property: "x"; to: 9; duration: 80 }
                NumberAnimation { target: shake; property: "x"; to: -6; duration: 70 }
                NumberAnimation { target: shake; property: "x"; to: 0; duration: 60 }
            }
            Connections {
                target: LockState
                function onRejected() { shakeAnim.restart() }
            }

            Text {
                anchors.centerIn: parent
                visible: LockState.password === "" && !LockState.busy
                text: "Password"
                color: Qt.alpha(Theme.text, 0.42)
                font { family: Theme.fontUi; pixelSize: 16; weight: Theme.wBold }
            }

            // The dots glide apart as the row grows, a new one pops in, a deleted one shrinks away,
            // while PAM checks a wave runs through them and after a failure they collapse from the end.
            Item {
                id: dots

                readonly property int maxDots: 20
                readonly property int count: Math.min(LockState.dotCount, maxDots)
                // Marks of the chosen size with a 6 px gap; a long password shrinks them so the row stays inside the field.
                readonly property real size: Math.max(10, Math.min(Theme.cfg.lock.dotSize, (fieldBox.width - 150) / Math.max(1, count) - 6))
                readonly property real step: size + 6

                anchors.centerIn: parent
                width: 0; height: 0

                Repeater {
                    model: dots.maxDots

                    LockDotShape {
                        id: dot

                        required property int index
                        readonly property bool on: index < dots.count
                        property real wave: 1

                        size: dots.size
                        shape: Theme.cfg.lock.dotShape
                        x: (index - (dots.count - 1) / 2) * dots.step - width / 2
                        y: -height / 2
                        color: Theme.text
                        scale: on ? 1 : 0
                        opacity: on ? wave : 0

                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on scale {
                            SequentialAnimation {
                                PauseAnimation { duration: dot.on || LockState.busy ? 0 : Math.max(0, dots.count > 0 ? 0 : (dots.maxDots - dot.index) * 6) }
                                NumberAnimation { duration: dot.on ? 260 : 160; easing.type: dot.on ? Easing.OutBack : Easing.InCubic; easing.overshoot: 2.2 }
                            }
                        }
                        Behavior on opacity { NumberAnimation { duration: 140 } }

                        SequentialAnimation on wave {
                            running: LockState.busy && dot.on
                            loops: Animation.Infinite
                            onRunningChanged: if (!running) dot.wave = 1
                            PauseAnimation { duration: dot.index * 55 }
                            NumberAnimation { to: 0.3; duration: 240; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 240; easing.type: Easing.InOutSine }
                            PauseAnimation { duration: Math.max(0, (dots.count - dot.index) * 55 + 120) }
                        }
                    }
                }
            }

            PanelIcon {
                anchors { left: parent.left; leftMargin: 24; verticalCenter: parent.verticalCenter }
                name: LockState.busy ? "restart" : "lock"
                size: 18
                color: LockState.busy ? Theme.accent : Theme.textDim
                RotationAnimator on rotation { from: 0; to: 360; duration: 900; loops: Animation.Infinite; running: LockState.busy }
            }

            // Keyboard layout: the one thing you must know before typing.
            Rectangle {
                anchors { right: parent.right; rightMargin: 11; verticalCenter: parent.verticalCenter }
                width: 44; height: 30; radius: 15
                color: Theme.lockPill
                visible: LockState.layoutCode !== ""

                Text {
                    anchors.centerIn: parent
                    text: LockState.layoutCode
                    color: Theme.text
                    font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wHeavy; letterSpacing: 0.5 }
                }
            }
        }

            Text {
                y: field.height + 10
                width: parent.width
                height: 14
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: LockState.message !== "" ? LockState.message : (root.isPreview ? "Preview: Esc closes, the real check is used" : "")
                color: LockState.messageIsError ? Theme.danger : Theme.textDim
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }
        }

    }
}
