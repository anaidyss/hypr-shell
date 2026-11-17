pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Who and what the shell runs on: user, host, distribution, compositor, uptime.
Singleton {
    id: root

    readonly property string user: Quickshell.env("USER") || ""
    readonly property string compositor: Quickshell.env("XDG_CURRENT_DESKTOP") || "Hyprland"
    readonly property string avatar: "file:///var/lib/AccountsService/icons/" + user

    property string host: ""
    property string distro: ""
    property real uptimeSec: 0

    readonly property string uptime: {
        const m = Math.floor(uptimeSec / 60), h = Math.floor(m / 60), d = Math.floor(h / 24)
        if (d > 0) return d + "d " + (h % 24) + "h"
        if (h > 0) return h + "h " + (m % 60) + "m"
        return m + " min"
    }

    function refresh() {
        if (!proc.running) proc.running = true
    }

    Component.onCompleted: refresh()

    Process {
        id: proc
        command: ["sh", "-c", ". /etc/os-release; echo \"$NAME $VERSION_ID\"; cat /proc/sys/kernel/hostname; cut -d' ' -f1 /proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n")
                if (l.length < 3) return
                root.distro = l[0].trim()
                root.host = l[1].trim()
                root.uptimeSec = parseFloat(l[2]) || 0
            }
        }
    }
}
