import QtQuick
import qs.theme
import qs.services
import qs.components

// Track view of the Media tab: title, artist, album, the spectrum and the line being sung.
Item {
    id: root

    Column {
        id: head
        width: parent.width
        spacing: 2

        RollText {
            width: parent.width
            text: Players.has ? Players.title : "Nothing playing"
            color: Players.has ? Theme.text : Theme.textDim
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 26; weight: Theme.wStrong }
        }
        RollText {
            width: parent.width
            text: Players.has ? Players.artist : "Start a player and it shows up here"
            color: Theme.textDim
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
        }
        RollText {
            width: parent.width
            text: Players.album
            color: Theme.textOff
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
    }

    Spectrum {
        id: spectrum
        anchors { left: parent.left; right: parent.right; top: head.bottom; topMargin: 12; bottom: lyric.visible ? lyric.top : parent.bottom; bottomMargin: lyric.visible ? 8 : 0 }
        opacity: Players.has ? 1 : 0.38
        Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }

        Text {
            anchors.centerIn: parent
            visible: !Cava.installed && Players.has
            text: "Install cava to see the spectrum"
            color: Theme.textOff
            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
        }
    }

    // The line being sung (synced lyrics only).
    RollText {
        id: lyric
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: Lyrics.synced && Players.has
        text: Lyrics.currentText !== "" ? Lyrics.currentText : "…"
        color: Theme.text
        elide: Text.ElideRight
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
    }
}
