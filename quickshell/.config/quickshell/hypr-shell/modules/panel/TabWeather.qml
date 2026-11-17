import QtQuick
import QtQuick.Shapes
import qs.theme
import qs.services
import qs.components

// The Weather tab: now, the details, the next 24 hours and the coming days. Details a source does not give are left out.
Item {
    id: root

    readonly property real gap: 8
    readonly property bool ok: Weather.has
    readonly property var today: Weather.daily.length > 0 ? Weather.daily[0] : null
    property real now: Date.now()

    onVisibleChanged: if (visible) { now = Date.now(); Weather.ensure() }

    Timer { interval: 30000; repeat: true; running: root.visible; onTriggered: root.now = Date.now() }

    readonly property string status: {
        if (Weather.loading) return "Updating…"
        if (Weather.error !== "") return Weather.error
        const m = Math.max(0, Math.floor((now - Weather.updatedAt) / 60000))
        if (m < 1) return "Updated just now"
        return "Updated " + (m < 60 ? m + " min" : Math.floor(m / 60) + " h") + " ago"
    }

    function uvText(v) { return v < 3 ? "Low" : v < 6 ? "Moderate" : v < 8 ? "High" : v < 11 ? "Very high" : "Extreme" }

    readonly property var facts: {
        if (!ok) return []
        const d = Weather.data
        const rows = [
            ["Feels like", d.feels, Weather.deg(d.feels)],
            ["Humidity", d.humidity, Weather.percent(d.humidity)],
            ["Wind", d.wind, Weather.wind(d.wind)],
            ["Pressure", d.pressure, Weather.pressure(d.pressure)],
            ["Sunrise", d.sunrise, d.sunrise],
            ["Sunset", d.sunset, d.sunset],
            ["Precipitation", d.precip, Weather.rain(d.precip)],
            ["UV index", d.uv, d.uv === null || d.uv === undefined ? "" : d.uv.toFixed(d.uv < 10 ? 1 : 0) + " · " + uvText(d.uv)]
        ]
        return rows.filter(r => r[1] !== null && r[1] !== undefined).map(r => ({ label: r[0], value: r[2] }))
    }

    // Smooth line through the points
    function curve(pts) {
        if (pts.length < 2) return ""
        let d = "M " + pts[0].x + " " + pts[0].y
        for (let i = 0; i < pts.length - 1; i++) {
            const p0 = pts[Math.max(0, i - 1)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[Math.min(pts.length - 1, i + 2)]
            d += " C " + (p1.x + (p2.x - p0.x) / 6) + " " + (p1.y + (p2.y - p0.y) / 6)
                + " " + (p2.x - (p3.x - p1.x) / 6) + " " + (p2.y - (p3.y - p1.y) / 6) + " " + p2.x + " " + p2.y
        }
        return d
    }

    // Now
    DashTile {
        id: hero
        tone: Theme.tertiaryContainer
        light: true
        order: 0
        x: 0; y: 0
        width: 250
        height: 128

        PanelIcon {
            x: 16; y: 16
            name: Weather.icon
            size: 52
            color: root.ok ? hero.fgAccent : hero.fgDim
        }
        RollText {
            x: 82; y: 10
            width: parent.width - x - 12
            text: root.ok ? Weather.deg(Weather.data.temp) : (Weather.loading ? "…" : "—")
            color: hero.fg
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 38; weight: Theme.wStrong }
        }
        Text {
            x: 16; y: 76
            width: parent.width - 32
            text: root.ok ? Weather.text + (root.today ? "  ·  H " + Weather.deg(root.today.max) + "  L " + Weather.deg(root.today.min) : "") : (Weather.loading ? "Loading" : "No data")
            color: hero.fg
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
        Text {
            x: 16; y: 96
            width: parent.width - 32
            text: (root.ok ? Weather.place + "  ·  " : "") + root.status
            color: Weather.error !== "" ? Theme.danger : hero.fgDim
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
        }

        HoverHandler { cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: Weather.refresh() }
    }

    // Details
    DashTile {
        order: 1
        x: hero.width + root.gap; y: 0
        width: root.width - x
        height: hero.height

        Flow {
            id: grid
            readonly property real cell: width / 4
            x: 12
            y: (parent.height - Math.ceil(root.facts.length / 4) * 56) / 2
            width: parent.width - 24

            Repeater {
                model: root.facts

                Column {
                    required property var modelData
                    width: grid.cell
                    height: 56
                    spacing: 3
                    topPadding: 8

                    Text {
                        text: modelData.label
                        color: Theme.textDim
                        font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
                    }
                    Text {
                        width: parent.width - 6
                        text: modelData.value
                        color: Theme.text
                        elide: Text.ElideRight
                        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !root.ok
            text: Weather.loading ? "Loading weather…" : "Set a city in Settings to see the weather"
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
    }

    // Next 24 hours
    DashTile {
        id: hours
        tone: Theme.secondaryContainer
        order: 2
        x: 0; y: hero.height + root.gap
        width: root.width
        height: 112

        readonly property var list: Weather.hourly
        readonly property real cw: (width - 24) / 8
        readonly property real lo: {
            let m = 1e9
            for (const h of list) if (h.temp < m) m = h.temp
            return m
        }
        readonly property real hi: {
            let m = -1e9
            for (const h of list) if (h.temp > m) m = h.temp
            return m
        }
        function yOf(t) { return hi - lo < 1 ? 80 : 90 - (t - lo) / (hi - lo) * 20 }
        readonly property var points: list.map((h, i) => ({ x: 12 + cw * (i + 0.5), y: yOf(h.temp) }))

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Qt.alpha(Theme.accent, 0.55)
                strokeWidth: 1.6
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathSvg { path: root.curve(hours.points) }
            }
        }

        Repeater {
            model: hours.list

            Item {
                id: slot
                required property var modelData
                required property int index
                x: 12 + hours.cw * index
                width: hours.cw
                height: hours.height

                Text {
                    y: 9
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: slot.index === 0 ? "Now" : slot.modelData.t.slice(11, 16)
                    color: slot.index === 0 ? Theme.accent : Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 11; weight: slot.index === 0 ? Theme.wStrong : Theme.wBold }
                }
                PanelIcon {
                    y: 25
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: Weather.iconFor(slot.modelData.cond, slot.modelData.isDay)
                    size: 20
                    color: Theme.text
                }
                Text {
                    y: 49
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: Weather.deg(slot.modelData.temp)
                    color: Theme.text
                    font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
                }
                Rectangle {
                    width: slot.index === 0 ? 7 : 5
                    height: width
                    radius: width / 2
                    x: parent.width / 2 - width / 2
                    y: hours.yOf(slot.modelData.temp) - height / 2
                    color: slot.index === 0 ? Theme.accent : Theme.panelHigh
                    border.width: 1.5
                    border.color: Theme.accent
                }
                Text {
                    y: 95
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    visible: slot.modelData.pop !== null && slot.modelData.pop !== undefined && slot.modelData.pop >= 5
                    text: Weather.percent(slot.modelData.pop)
                    color: slot.modelData.pop >= 30 ? Theme.accent : Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
                }
            }
        }
    }

    // Coming days
    DashTile {
        id: days
        order: 3
        x: 0; y: hours.y + hours.height + root.gap
        width: root.width
        height: root.height - y

        readonly property var list: Weather.daily.slice(0, 5)
        readonly property real cw: (width - 24) / Math.max(1, list.length)

        Repeater {
            model: days.list

            Item {
                id: day
                required property var modelData
                required property int index
                x: 12 + days.cw * index
                width: days.cw
                height: days.height

                Rectangle {
                    visible: day.index > 0
                    x: 0; y: 14
                    width: 1
                    height: parent.height - 28
                    color: Theme.separator
                }
                Text {
                    y: 9
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: day.index === 0 ? "Today" : Weather.weekday(day.modelData.date)
                    color: day.index === 0 ? Theme.accent : Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 11; weight: day.index === 0 ? Theme.wStrong : Theme.wBold }
                }
                PanelIcon {
                    y: 26
                    x: parent.width / 2 - 28 - 4
                    name: Weather.iconFor(day.modelData.cond, true)
                    size: 20
                    color: Theme.text
                }
                Column {
                    x: parent.width / 2 - 2
                    y: 24
                    Text {
                        text: Weather.deg(day.modelData.max)
                        color: Theme.text
                        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
                    }
                    Text {
                        text: Weather.deg(day.modelData.min)
                        color: Theme.textDim
                        font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
                    }
                }
                Text {
                    y: 62
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    visible: day.modelData.pop !== null && day.modelData.pop !== undefined && day.modelData.pop >= 5
                    text: Weather.percent(day.modelData.pop)
                    color: day.modelData.pop >= 30 ? Theme.accent : Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
                }
            }
        }
    }
}
