import QtQuick
import qs.theme
import qs.services
import qs.components

// One metric: title and icon, the current value, a note, and either a live chart or a fill bar at the bottom.
DashTile {
    id: root

    property string title
    property string icon
    property string value
    property string note
    property var series: []
    property var series2: []
    property string kind: "area"
    property real seriesMax: 0
    property real seriesMin: 0
    property real seriesFloor: 0
    property int grid: 2
    property real hotAt: 0
    property bool filled: true
    property real limit: 0
    property bool fit: false
    property real fitSpan: 0.05
    property real lineWidth: 1.6
    property bool showAverage: false
    // Formats a sample for the "peak" caption
    property var format: v => String(v)
    // 0..1 draws a bar instead of the chart; -1 hides it
    property real bar: -1

    PanelIcon {
        x: 12; y: 12
        name: root.icon
        size: 14
        color: Theme.accent2
    }
    Text {
        x: 32; y: 12
        height: 14
        verticalAlignment: Text.AlignVCenter
        text: root.title
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
    }

    Text {
        x: 12; y: 32
        text: root.value
        color: Theme.text
        font { family: Theme.fontUi; pixelSize: 26; weight: Theme.wStrong }
    }
    Text {
        x: 12; y: 62
        width: parent.width - 24
        text: root.note
        color: Theme.textDim
        elide: Text.ElideRight
        font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
    }

    Sparkline {
        id: chart
        color: Theme.accent
        visible: root.bar < 0
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 10; rightMargin: 12; bottomMargin: 10 }
        height: root.height - 94
        count: Perf.points
        tickEvery: 60 / Perf.interval
        kind: root.kind
        values: root.series
        values2: root.series2
        max: root.seriesMax
        min: root.seriesMin
        floor: root.seriesFloor
        grid: root.grid
        hotAt: root.hotAt
        filled: root.filled
        limit: root.limit
        fit: root.fit
        fitSpan: root.fitSpan
        lineWidth: root.lineWidth
        showAverage: root.showAverage
    }

    Text {
        visible: chart.visible && chart.drawn
        x: parent.width - width - 12
        y: 12
        height: 14
        verticalAlignment: Text.AlignVCenter
        text: "peak " + root.format(chart.peak)
        color: Theme.textDim
        font { family: Theme.fontMono; pixelSize: 11; weight: Theme.wBold }
    }

    Rectangle {
        visible: root.bar >= 0
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 12 }
        height: 6
        radius: 3
        color: Theme.panelPill

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.bar))
            height: parent.height
            radius: 3
            color: root.bar > 0.9 ? Theme.danger : Theme.accent
            Behavior on width { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }
        }
    }
}
