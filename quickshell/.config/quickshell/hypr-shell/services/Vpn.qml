pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// sing-box tunnel state for the control center: selected and active node, traffic, per-node ping.
// Talks to the Clash API (127.0.0.1:9090); the tunnel itself is switched with the vpnon/vpnoff scripts.
// The full set (traffic, every node) is polled only while the tab is on screen (`watch`);
// `ambient` keeps a light poll (state and the active node's ping) for the strip icon.
Singleton {
    id: root

    readonly property string api: "http://127.0.0.1:9090"
    readonly property string group: "proxy"
    readonly property string auto: "auto"
    readonly property string configPath: Quickshell.env("HOME") + "/.config/sing-box/config.json"

    property bool watch: false
    property bool ambient: false
    readonly property bool polling: watch || ambient

    property bool loaded: false
    property bool up: false
    property string selected: ""
    property string active: ""
    property var nodes: []
    property var ping: ({})
    property var probe: ({})
    property real rateUp: 0
    property real rateDown: 0
    property int connVpn: 0
    property int connDirect: 0
    property real startedAt: 0
    property real uptime: 0
    property bool busy: false
    property bool starting: false
    property bool testing: false

    // Full reset (hs-vpn-reset): the script runs detached and reports progress through a status file.
    readonly property string resetFile: Quickshell.env("XDG_RUNTIME_DIR") + "/hs-vpn-reset.status"
    property bool resetting: false
    property string resetStep: ""
    // "ok" or "fail" for a few seconds after a reset ends.
    property string resetResult: ""
    property bool resetSeen: false

    readonly property bool pinned: up && selected !== "" && selected !== auto
    readonly property var activeNode: nodeByTag(active)

    property real prevUp: -1
    property real prevDown: -1
    property real prevAt: 0
    property var probeQueue: []

    function nodeByTag(tag) {
        for (const n of nodes) if (n.tag === tag) return n
        return null
    }

    function parseConfig(text) {
        let cfg
        try { cfg = JSON.parse(text) } catch (e) { return }
        const protos = { vless: "Reality · TCP", hysteria2: "Hysteria2 · UDP" }
        const who = { bwh: "BWH", aws: "AWS" }
        const list = []
        for (const o of cfg.outbounds || []) {
            if (!protos[o.type]) continue
            const pre = o.tag.split("-")[0]
            list.push({ tag: o.tag, who: who[pre] || pre.toUpperCase(), proto: protos[o.type], ip: o.server || "", port: o.server_port || 0 })
        }
        nodes = list
    }

    function parseProxies(text) {
        let p
        try { p = JSON.parse(text).proxies } catch (e) { p = null }
        loaded = true
        if (!p || !p[group]) {
            up = false
            selected = ""
            active = ""
            return
        }
        const sel = p[group].now
        up = true
        selected = sel
        active = sel === auto && p[auto] ? p[auto].now : sel
        uptime = startedAt > 0 ? Math.max(0, Date.now() / 1000 - startedAt) : 0
    }

    function parseConns(text) {
        let c
        try { c = JSON.parse(text) } catch (e) { return }
        const now = Date.now()
        const tx = c.uploadTotal || 0
        const rx = c.downloadTotal || 0
        if (prevAt > 0 && now > prevAt) {
            const dt = Math.max((now - prevAt) / 1000, 0.2)
            rateUp = Math.max(tx - prevUp, 0) / dt
            rateDown = Math.max(rx - prevDown, 0) / dt
        }
        prevUp = tx
        prevDown = rx
        prevAt = now
        let direct = 0
        const all = c.connections || []
        for (const k of all) if (k.chains && k.chains[0] === "direct") direct++
        connDirect = direct
        connVpn = all.length - direct
    }

    function parsePing(text) {
        const out = {}
        for (const l of text.split("\n")) {
            const f = l.trim().split(" ")
            if (f[0] === "uptime") {
                startedAt = parseInt(f[1]) || 0
            } else if (f.length === 3) {
                out[f[0]] = { ms: f[1] === "-" ? -1 : parseFloat(f[1]), loss: parseFloat(f[2]) }
            }
        }
        ping = out
    }

    function reset() {
        rateUp = 0
        rateDown = 0
        prevAt = 0
        probe = ({})
        probeQueue = []
        testing = false
    }

    onWatchChanged: {
        if (watch) {
            configProc.running = true
        } else {
            reset()
        }
    }

    onPollingChanged: if (polling && nodes.length === 0) configProc.running = true

    onActiveChanged: if (polling && !watch && active !== "" && !pingProc.running) pingProc.running = true

    onUpChanged: if (!up) { rateUp = 0; rateDown = 0; prevAt = 0 }

    function select(tag) {
        if (!up || busy) return
        selected = tag
        if (tag === auto) active = ""
        Quickshell.execDetached(["curl", "-s", "-m", "4", "-X", "PUT", "-H", "Content-Type: application/json",
            "-d", JSON.stringify({ name: tag }), api + "/proxies/" + group])
        refreshTimer.restart()
    }

    function resetAll() {
        if (resetting) return
        resetting = true
        resetSeen = false
        resetStep = "Starting"
        resetResult = ""
        Quickshell.execDetached(["setsid", "-f", "sh", "-c",
            "PATH=\"$HOME/.local/bin:$PATH\"; rm -f \"" + resetFile + "\"; exec hs-vpn-reset >/dev/null 2>&1"])
        resetPoll.restart()
        resetGuard.restart()
    }

    function parseReset(text) {
        const line = text.trim()
        if (line.startsWith("step ")) {
            resetSeen = true
            resetStep = line.slice(5)
        } else if (resetSeen && line.startsWith("done ")) {
            resetting = false
            resetResult = line.slice(5)
            resultTimer.restart()
            sample()
        }
    }

    function setTunnel(on) {
        if (busy || resetting) return
        busy = true
        starting = on
        Quickshell.execDetached(["sh", "-c", "PATH=\"$HOME/.local/bin:$PATH\"; exec " + (on ? "vpnon" : "vpnoff") + " >/dev/null 2>&1"])
        busyTimer.restart()
    }

    function testAll() {
        if (!up || testing || nodes.length === 0) return
        probe = ({})
        probeQueue = nodes.map(n => n.tag)
        testing = true
        nextProbe()
    }

    function nextProbe() {
        if (probeQueue.length === 0) {
            testing = false
            return
        }
        probeProc.tag = probeQueue[0]
        probeQueue = probeQueue.slice(1)
        probeProc.running = true
    }

    function sample() {
        if (!proxiesProc.running) proxiesProc.running = true
        if (up && watch && !connsProc.running) connsProc.running = true
    }

    readonly property string pingScript: 'dev=$(ip -o route show default 2>/dev/null | awk \'$5!="vpn-sb"{print $5; exit}\')
while [ $# -ge 2 ]; do
  ( out=$(ping ${dev:+-I $dev} -c 3 -i 0.3 -W 1 -q "$2" 2>&1)
    avg=$(echo "$out" | sed -n \'s|.*= [0-9.]*/\\([0-9.]*\\)/.*|\\1|p\')
    loss=$(echo "$out" | sed -n \'s|.* \\([0-9.]*\\)% packet loss.*|\\1|p\')
    echo "$1 ${avg:--} ${loss:-100}" ) &
  shift 2
done
wait
start=$(date -d "$(systemctl --user show sing-box -p ActiveEnterTimestamp --value 2>/dev/null)" +%s 2>/dev/null)
echo "uptime ${start:-0}"'

    Process {
        id: configProc
        command: ["cat", root.configPath]
        stdout: StdioCollector { onStreamFinished: root.parseConfig(text) }
    }

    Process {
        id: proxiesProc
        command: ["curl", "-s", "-m", "2", root.api + "/proxies"]
        stdout: StdioCollector { onStreamFinished: root.parseProxies(text) }
    }

    Process {
        id: connsProc
        command: ["curl", "-s", "-m", "2", root.api + "/connections"]
        stdout: StdioCollector { onStreamFinished: root.parseConns(text) }
    }

    Process {
        id: pingProc
        command: {
            const argv = ["sh", "-c", root.pingScript, "sh"]
            const targets = root.watch ? root.nodes : (root.activeNode ? [root.activeNode] : [])
            for (const n of targets) argv.push(n.tag, n.ip)
            return argv
        }
        stdout: StdioCollector { onStreamFinished: root.parsePing(text) }
    }

    Process {
        id: probeProc
        property string tag: ""
        command: ["curl", "-s", "-m", "7", root.api + "/proxies/" + tag + "/delay?url=http%3A%2F%2F1.1.1.1%2F&timeout=5000"]
        stdout: StdioCollector {
            onStreamFinished: {
                let ms = -1
                try { ms = JSON.parse(text).delay } catch (e) {}
                const next = Object.assign({}, root.probe)
                next[probeProc.tag] = ms > 0 ? ms : -1
                root.probe = next
                root.nextProbe()
            }
        }
    }

    Timer {
        interval: root.watch ? 2000 : 10000
        repeat: true
        running: root.polling
        triggeredOnStart: true
        onTriggered: root.sample()
    }

    Timer {
        interval: root.watch ? 12000 : 15000
        repeat: true
        running: root.polling && root.nodes.length > 0 && (root.watch || root.up)
        triggeredOnStart: true
        onTriggered: if (!pingProc.running) pingProc.running = true
    }

    FileView {
        id: resetView
        path: root.resetFile
        printErrors: false
        onLoaded: root.parseReset(text())
    }

    Timer {
        id: resetPoll
        interval: 400
        repeat: true
        running: root.resetting
        onTriggered: resetView.reload()
    }

    // A reset that never reports back (the script died) must not leave the UI stuck.
    Timer {
        id: resetGuard
        interval: 240000
        onTriggered: root.resetting = false
    }

    Timer {
        id: resultTimer
        interval: 6000
        onTriggered: root.resetResult = ""
    }

    Timer {
        id: refreshTimer
        interval: 500
        onTriggered: root.sample()
    }

    Timer {
        id: busyTimer
        interval: 5000
        onTriggered: {
            root.busy = false
            root.sample()
        }
    }
}
