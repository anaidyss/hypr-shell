import QtQuick
import QtQuick.Shapes
import qs.theme

// Where hovering the screen edge opens something: a miniature screen with the three hot zones where they really
// are (click one to switch it), and a switch per zone beside it.
Item {
    id: root

    readonly property var zones: [
        { key: "hotZone", edge: "top", label: "Dashboard", detail: "Top edge, opens the dashboard" },
        { key: "controlHotZone", edge: "right", label: "Control center", detail: "Right edge, opens Wi-Fi, sound and battery" },
        { key: "utilityHotZone", edge: "bottom", label: "Search & notes", detail: "Bottom edge, opens search, clipboard and notes" },
        { key: "notifHotZone", edge: "corner", label: "Notifications", detail: "Top right corner, opens the notification center" }
    ]
    readonly property real zoneLength: 260

    width: parent ? parent.width : implicitWidth
    implicitHeight: preview.height

    ScreenPreview {
        id: preview
        shotWidth: 420
        width: shotWidth
        captions: false
        bands: false
        showWindows: false
        showGlow: false

        Repeater {
            model: root.zones

            Item {
                id: zone
                required property var modelData
                readonly property bool on: Theme.cfg.dashboard[modelData.key]
                readonly property real thick: Math.max(6, 24 * preview.k)
                readonly property real len: root.zoneLength * preview.k
                readonly property bool horizontal: modelData.edge !== "right"
                readonly property bool corner: modelData.edge === "corner"

                width: corner ? thick * 1.6 : (horizontal ? len : thick)
                height: corner ? thick * 1.6 : (horizontal ? thick : len)
                x: corner || modelData.edge === "right" ? preview.width - width : (preview.width - len) / 2
                y: corner || modelData.edge === "top" ? 0 : (modelData.edge === "bottom" ? preview.height - thick : (preview.height - len) / 2)

                Rectangle {
                    anchors.fill: parent
                    radius: zone.corner ? zone.width / 2 : zone.thick / 2
                    color: Theme.accent
                    opacity: zone.on ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
                }

                Shape {
                    anchors.fill: parent
                    opacity: zone.on ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Theme.textDim
                        strokeWidth: 1
                        strokeStyle: ShapePath.DashLine
                        dashPattern: [3, 3]
                        PathPolyline {
                            path: [Qt.point(0.5, 0.5), Qt.point(zone.width - 0.5, 0.5), Qt.point(zone.width - 0.5, zone.height - 0.5), Qt.point(0.5, zone.height - 0.5), Qt.point(0.5, 0.5)]
                        }
                    }
                }

                Text {
                    x: zone.corner || zone.modelData.edge === "right" ? -width - 6 : (zone.width - width) / 2
                    y: zone.modelData.edge === "top" ? zone.thick + 4 : (zone.modelData.edge === "bottom" ? -height - 4 : (zone.height - height) / 2)
                    text: zone.modelData.label
                    color: zone.on ? Theme.text : Theme.textOff
                    font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                }

                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    margin: 8
                    onTapped: Theme.set("dashboard", zone.modelData.key, !zone.on)
                }
            }
        }
    }

    Column {
        anchors { left: preview.right; leftMargin: 16; right: parent.right; verticalCenter: preview.verticalCenter }
        spacing: 12

        Repeater {
            model: root.zones

            Item {
                required property var modelData
                width: parent.width
                height: 40

                Column {
                    anchors { left: parent.left; right: toggle.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    spacing: 2
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: modelData.label
                        color: Theme.text
                        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                    }
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: modelData.detail
                        color: Theme.textDim
                        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                    }
                }

                Switch {
                    id: toggle
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    checked: Theme.cfg.dashboard[modelData.key]
                    onToggled: v => Theme.set("dashboard", modelData.key, v)
                }
            }
        }

        Text {
            text: "Hover the edge to open"
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
    }
}
