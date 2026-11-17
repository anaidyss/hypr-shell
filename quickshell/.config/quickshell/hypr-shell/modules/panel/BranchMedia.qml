import QtQuick
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    implicitWidth: 400
    implicitHeight: 220

    readonly property var player: Players.player
    readonly property real ratio: player && player.length > 0 ? Math.max(0, Math.min(1, player.position / player.length)) : 0

    function clock(s) {
        const m = Math.floor(s / 60), sec = Math.floor(s % 60)
        return m + ":" + (sec < 10 ? "0" : "") + sec
    }

    Timer {
        running: root.player !== null && root.player.isPlaying
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    Rectangle {
        anchors { fill: parent; margins: 10 }
        radius: Theme.radiusLg
        color: Theme.panelRaised
    }

    Text {
        anchors.centerIn: parent
        visible: root.player === null
        text: "Nothing playing"
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
    }

    Item {
        anchors.fill: parent
        visible: root.player !== null

        Rectangle {
            id: art
            x: 22; y: 22
            width: 130; height: 130
            radius: Theme.radiusMd
            color: Theme.panelHigh
            clip: true

            Image {
                anchors.fill: parent
                source: root.player ? root.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }
            PanelIcon {
                anchors.centerIn: parent
                name: "play"
                size: 28
                color: Theme.textDim
                visible: !root.player || root.player.trackArtUrl === ""
            }
        }

        Column {
            anchors { left: art.right; leftMargin: 18; right: parent.right; rightMargin: 22; top: art.top }
            spacing: 3

            Text {
                width: parent.width
                text: root.player ? root.player.trackTitle : ""
                color: Theme.text
                elide: Text.ElideRight
                font { family: Theme.fontUi; pixelSize: 18; weight: Theme.wStrong }
            }
            Text {
                width: parent.width
                text: root.player ? root.player.trackArtist : ""
                color: Theme.textDim
                elide: Text.ElideRight
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }
        }

        Item {
            id: progress
            anchors { left: art.right; leftMargin: 18; right: parent.right; rightMargin: 22; top: art.top; topMargin: 66 }
            height: 20

            Rectangle {
                id: track
                anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 4 }
                height: 4
                radius: 2
                color: Theme.tile
                Rectangle {
                    width: parent.width * root.ratio
                    height: parent.height
                    radius: 2
                    color: Theme.accent
                }
            }
            Text {
                anchors { left: parent.left; top: track.bottom; topMargin: 6 }
                text: root.player ? root.clock(root.player.position) : ""
                color: Theme.textDim
                font { family: Theme.fontMono; pixelSize: 11; weight: Theme.wBold }
            }
            Text {
                anchors { right: parent.right; top: track.bottom; topMargin: 6 }
                text: root.player && root.player.length > 0 ? root.clock(root.player.length) : ""
                color: Theme.textDim
                font { family: Theme.fontMono; pixelSize: 11; weight: Theme.wBold }
            }
        }

        Row {
            anchors { horizontalCenter: progress.horizontalCenter; top: art.top; topMargin: 104 }
            spacing: 14

            PanelButton {
                icon: "prev"
                vertical: false
                clickOpens: false
                width: 34; height: 34
                onClicked: { if (root.player) root.player.previous() }
            }
            PanelButton {
                icon: root.player && root.player.isPlaying ? "pause" : "play"
                vertical: false
                clickOpens: false
                highlight: true
                width: 34; height: 34
                onClicked: { if (root.player) root.player.togglePlaying() }
            }
            PanelButton {
                icon: "next"
                vertical: false
                clickOpens: false
                width: 34; height: 34
                onClicked: { if (root.player) root.player.next() }
            }
        }

        Text {
            anchors { left: parent.left; leftMargin: 22; right: parent.right; rightMargin: 22; bottom: parent.bottom; bottomMargin: 20 }
            text: root.player ? Players.name(root.player) : ""
            color: Theme.textDim
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
        }
    }
}
