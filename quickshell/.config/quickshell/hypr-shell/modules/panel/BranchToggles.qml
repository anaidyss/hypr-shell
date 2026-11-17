import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components

// One-button switches, most important first: look, silence, radios, comfort and the power actions at the end.
Item {
    id: root

    readonly property real pad: 12
    readonly property var modeNames: ({ auto: "Auto", dark: "Dark", light: "Light", glass: "Transparent", solid: "Opaque" })

    function cycle(group, key, order) {
        const cur = Theme.cfg[group][key]
        Theme.set(group, key, order[(order.indexOf(cur) + 1) % order.length])
    }

    implicitWidth: 2 * pad + 4 * 100 + 3 * Theme.gapTile
    implicitHeight: 2 * pad + 4 * 76 + 3 * Theme.gapTile

    Component.onCompleted: QuickToggles.refresh()

    GridLayout {
        x: root.pad
        y: root.pad
        width: root.width - 2 * root.pad
        height: root.height - 2 * root.pad
        columns: 4
        rowSpacing: Theme.gapTile
        columnSpacing: Theme.gapTile

        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: Theme.isLight ? "sun" : "moon"
            label: "Theme"
            sub: root.modeNames[Theme.cfg.theme.mode] || "Auto"
            on: Theme.isLight
            onActivated: root.cycle("theme", "mode", ["auto", "dark", "light"])
        }
        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: "dashboard"
            label: "Design"
            sub: Theme.solid ? "Opaque" : "Transparent"
            on: Theme.solid
            onActivated: Theme.set("design", "mode", Theme.solid ? "glass" : "solid")
        }
        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: Toasts.dnd ? "bellOff" : "bell"
            label: "Silence"
            sub: Toasts.dnd ? "No popups" : "Off"
            on: Toasts.dnd
            onActivated: Toasts.dnd = !Toasts.dnd
        }
        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: "moon"
            label: "Night light"
            sub: NightLight.on ? NightLight.shownKelvin + " K" : "Off"
            on: NightLight.on
            onActivated: NightLight.setOn(!NightLight.on)
        }

        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: "plane"
            label: "Airplane"
            sub: QuickToggles.airplane ? "On" : "Off"
            on: QuickToggles.airplane
            onActivated: QuickToggles.setAirplane(!QuickToggles.airplane)
        }
        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: "wifi"
            label: "Wi-Fi"
            sub: QuickToggles.wifiOn ? "On" : "Off"
            on: QuickToggles.wifiOn
            onActivated: Net.toggleWifi()
        }
        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: "bluetooth"
            label: "Bluetooth"
            sub: QuickToggles.btOn ? "On" : (QuickToggles.adapter ? "Off" : "No adapter")
            on: QuickToggles.btOn
            enabled: QuickToggles.adapter !== null
            onActivated: QuickToggles.adapter.enabled = !QuickToggles.adapter.enabled
        }
        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: Vpn.up ? "shieldCheck" : "shield"
            label: "VPN"
            sub: Vpn.busy ? (Vpn.starting ? "Starting" : "Stopping") : (Vpn.up ? "On" : "Off")
            on: Vpn.up
            enabled: !Vpn.busy
            onActivated: Vpn.setTunnel(!Vpn.up)
        }

        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: QuickToggles.micMuted ? "micOff" : "mic"
            label: "Microphone"
            sub: QuickToggles.micMuted ? "Muted" : "Live"
            on: QuickToggles.micMuted
            enabled: QuickToggles.source !== null
            onActivated: QuickToggles.toggleMic()
        }
        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: "cup"
            label: "Caffeine"
            sub: QuickToggles.caffeine ? "Staying awake" : "Off"
            on: QuickToggles.caffeine
            onActivated: QuickToggles.caffeine = !QuickToggles.caffeine
        }
        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: "motion"
            label: "Less motion"
            sub: QuickToggles.motionReduced ? "On" : "Off"
            on: QuickToggles.motionReduced
            onActivated: QuickToggles.setMotionReduced(!QuickToggles.motionReduced)
        }
        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: "battery"
            label: "Power saver"
            sub: QuickToggles.powerSaver ? "On" : "Off"
            on: QuickToggles.powerSaver
            onActivated: QuickToggles.togglePowerSaver()
        }

        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: "lock"
            label: "Lock"
            sub: "Now"
            onActivated: { PanelState.dismiss("toggles"); QuickToggles.lockNow() }
        }
        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: "monitorOff"
            label: "Screen off"
            sub: "Key wakes"
            onActivated: { PanelState.dismiss("toggles"); QuickToggles.screenOff() }
        }
        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: "gear"
            label: "Settings"
            sub: "Open"
            onActivated: { PanelState.dismiss("toggles"); SettingsState.show("glass") }
        }
        ToggleTile {
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: "timer"
            label: "Timer"
            sub: TimerService.running ? TimerService.remainingText : "Open"
            on: TimerService.running
            onActivated: PanelState.openOption("timer")
        }
    }
}
