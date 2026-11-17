import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

// The session lock (ext-session-lock) with the lock screen on every display, plus a harmless preview window.
Scope {
    WlSessionLock {
        id: sessionLock

        onLockedChanged: LockState.locked = locked

        surface: Component {
            WlSessionLockSurface {
                color: "black"
                LockScreen { anchors.fill: parent }
            }
        }
    }

    // Login opens on the lock screen: tty1 logs in automatically and autostart runs the shell with HS_LOCK_ON_START=1.
    // The lock is taken while the shell loads, before the panel shows; `done` survives config reloads so a reload does not lock again.
    PersistentProperties {
        reloadableId: "hs-lock-on-start"
        property bool done: false
        onLoaded: {
            if (!done && Quickshell.env("HS_LOCK_ON_START") === "1") {
                LockState.reset()
                sessionLock.locked = true
            }
            done = true
        }
    }

    Connections {
        target: LockState
        function onLockRequested() { sessionLock.locked = true }
        function onUnlockRequested() { sessionLock.locked = false }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            readonly property bool onFocused: Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === modelData.name

            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            color: "black"
            visible: LockState.preview && onFocused
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "hs-lockpreview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            LockScreen { anchors.fill: parent; isPreview: true }
        }
    }
}
