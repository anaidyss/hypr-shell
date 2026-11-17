import QtQuick
import qs.theme
import qs.services

// Audio spectrum bars from the Cava service, mirrored around the middle (lows in the centre). Static low bars while
// nothing plays (DESIGN.md 8.4). Bars use the secondary accent (DESIGN.md 5.5: second data row on a chart).
Item {
    id: root

    property color color: Theme.accent2
    readonly property int count: Cava.bars * 2
    readonly property real gap: 4
    readonly property real barW: Math.max(2, (width - (count - 1) * gap) / count)

    Row {
        anchors.bottom: parent.bottom
        spacing: root.gap

        Repeater {
            model: root.count

            Rectangle {
                required property int index
                // Mirrored: the bass sits in the middle, the highs at both ends.
                readonly property int band: index < Cava.bars ? Cava.bars - 1 - index : index - Cava.bars
                readonly property real v: band < Cava.values.length ? Cava.values[band] : 0
                width: root.barW
                height: Math.max(4, v * root.height)
                anchors.bottom: parent.bottom
                radius: Theme.solid ? 2 : width / 2
                color: root.color
                opacity: Cava.running ? 0.55 + 0.45 * v : 0.35
            }
        }
    }
}
