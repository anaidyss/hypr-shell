pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live system load: CPU, memory, temperature, network, battery power, GPU clock, disk and the busiest processes.
// The sampler runs in the background from `start()` so the charts are already full when the dashboard opens;
// the process list (`top`) is only polled while `watching` is set (the Performance tab is visible).
Singleton {
    id: root

    property bool sampling: false
    property bool watching: false
    readonly property int points: 120
    readonly property int interval: 2

    function start() { sampling = true }

    property int cores: 1

    property real cpu: 0
    property real ramUsed: 0
    property real ramTotal: 1
    property real swapUsed: 0
    property real swapTotal: 0
    property real temp: -1
    property real netDown: 0
    property real netUp: 0
    property bool hasBattery: false
    property int batteryPct: 0
    property string batteryStatus: ""
    property real watts: 0
    property real gpuMhz: -1
    property real gpuMax: 1
    property real diskUsed: 0
    property real diskTotal: 1
    property var procs: []

    property var cpuHist: []
    property var ramHist: []
    property var tempHist: []
    property var downHist: []
    property var upHist: []
    property var wattHist: []
    property var gpuHist: []

    readonly property real ram: ramTotal > 0 ? ramUsed / ramTotal : 0
    readonly property real disk: diskTotal > 0 ? diskUsed / diskTotal : 0

    function push(arr, v) {
        const next = arr.length >= points ? arr.slice(arr.length - points + 1) : arr.slice()
        next.push(v)
        return next
    }

    function rate(bytes) {
        const units = ["B/s", "KB/s", "MB/s", "GB/s"]
        let v = bytes, i = 0
        while (v >= 1000 && i < units.length - 1) { v /= 1000; i++ }
        return (v >= 100 || i === 0 ? Math.round(v) : v.toFixed(1)) + " " + units[i]
    }

    // Memory is counted in powers of 1024, disks in powers of 1000, as the file manager does.
    function size(bytes, binary) {
        const units = ["B", "KB", "MB", "GB", "TB"]
        const base = binary ? 1024 : 1000
        let v = bytes, i = 0
        while (v >= base && i < units.length - 1) { v /= base; i++ }
        return (v >= 100 || i === 0 ? Math.round(v) : v.toFixed(1)) + " " + units[i]
    }

    // Raw counters of the previous sample
    property real prevTotal: -1
    property real prevIdle: 0
    property real prevRx: -1
    property real prevTx: 0
    property real prevAt: 0

    property var block: ({})

    function feed(line) {
        if (line === "---") {
            apply(block)
            block = ({})
            return
        }
        const sp = line.indexOf(" ")
        if (sp < 0) return
        const tag = line.slice(0, sp)
        const rest = line.slice(sp + 1)
        if (tag === "cores") { cores = Math.max(1, parseInt(rest) || 1); return }
        block[tag] = rest
    }

    function apply(b) {
        const now = Date.now()
        const dt = prevAt > 0 ? Math.max(0.2, (now - prevAt) / 1000) : 1
        prevAt = now

        if (b.cpu) {
            const f = b.cpu.trim().split(/\s+/).slice(1).map(Number)
            const total = f.slice(0, 8).reduce((s, v) => s + v, 0)
            const idle = f[3] + f[4]
            if (prevTotal >= 0 && total > prevTotal) {
                cpu = Math.max(0, Math.min(1, 1 - (idle - prevIdle) / (total - prevTotal)))
                cpuHist = push(cpuHist, cpu)
            }
            prevTotal = total
            prevIdle = idle
        }

        if (b.mem) {
            const m = b.mem.trim().split(/\s+/).map(v => Number(v) * 1024)
            ramTotal = m[0]
            ramUsed = m[0] - m[1]
            swapTotal = m[2]
            swapUsed = m[2] - m[3]
            ramHist = push(ramHist, ram)
        }

        if (b.temp) {
            temp = Number(b.temp) / 1000
            tempHist = push(tempHist, temp)
        }

        if (b.net) {
            const n = b.net.trim().split(/\s+/).map(Number)
            if (prevRx >= 0 && n[0] >= prevRx && n[1] >= prevTx) {
                netDown = (n[0] - prevRx) / dt
                netUp = (n[1] - prevTx) / dt
                downHist = push(downHist, netDown)
                upHist = push(upHist, netUp)
            }
            prevRx = n[0]
            prevTx = n[1]
        }

        if (b.bat) {
            const f = b.bat.trim().split(/\s+/)
            hasBattery = true
            batteryPct = parseInt(f[0]) || 0
            const power = Number(f[1]), volt = Number(f[2]), cur = Number(f[3])
            watts = (power > 0 ? power : volt * cur / 1e6) / 1e6
            batteryStatus = f.slice(4).join(" ")
            wattHist = push(wattHist, watts)
        }

        if (b.gpu) {
            const g = b.gpu.trim().split(/\s+/).map(Number)
            gpuMhz = g[0]
            gpuMax = Math.max(1, g[1])
            gpuHist = push(gpuHist, gpuMhz / gpuMax)
        }

        if (b.disk) {
            const d = b.disk.trim().split(/\s+/).map(Number)
            if (d.length === 2 && d[1] > 0) { diskUsed = d[0]; diskTotal = d[1] }
        }
    }

    Process {
        running: root.sampling
        command: [Quickshell.env("HOME") + "/.local/bin/hs-perf-sampler", String(root.interval)]
        stdout: SplitParser { onRead: line => root.feed(line) }
    }

    // `top` needs two passes for a real CPU share; it runs only every few seconds.
    Process {
        id: top
        environment: ({ LC_ALL: "C" })
        command: ["top", "-b", "-n", "2", "-d", "0.5", "-w", "200", "-o", "%CPU"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                let last = -1
                for (let i = 0; i < lines.length; i++) if (/^\s*PID\s+USER/.test(lines[i])) last = i
                if (last < 0) return
                const out = []
                for (let i = last + 1; i < lines.length && out.length < 3; i++) {
                    const t = lines[i].trim().split(/\s+/)
                    if (t.length < 12 || t[11] === "top") continue
                    out.push({ name: t.slice(11).join(" "), cpu: parseFloat(t[8]) / root.cores / 100, mem: parseFloat(t[9]) / 100 })
                }
                root.procs = out
            }
        }
    }

    Timer {
        running: root.watching
        interval: 3000
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!top.running) top.running = true
    }
}
