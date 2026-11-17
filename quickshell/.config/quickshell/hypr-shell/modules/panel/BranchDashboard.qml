import QtQuick
import qs.theme
import qs.services
import qs.components

// Dashboard that hangs from the top frame band: tabs on top, tiles below.
Item {
    id: root

    readonly property real pad: 12
    readonly property real tabsH: 40
    // Height of the content area per tab; the branch resizes when the tab changes.
    readonly property var heights: [340, 340, 296, workspaces.wanted, 340]
    readonly property int tab: PanelState.dashTab

    readonly property real maxW: Window.window ? Window.window.width - 160 : 800

    implicitWidth: Math.min(800, maxW)
    implicitHeight: pad / 2 + tabsH + 8 + heights[tab] + pad

    Binding { target: Perf; property: "watching"; value: root.visible && root.tab === 2 }

    DashTabs {
        x: root.pad
        y: root.pad / 2
        width: parent.width - 2 * root.pad
        height: root.tabsH
        current: root.tab
        model: [
            { label: "Dashboard", icon: "dashboard", badge: Toasts.missed },
            { label: "Media", icon: "music" },
            { label: "Performance", icon: "pulse" },
            { label: "Workspaces", icon: "layers" },
            { label: "Weather", icon: "cloudSun" }
        ]
        onPicked: i => PanelState.dashTab = i

        DashProfile {}
    }

    Item {
        id: area
        x: root.pad
        y: root.pad / 2 + root.tabsH + 8
        width: parent.width - 2 * root.pad
        height: root.heights[root.tab]

        // Dashboard
        Item {
            id: dash
            readonly property int index: 0
            width: parent.width
            height: root.heights[index]
            opacity: root.tab === index ? 1 : 0
            x: root.tab === index ? 0 : (root.tab > index ? -16 : 16)
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
            Behavior on x { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }

            readonly property real side: Math.max(190, Math.min(232, (width - 2 * Theme.gapBlock - 260) / 2))
            readonly property real mediaH: 160

            onVisibleChanged: if (visible) Weather.ensure()

            WeatherBlock {
                order: 0
                clickable: true
                tone: Theme.tertiaryContainer
                light: true
                width: dash.side
                height: parent.height
                onActivated: PanelState.dashTab = 4
            }
            CalendarBlock {
                order: 1
                x: dash.side + Theme.gapBlock
                width: parent.width - 2 * dash.side - 2 * Theme.gapBlock
                height: parent.height
            }
            MediaCard {
                order: 2
                tone: Theme.secondaryContainer
                x: parent.width - dash.side
                width: dash.side
                height: dash.mediaH
                onOpenMedia: PanelState.dashTab = 1
            }
            ControlsBlock {
                order: 3
                mic: true
                showValues: true
                x: parent.width - dash.side
                y: dash.mediaH + Theme.gapBlock
                width: dash.side
                height: parent.height - y
            }
        }

        Item {
            readonly property int index: 1
            width: parent.width
            height: root.heights[index]
            opacity: root.tab === index ? 1 : 0
            x: root.tab === index ? 0 : (root.tab > index ? -16 : 16)
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
            Behavior on x { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }

            TabMedia { anchors.fill: parent; shown: root.visible && root.tab === 1 }
        }

        Item {
            readonly property int index: 2
            width: parent.width
            height: root.heights[index]
            opacity: root.tab === index ? 1 : 0
            x: root.tab === index ? 0 : (root.tab > index ? -16 : 16)
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
            Behavior on x { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }

            TabPerformance { anchors.fill: parent }
        }

        Item {
            readonly property int index: 3
            width: parent.width
            height: root.heights[index]
            opacity: root.tab === index ? 1 : 0
            x: root.tab === index ? 0 : (root.tab > index ? -16 : 16)
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
            Behavior on x { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }

            TabWorkspaces { id: workspaces; anchors.fill: parent; active: root.visible && root.tab === 3 }
        }

        Item {
            readonly property int index: 4
            width: parent.width
            height: root.heights[index]
            opacity: root.tab === index ? 1 : 0
            x: root.tab === index ? 0 : (root.tab > index ? -16 : 16)
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }
            Behavior on x { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }

            TabWeather { anchors.fill: parent }
        }
    }
}
