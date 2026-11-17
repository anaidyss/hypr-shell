import QtQuick
import qs.theme
import qs.services
import qs.components

// The current player: cover, title, artist, progress and transport buttons. Clicking the cover opens the Media tab.
Block {
    id: root

    signal openMedia()

    readonly property bool playing: Players.playing

    Timer {
        running: root.visible && root.playing
        interval: 500
        repeat: true
        onTriggered: Players.refreshPosition()
    }

    Cover {
        id: art
        width: 56; height: 56
        corner: Theme.radiusSm
        source: Players.art
        dim: Players.has && !root.playing

        HoverHandler { cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.openMedia() }
    }

    Column {
        anchors { left: art.right; leftMargin: 12; right: parent.right; verticalCenter: art.verticalCenter }
        spacing: 2

        Text {
            width: parent.width
            text: Players.has ? Players.title : "Nothing playing"
            color: Players.has ? Theme.text : Theme.textDim
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
        }
        Text {
            width: parent.width
            visible: Players.has
            text: Players.artist
            color: Theme.textDim
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
        Text {
            width: parent.width
            visible: Players.has
            text: Players.has ? Players.name(Players.player) + (Players.list.length > 1 ? "  ·  " + (Players.index + 1) + "/" + Players.list.length : "") : ""
            color: Theme.textOff
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }

            HoverHandler { cursorShape: Players.list.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor }
            TapHandler { enabled: Players.list.length > 1; onTapped: Players.cycle() }
        }
    }

    Rectangle {
        y: 72
        width: parent.width
        height: 4
        radius: 2
        color: Theme.panelTrack
        opacity: Players.has ? 1 : 0.5

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, Players.ratio))
            height: parent.height
            radius: 2
            color: Theme.accent
            Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.Linear } }
        }
    }

    Row {
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
        spacing: 8
        opacity: Players.has ? 1 : 0.38
        Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }

        PanelButton {
            icon: "prev"; vertical: false; clickOpens: false
            width: 36; height: 32
            enabled: Players.has && Players.player.canGoPrevious
            onClicked: Players.player.previous()
        }
        PanelButton {
            icon: root.playing ? "pause" : "play"; vertical: false; clickOpens: false; highlight: true
            width: 44; height: 32
            enabled: Players.has && Players.player.canTogglePlaying
            onClicked: Players.player.togglePlaying()
        }
        PanelButton {
            icon: "next"; vertical: false; clickOpens: false
            width: 36; height: 32
            enabled: Players.has && Players.player.canGoNext
            onClicked: Players.player.next()
        }
    }
}
