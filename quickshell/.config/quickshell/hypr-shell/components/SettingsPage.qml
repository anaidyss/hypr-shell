import QtQuick
import qs.theme

Flickable {
    id: root

    property string title
    default property alias content: column.data
    // The whole page body (not only the visible part), for snapshots.
    readonly property Item body: column

    contentWidth: width
    contentHeight: column.implicitHeight + 64
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    Column {
        id: column
        x: 32
        y: 28
        width: root.width - 64
        spacing: 22

        Text {
            text: root.title
            color: Theme.text
            font { family: Theme.fontUi; pixelSize: 26; weight: Theme.wStrong }
        }
    }
}
