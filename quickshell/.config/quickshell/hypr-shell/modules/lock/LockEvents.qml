import QtQuick
import qs.theme
import qs.services
import qs.components

// The next calendar events.
Block {
    id: root

    glass: true

    property date now: new Date()
    title: "Up next"
    icon: "clock"

    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.now = new Date() }

    readonly property var items: Events.upcoming(3, root.now)

    Column {
        width: parent.width
        spacing: 2

        Repeater {
            model: root.items

            Column {
                id: row
                required property var modelData
                width: parent.width
                height: 30

                Text {
                    width: parent.width
                    text: Events.whenLabel(row.modelData, root.now)
                    color: Theme.accent
                    elide: Text.ElideRight
                    font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wStrong }
                }
                Text {
                    width: parent.width
                    text: row.modelData.title
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
        text: "Nothing planned"
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
    }
}
