import QtQuick
import qs.theme
import qs.services
import qs.components

// The current player with basic controls.
Block {
    id: root

    glass: true

    Cover {
        id: art
        anchors.verticalCenter: parent.verticalCenter
        width: 60; height: 60
        corner: Theme.radiusSm
        source: Players.art
    }

    Column {
        anchors { left: art.right; leftMargin: 12; right: controls.left; rightMargin: 6; verticalCenter: parent.verticalCenter }

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
    }

    Row {
        id: controls
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: 0
        visible: Players.has

        Repeater {
            model: [
                { icon: "prev", act: "prev" },
                { icon: Players.playing ? "pause" : "play", act: "toggle" },
                { icon: "next", act: "next" }
            ]
            Rectangle {
                id: btn
                required property var modelData
                width: 28; height: 28; radius: 14
                color: tap.pressed ? Theme.panelHigh : (hover.hovered ? Theme.lockPill : "transparent")

                PanelIcon { anchors.centerIn: parent; name: btn.modelData.icon; size: 16; color: Theme.text }
                HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    id: tap
                    onTapped: {
                        const p = Players.player
                        if (!p) return
                        if (btn.modelData.act === "prev") p.previous()
                        else if (btn.modelData.act === "next") p.next()
                        else p.togglePlaying()
                    }
                }
            }
        }
    }
}
