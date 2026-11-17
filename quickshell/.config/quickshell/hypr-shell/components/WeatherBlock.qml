import QtQuick
import qs.theme
import qs.services
import qs.components

// Weather: conditions now (with the day's range and details), the next hours and, when tall enough, the next days.
Block {
    id: root

    property bool clickable: false
    signal activated()

    readonly property bool tall: height >= 300

    title: "Weather" + (Weather.has && Weather.place !== "" ? "  ·  " + Weather.place : "")
    icon: "cloudSun"

    readonly property var today: Weather.daily.length > 0 ? Weather.daily[0] : null
    readonly property var slots: Weather.hourly.slice(1, 5)

    Text {
        visible: !Weather.has
        anchors.centerIn: parent
        text: Weather.loading ? "Loading weather…" : "No weather data"
        color: root.fgDim
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
    }

    Tile {
        id: nowTile
        visible: Weather.has
        width: parent.width
        // Narrow blocks (the dashboard) cannot fit the details beside the temperature, so they go in a row below it.
        readonly property bool compact: width < 280
        readonly property var details: [
            { label: "Feels", value: Weather.has ? Weather.deg(Weather.data.feels) : "" },
            { label: "Humidity", value: Weather.has ? Weather.percent(Weather.data.humidity) : "" },
            { label: "Wind", value: Weather.has ? Weather.wind(Weather.data.wind) : "" }
        ]
        height: compact ? 132 : 100

        PanelIcon { x: 12; y: 12; name: Weather.icon; size: 38; color: root.fgAccent }
        Text {
            x: 58
            y: 8
            text: Weather.has ? Weather.deg(Weather.data.temp) : ""
            color: root.fg
            lineHeightMode: Text.FixedHeight
            lineHeight: 44
            font { family: Theme.fontUi; pixelSize: 38; weight: Theme.wHeavy }
        }
        Text {
            x: 12
            y: 58
            width: nowTile.compact ? nowTile.width - 24 - range.implicitWidth - 8 : 120
            text: Weather.text
            color: root.fg
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
        }
        Text {
            id: range
            x: nowTile.compact ? nowTile.width - 12 - implicitWidth : 12
            y: nowTile.compact ? 60 : 76
            text: root.today ? "H " + Weather.deg(root.today.max) + "   L " + Weather.deg(root.today.min) : ""
            color: root.fgDim
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }

        Rectangle { visible: !nowTile.compact; x: 140; y: 15; width: 1; height: parent.height - 30; color: root.fgLine }

        Row {
            visible: nowTile.compact
            x: 12
            y: 88
            width: parent.width - 24

            Repeater {
                model: nowTile.details

                Column {
                    id: cell
                    required property var modelData
                    width: parent.width / 3
                    spacing: 2

                    Text {
                        width: parent.width
                        text: cell.modelData.value
                        color: root.fg
                        elide: Text.ElideRight
                        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
                    }
                    Text {
                        width: parent.width
                        text: (cell.modelData.label === "Humidity" ? "Humid" : cell.modelData.label).toUpperCase()
                        color: root.fgDim
                        elide: Text.ElideRight
                        font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy; letterSpacing: 1.3 }
                    }
                }
            }
        }

        Column {
            visible: !nowTile.compact
            x: 154
            y: 15
            width: parent.width - 154 - 12
            spacing: 8

            Repeater {
                model: nowTile.details

                Item {
                    id: detail
                    required property var modelData
                    width: parent.width
                    height: 18

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: detail.modelData.label.toUpperCase()
                        color: root.fgDim
                        font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy; letterSpacing: 1.3 }
                    }
                    Text {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        text: detail.modelData.value
                        color: root.fg
                        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
                    }
                }
            }
        }
    }

    Tile {
        id: hoursTile
        visible: Weather.has
        y: nowTile.height + Theme.gapTile
        width: parent.width
        // Without the days below, the hours take all the room that is left in the block.
        height: root.tall ? 64 : parent.height - y

        Row {
            anchors.fill: parent

            Repeater {
                model: root.slots

                Item {
                    id: slot
                    required property var modelData
                    width: parent.width / 4
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: root.tall ? 2 : 6

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: slot.modelData.t.slice(11, 16)
                            color: root.fgDim
                            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
                        }
                        PanelIcon { anchors.horizontalCenter: parent.horizontalCenter; name: Weather.iconFor(slot.modelData.cond, slot.modelData.isDay); size: root.tall ? 20 : 24; color: root.fg }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Weather.deg(slot.modelData.temp)
                            color: root.fg
                            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
                        }
                    }
                }
            }
        }
    }

    Tile {
        visible: Weather.has && root.tall
        y: hoursTile.y + hoursTile.height + Theme.gapTile
        width: parent.width
        height: parent.height - y

        Column {
            anchors.fill: parent

            Repeater {
                model: Weather.daily.slice(1, 4)

                Item {
                    id: day
                    required property var modelData
                    width: parent.width
                    height: parent.height / 3

                    Text {
                        x: Theme.padTile
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44
                        text: Weather.weekday(day.modelData.date)
                        color: root.fgDim
                        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                    }
                    PanelIcon {
                        x: Theme.padTile + 50
                        anchors.verticalCenter: parent.verticalCenter
                        name: Weather.iconFor(day.modelData.cond, true)
                        size: 18
                        color: root.fg
                    }
                    Row {
                        anchors { right: parent.right; rightMargin: Theme.padTile; verticalCenter: parent.verticalCenter }
                        spacing: 8
                        Text {
                            text: Weather.deg(day.modelData.max)
                            color: root.fg
                            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
                        }
                        Text {
                            text: Weather.deg(day.modelData.min)
                            color: root.fgDim
                            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                        }
                    }
                }
            }
        }
    }

    HoverHandler { cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor }
    TapHandler { enabled: root.clickable; onTapped: root.activated() }
}
