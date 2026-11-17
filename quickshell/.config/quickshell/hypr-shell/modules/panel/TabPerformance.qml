import QtQuick
import qs.theme
import qs.services
import qs.components

// The Performance tab: eight tiles. Samples are collected in the background, so the charts are already full on opening.
Item {
    id: root

    readonly property real gap: 8
    readonly property real tw: (width - 3 * gap) / 4
    readonly property real th: (height - gap) / 2

    function mean(a) {
        let s = 0
        for (const v of a) s += v
        return a.length > 0 ? s / a.length : 0
    }

    function percent(v) { return Math.round(v * 100) + "%" }

    PerfTile {
        order: 0
        x: 0; y: 0; width: root.tw; height: root.th
        tone: Theme.tertiaryContainer
        title: "CPU"; icon: "cpu"
        value: Math.round(Perf.cpu * 100) + "%"
        note: Perf.cores + " threads"
        kind: "blocks"
        series: Perf.cpuHist
        seriesMax: 1
        hotAt: 0.8
        grid: 0
        format: root.percent
    }
    PerfTile {
        order: 1
        x: (root.tw + root.gap); y: 0; width: root.tw; height: root.th
        tone: Theme.secondaryContainer
        title: "Memory"; icon: "memory"
        value: Perf.size(Perf.ramUsed, true)
        note: "of " + Perf.size(Perf.ramTotal, true) + (Perf.swapTotal > 0 ? " · swap " + Perf.size(Perf.swapUsed, true) : "")
        kind: "area"
        series: Perf.ramHist
        fit: true
        fitSpan: 0.04
        grid: 3
        format: root.percent
    }
    PerfTile {
        order: 2
        x: 2 * (root.tw + root.gap); y: 0; width: root.tw; height: root.th
        tone: Theme.tertiaryContainer
        title: "GPU"; icon: "chip"
        value: Perf.gpuMhz >= 0 ? Math.round(Perf.gpuMhz) + " MHz" : "—"
        note: Perf.gpuMhz >= 0 ? "of " + Math.round(Perf.gpuMax) + " MHz" : "No data"
        kind: "step"
        filled: false
        lineWidth: 2
        series: Perf.gpuHist
        seriesMax: 1
        grid: 1
        format: v => Math.round(v * Perf.gpuMax) + " MHz"
    }
    PerfTile {
        order: 3
        x: 3 * (root.tw + root.gap); y: 0; width: root.tw; height: root.th
        title: "Temperature"; icon: "thermo"
        value: Perf.temp >= 0 ? Math.round(Perf.temp) + "°C" : "—"
        note: Perf.temp >= 0 ? "CPU package · hot above 85°" : "No sensor"
        kind: "dots"
        series: Perf.tempHist
        seriesMin: 20
        seriesMax: 100
        limit: 85
        grid: 0
        format: v => Math.round(v) + "°C"
    }

    PerfTile {
        order: 1
        x: 0; y: root.th + root.gap; width: root.tw; height: root.th
        tone: Theme.secondaryContainer
        title: "Network"; icon: "wifi"
        value: "↓ " + Perf.rate(Perf.netDown)
        note: "↑ " + Perf.rate(Perf.netUp)
        kind: "mirror"
        series: Perf.downHist
        series2: Perf.upHist
        seriesFloor: 50000
        grid: 0
        format: Perf.rate
    }
    PerfTile {
        order: 2
        x: (root.tw + root.gap); y: root.th + root.gap; width: root.tw; height: root.th
        tone: Theme.tertiaryContainer
        title: "Power"; icon: "battery"
        value: Perf.hasBattery ? Perf.watts.toFixed(1) + " W" : "AC"
        note: Perf.hasBattery ? Perf.batteryPct + "% · " + Perf.batteryStatus + " · avg " + root.mean(Perf.wattHist).toFixed(1) + " W" : "No battery"
        kind: "line"
        showAverage: true
        series: Perf.wattHist
        seriesFloor: 15
        grid: 0
        lineWidth: 2.4
        format: v => v.toFixed(1) + " W"
    }
    PerfTile {
        order: 3
        x: 2 * (root.tw + root.gap); y: root.th + root.gap; width: root.tw; height: root.th
        tone: Theme.secondaryContainer
        title: "Disk"; icon: "disk"
        value: Perf.size(Perf.diskUsed)
        note: "of " + Perf.size(Perf.diskTotal) + " · " + Math.round(Perf.disk * 100) + "% used"
        bar: Perf.disk
    }

    DashTile {
        order: 4
        x: 3 * (root.tw + root.gap); y: root.th + root.gap; width: root.tw; height: root.th

        PanelIcon { x: 12; y: 12; name: "pulse"; size: 14; color: Theme.textDim }
        Text {
            x: 32; y: 12; height: 14
            verticalAlignment: Text.AlignVCenter
            text: "Busiest"
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }

        Column {
            x: 12; y: 36
            width: parent.width - 24
            spacing: 8

            Repeater {
                model: Perf.procs

                Item {
                    required property var modelData
                    width: parent.width
                    height: 22

                    Text {
                        anchors { left: parent.left; right: share.left; rightMargin: 6 }
                        text: modelData.name
                        color: Theme.text
                        elide: Text.ElideRight
                        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                    }
                    Text {
                        id: share
                        anchors.right: parent.right
                        text: Math.round(modelData.cpu * 100) + "%"
                        color: Theme.textDim
                        font { family: Theme.fontMono; pixelSize: 11; weight: Theme.wBold }
                    }
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 3
                        radius: 1.5
                        color: Theme.panelPill
                        Rectangle {
                            width: parent.width * Math.max(0.02, Math.min(1, modelData.cpu))
                            height: parent.height
                            radius: 1.5
                            color: Theme.accent
                        }
                    }
                }
            }
        }
    }
}
