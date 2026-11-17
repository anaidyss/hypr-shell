import QtQuick
import Quickshell.Services.Mpris
import qs.theme
import qs.services
import qs.components

// The Media tab: the cover on the left (the hero), on the right player chips, a Track / Lyrics / EQ switch, the
// view and, under Track and Lyrics, the seek bar with the transport. Tap the cover to play or pause, scroll it to seek.
Item {
    id: root

    property bool shown: false
    readonly property int view: PanelState.mediaView

    readonly property bool playing: Players.playing
    readonly property real pad: 16

    Binding { target: Lyrics; property: "wanted"; value: root.shown && root.view !== 2 }
    Binding { target: Cava; property: "wanted"; value: root.shown && root.view === 0 }

    Timer {
        running: root.shown && root.playing
        interval: 500
        repeat: true
        onTriggered: Players.refreshPosition()
    }

    DashTile {
        id: artTile
        tone: Theme.secondaryContainer
        light: true
        width: parent.height
        height: parent.height

        Cover {
            id: cover
            anchors.centerIn: parent
            width: parent.width - 32
            height: width
            corner: Theme.radiusMd
            source: Players.art
            dim: Players.has && !root.playing
            scale: coverTap.pressed ? 0.97 : (root.playing || !Players.has ? 1 : 0.96)
            Behavior on scale { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }

            // Play or pause, shown on hover
            Rectangle {
                anchors.centerIn: parent
                width: 64; height: 64
                radius: 32
                color: Theme.panelFill
                opacity: coverHover.hovered && Players.has ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }

                PanelIcon {
                    anchors.centerIn: parent
                    name: root.playing ? "pause" : "play"
                    size: 30
                    color: Theme.text
                }
            }

            HoverHandler { id: coverHover; cursorShape: Players.has ? Qt.PointingHandCursor : Qt.ArrowCursor }
            TapHandler {
                id: coverTap
                enabled: Players.has && Players.player.canTogglePlaying
                onTapped: Players.player.togglePlaying()
            }
            WheelHandler {
                enabled: Players.canSeek
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    Players.refreshPosition()
                    const step = event.angleDelta.y > 0 ? 5 : -5
                    Players.seekTo((Players.player.position + step) / Players.player.length)
                }
            }
        }
    }

    DashTile {
        id: info
        order: 1
        x: artTile.width + Theme.gapTile
        width: parent.width - x
        height: parent.height

        // Header: player chips on the left, the view switch on the right.
        Item {
            id: header
            x: root.pad; y: root.pad
            width: info.width - 2 * root.pad
            height: 28

            Item {
                anchors { left: parent.left; right: switcher.left; rightMargin: 8; top: parent.top; bottom: parent.bottom }
                clip: true

                Row {
                    spacing: 4

                    Repeater {
                        model: Players.list

                        Rectangle {
                            id: chip
                            required property var modelData
                            readonly property bool current: modelData === Players.player

                            height: 28
                            width: chipText.implicitWidth + 32
                            radius: height / 2
                            color: current ? (Theme.solid ? Theme.accentContainer : Qt.alpha(Theme.accent, 0.16))
                                : (chipHover.hovered ? Theme.panelHigh : Theme.panelPill)
                            Behavior on color { ColorAnimation { duration: Theme.durFast } }

                            Rectangle {
                                x: 12; anchors.verticalCenter: parent.verticalCenter
                                width: 4; height: 4; radius: 2
                                color: chip.modelData.isPlaying ? Theme.accent : Theme.textOff
                            }
                            Text {
                                id: chipText
                                x: 20; anchors.verticalCenter: parent.verticalCenter
                                text: Players.name(chip.modelData)
                                color: chip.current ? Theme.text : Theme.textDim
                                font { family: Theme.fontUi; pixelSize: 12; weight: chip.current ? Theme.wStrong : Theme.wBold }
                            }

                            HoverHandler { id: chipHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Players.pick(chip.modelData) }
                        }
                    }
                }
            }

            SegmentedControl {
                id: switcher
                anchors.right: parent.right
                width: 180
                height: 28
                model: ["Track", "Lyrics", "EQ"]
                current: root.view
                onPicked: i => PanelState.mediaView = i
            }
        }

        // The view
        Item {
            id: body
            x: root.pad
            y: header.y + header.height + 12
            width: info.width - 2 * root.pad
            height: (root.view === 2 ? info.height - root.pad : seek.y - 8) - y

            MediaTrack {
                anchors.fill: parent
                opacity: root.view === 0 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
            }
            MediaLyrics {
                anchors.fill: parent
                opacity: root.view === 1 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
            }
            MediaEq {
                anchors.fill: parent
                opacity: root.view === 2 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
            }
        }

        // Seek bar, times and transport (hidden in the equalizer view)
        Item {
            id: dock
            anchors.fill: parent
            opacity: root.view === 2 ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }

            SeekBar {
                id: seek
                x: root.pad
                y: transport.y - 8 - 14 - height
                width: info.width - 2 * root.pad
                ratio: Players.ratio
                seekable: Players.canSeek
                opacity: Players.has ? 1 : 0.38
                onSeeked: r => Players.seekTo(r)
            }

            Text {
                x: root.pad; y: seek.y + seek.height
                text: Players.has && Players.player.positionSupported ? Players.clock(seek.dragging ? seek.dragRatio * Players.player.length : Players.player.position) : ""
                color: Theme.textDim
                font { family: Theme.fontMono; pixelSize: 11; weight: Theme.wBold }
            }
            Text {
                x: info.width - root.pad - width; y: seek.y + seek.height
                text: Players.has && Players.player.lengthSupported && Players.player.length > 0 ? Players.clock(Players.player.length) : ""
                color: Theme.textDim
                font { family: Theme.fontMono; pixelSize: 11; weight: Theme.wBold }
            }

            Row {
                id: transport
                anchors.horizontalCenter: parent.horizontalCenter
                y: info.height - root.pad - height
                height: 40
                spacing: 8
                opacity: Players.has ? 1 : 0.38
                Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }

                PanelButton {
                    icon: "shuffle"; vertical: false; clickOpens: false
                    width: 40; height: 40
                    highlight: Players.has && Players.player.shuffle
                    opacity: Players.has && Players.player.shuffleSupported ? 1 : 0.38
                    enabled: Players.has && Players.player.shuffleSupported
                    onClicked: Players.toggleShuffle()
                }
                PanelButton {
                    icon: "prev"; vertical: false; clickOpens: false
                    width: 40; height: 40
                    enabled: Players.has && Players.player.canGoPrevious
                    onClicked: Players.player.previous()
                }
                PanelButton {
                    icon: root.playing ? "pause" : "play"; vertical: false; clickOpens: false; highlight: true
                    iconSize: 24
                    width: 56; height: 40
                    enabled: Players.has && Players.player.canTogglePlaying
                    onClicked: Players.player.togglePlaying()
                }
                PanelButton {
                    icon: "next"; vertical: false; clickOpens: false
                    width: 40; height: 40
                    enabled: Players.has && Players.player.canGoNext
                    onClicked: Players.player.next()
                }
                PanelButton {
                    icon: Players.has && Players.player.loopState === MprisLoopState.Track ? "repeatOne" : "repeat"
                    vertical: false; clickOpens: false
                    width: 40; height: 40
                    highlight: Players.has && Players.player.loopState !== MprisLoopState.None
                    opacity: Players.has && Players.player.loopSupported ? 1 : 0.38
                    enabled: Players.has && Players.player.loopSupported
                    onClicked: Players.cycleLoop()
                }
            }
        }
    }
}
