pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.theme

// State and actions behind the one-button tiles of the toggles menu; what already lives in another service
// (do not disturb, VPN, night light, theme tokens) is only read there.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property bool btOn: adapter !== null && adapter.enabled
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool micMuted: source !== null && source.audio !== null && source.audio.muted
    readonly property bool powerSaver: PowerProfiles.profile === PowerProfile.PowerSaver

    PwObjectTracker { objects: [root.source] }

    // Airplane mode: both radios off. What was on is remembered so that turning it off brings it back.
    readonly property bool airplane: !wifiOn && !btOn
    property bool wifiWas: true
    property bool btWas: true

    function setAirplane(on) {
        if (on) {
            wifiWas = wifiOn
            btWas = btOn
            Networking.wifiEnabled = false
            if (adapter) adapter.enabled = false
        } else {
            Networking.wifiEnabled = wifiWas || !btWas
            if (adapter) adapter.enabled = btWas || !wifiWas
        }
    }

    function toggleMic() {
        if (source && source.audio) source.audio.muted = !source.audio.muted
    }

    function togglePowerSaver() {
        PowerProfiles.profile = powerSaver ? PowerProfile.Balanced : PowerProfile.PowerSaver
    }

    // Caffeine: holds a systemd idle inhibitor, which hypridle honors, so the dim/lock/off chain pauses. The helper
    // shell exits when its parent (systemd-inhibit) is gone, so stopping the process never leaves a lock behind.
    property bool caffeine: false
    Process {
        running: root.caffeine
        command: ["systemd-inhibit", "--what=idle", "--who=hypr-shell", "--why=Caffeine", "--mode=block",
            "sh", "-c", "p=$PPID; while kill -0 $p 2>/dev/null; do sleep 2; done"]
    }

    // Reduce motion: Hyprland animations off. A config reload restores them, so the flag is read back from the compositor.
    property bool motionReduced: false

    function setMotionReduced(on) {
        Quickshell.execDetached(["hyprctl", "dispatch",
            "function() hl.config({ animations = { enabled = " + (on ? "false" : "true") + " } }) end"])
        motionReduced = on
        motionProbe.restart()
    }

    function refresh() { motionProbe.restart() }

    Timer { id: motionProbe; interval: 400; onTriggered: motionRead.running = true }
    Process {
        id: motionRead
        command: ["hyprctl", "-j", "getoption", "animations:enabled"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.motionReduced = JSON.parse(text).bool === false } catch (e) {}
            }
        }
    }

    function lockNow() { Quickshell.execDetached(["hs-lock"]) }

    function screenOff() {
        Quickshell.execDetached(["sh", "-c", "sleep 0.4; hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'"])
    }
}
