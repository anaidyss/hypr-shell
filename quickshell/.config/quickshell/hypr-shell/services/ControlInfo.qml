pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Live details for the control center tabs (link rate, sample rate, battery electronics).
// Each source is polled only while its tab is on screen.
Singleton {
    id: root

    property bool wifiWatch: false
    property string wifiDev: ""
    property bool soundWatch: false
    property bool batteryWatch: false

    property string wifiChan: ""
    property real wifiFreq: 0
    property real wifiLink: 0
    property real wifiDbm: 0
    property string wifiIp: ""

    property real sinkRate: 0
    property string sinkFormat: ""
    property int sinkChannels: 0

    property real voltage: 0
    property int cycles: 0
    property real capacityHealth: 0

    function num(s) {
        const m = /-?[0-9.]+/.exec(s || "")
        return m ? parseFloat(m[0]) : 0
    }

    function parseWifi(text) {
        const parts = text.split("---\n")
        const nm = (parts[0] || "").trim().split(":")
        let rate = 0
        if (nm.length >= 5) {
            wifiChan = nm[1]
            wifiFreq = num(nm[2])
            rate = num(nm[3])
        } else {
            wifiChan = ""
            wifiFreq = 0
        }
        wifiIp = (parts[1] || "").trim().split("/")[0]
        let tx = 0, dbm = 0
        for (const l of (parts[2] || "").split("\n")) {
            if (l.indexOf("signal:") >= 0) dbm = num(l.split("signal:")[1])
            else if (l.indexOf("tx bitrate:") >= 0) tx = num(l.split("tx bitrate:")[1])
        }
        wifiDbm = dbm
        wifiLink = tx > 0 ? tx : rate
    }

    function parseSinks(text) {
        let list
        try { list = JSON.parse(text) } catch (e) { return }
        const sink = Pipewire.defaultAudioSink
        const name = sink ? sink.name : ""
        for (const s of list) {
            if (s.name !== name) continue
            const m = /^(\S+)\s+(\d+)ch\s+(\d+)Hz/.exec(s.sample_specification || "")
            if (m) {
                sinkFormat = m[1]
                sinkChannels = parseInt(m[2])
                sinkRate = parseInt(m[3])
            }
            return
        }
        sinkFormat = ""
        sinkChannels = 0
        sinkRate = 0
    }

    function parseBattery(text) {
        const v = text.trim().split("\n").map(s => parseFloat(s))
        voltage = v[0] > 0 ? v[0] / 1e6 : 0
        cycles = v[1] >= 0 ? v[1] : 0
        capacityHealth = v[2] > 0 && v[3] > 0 ? v[2] / v[3] * 100 : 0
    }

    readonly property string wifiScript: 'dev="$1"
nmcli -t -f IN-USE,CHAN,FREQ,RATE,SIGNAL dev wifi list ifname "$dev" --rescan no 2>/dev/null | grep "^\\*" | head -1
echo ---
nmcli -g IP4.ADDRESS dev show "$dev" 2>/dev/null | head -1
echo ---
iw dev "$dev" link 2>/dev/null | grep -E "signal:|bitrate:"'

    readonly property string batteryScript: 'cd /sys/class/power_supply/BAT0 2>/dev/null || exit 0
for f in voltage_now cycle_count charge_full charge_full_design; do cat $f 2>/dev/null || echo -1; done'

    Process {
        id: wifiProc
        command: ["sh", "-c", root.wifiScript, "sh", root.wifiDev]
        stdout: StdioCollector { onStreamFinished: root.parseWifi(text) }
    }
    Timer {
        interval: 3000
        repeat: true
        running: root.wifiWatch && root.wifiDev !== ""
        triggeredOnStart: true
        onTriggered: if (!wifiProc.running) wifiProc.running = true
    }

    Process {
        id: sinkProc
        command: ["pactl", "--format=json", "list", "sinks"]
        stdout: StdioCollector { onStreamFinished: root.parseSinks(text) }
    }
    Timer {
        interval: 5000
        repeat: true
        running: root.soundWatch
        triggeredOnStart: true
        onTriggered: if (!sinkProc.running) sinkProc.running = true
    }

    Process {
        id: batProc
        command: ["sh", "-c", root.batteryScript]
        stdout: StdioCollector { onStreamFinished: root.parseBattery(text) }
    }
    Timer {
        interval: 10000
        repeat: true
        running: root.batteryWatch
        triggeredOnStart: true
        onTriggered: if (!batProc.running) batProc.running = true
    }
}
