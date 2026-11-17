pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Backlight level through brightnessctl, 0..1.
Singleton {
    id: root

    property real value: 0
    property bool available: false
    property bool dirty: false
    property int target: 0

    function refresh() {
        if (!read.running && !write.running && !dirty) read.running = true
    }

    // Never goes below 1% so the panel cannot be switched off by a slider.
    function set(v) {
        value = Math.max(0.01, Math.min(1, v))
        target = Math.round(value * 100)
        dirty = true
        flush()
    }

    function flush() {
        if (write.running || !dirty) return
        dirty = false
        write.command = ["brightnessctl", "-q", "set", root.target + "%"]
        write.running = true
    }

    Process {
        id: read
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",")
                if (f.length >= 4 && !root.dirty) {
                    root.available = true
                    root.value = parseInt(f[3]) / 100
                }
            }
        }
    }

    Process {
        id: write
        onRunningChanged: if (!running) root.flush()
    }
}
