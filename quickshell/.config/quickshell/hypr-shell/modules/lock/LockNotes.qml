import QtQuick
import qs.theme
import qs.services
import qs.components

// Notifications that arrived while the screen was locked.
Block {
    id: root

    glass: true

    readonly property var items: Toasts.unread.slice(0, 2)

    title: Toasts.unread.length > 0 ? "Missed · " + Toasts.unread.length : "Notifications"
    icon: Toasts.dnd ? "bellOff" : "bell"

    Column {
        width: parent.width
        spacing: 3

        Repeater {
            model: root.items

            Column {
                id: item
                required property var modelData
                width: parent.width

                Text {
                    width: parent.width
                    text: item.modelData.app + "  ·  " + Qt.formatTime(new Date(item.modelData.time), "HH:mm")
                    color: Theme.accent
                    elide: Text.ElideRight
                    font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wStrong }
                }
                Text {
                    width: parent.width
                    text: item.modelData.summary
                    color: Theme.text
                    elide: Text.ElideRight
                    font { family: Theme.fontUi; pixelSize: 13; weight: Theme.wBold }
                }
            }
        }
    }

    Text {
        visible: root.items.length === 0
        anchors.centerIn: parent
        text: Toasts.dnd ? "Do not disturb is on" : "Nothing new"
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
    }
}
