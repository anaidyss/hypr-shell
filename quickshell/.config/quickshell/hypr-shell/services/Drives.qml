pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.theme

// Drives: a background `hs-drives watch` keeps `drives` (removable disks, each with its partitions) and `internal`
// (internal data partitions) current; the strip shows a drives icon only while a removable disk is present and pulses
// it when a new one appears. Quick actions go through hs-drives (udisks2) and report failures as a toast. Long jobs
// (write an image, Windows installer, Ventoy, backup, tests, erase, photo import) run one at a time through hs-flash
// and live here, not in the branch, so they keep running when the branch closes.
Singleton {
    id: root

    property bool sampling: false
    property var drives: []
    property var internal: []
    readonly property bool hasDrives: drives.length > 0
    property bool pulse: false
    // Filesystems whose mkfs tool is installed, plus the helpers of the Windows mode (`hs-drives caps`, `which`).
    property var fsCaps: ({})
    property bool hasWinTools: false

    // The disk the branch works on: the one picked last, or the newest one plugged in.
    property string selectedDev: ""
    readonly property var selected: {
        for (const d of drives) if (d.dev === selectedDev) return d
        return drives.length > 0 ? drives[drives.length - 1] : null
    }

    function start() { sampling = true; refreshCaps() }

    property bool sampledOnce: false
    property var imported: ({})   // camera cards already imported this session (by disk path)

    function parse(line) {
        let st = { disks: [], internal: [] }
        try { st = JSON.parse(line) } catch (e) {}
        const prev = drives.map(d => d.dev)
        internal = st.internal || []
        drives = st.disks || []
        const added = drives.filter(d => prev.indexOf(d.dev) < 0)
        if (added.length > 0 && sampledOnce) {
            const d = added[added.length - 1]
            selectedDev = d.dev
            pulse = true
            pulseTimer.restart()
            connected(d)
        }
        for (const d of drives)
            if (d.camera && Theme.cfg.drives.autoImport && !imported[d.dev] && !busy) {
                const m = Object.assign({}, imported)
                m[d.dev] = true
                imported = m
                importPhotos(d)
            }
        const gone = Object.keys(imported).filter(k => drives.every(d => d.dev !== k))
        if (gone.length > 0) {
            const m = Object.assign({}, imported)
            for (const k of gone) delete m[k]
            imported = m
        }
        sampledOnce = true
    }

    // What happens when a drive is plugged in (`drives.onConnect`): nothing but the pulse, open the Drives menu,
    // mount it, or open it in the file manager.
    function connected(d) {
        const how = Theme.cfg.drives.onConnect
        if (how === "menu")
            PanelState.open("drives", -1, Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "", true)
        else if (how === "mount" && d.main !== "") mount(d.main)
        else if (how === "files") open(d.dev, "")
        else if (Theme.cfg.drives.autoImport && d.main !== "") mount(d.main)  // so a camera card can be seen
    }

    Timer { id: pulseTimer; interval: 1200; onTriggered: root.pulse = false }

    // ---- one-shot actions ----
    function mount(dev) { act(["mount", dev]) }
    function unmount(dev) { act(["unmount", dev]) }
    function eject(dev) { act(["eject", dev]) }
    function open(dev, sub) { act(["open", dev, sub || ""]) }
    function terminal(dev, sub) { act(["terminal", dev, sub || ""]) }
    function rename(dev, label) { act(["rename", dev, label]) }

    function act(args) {
        const p = actComp.createObject(root, { command: ["hs-drives"].concat(args) })
        p.running = true
    }

    Component {
        id: actComp
        Process {
            id: proc
            stdout: SplitParser { onRead: line => root.report(line, "Drive") }
            onExited: proc.destroy()
        }
    }

    function report(line, title) {
        let r = { ok: true, msg: "" }
        try { r = JSON.parse(line) } catch (e) {}
        if (r.ok === false && r.msg)
            Quickshell.execDetached(["notify-send", "-a", "Drives", "-u", "critical", title, r.msg])
    }

    // ---- format (whole removable disk) ----
    property string formatDev: ""
    readonly property bool formatting: formatProc.running

    // Erases the disk: the branch only calls this after the confirmation step that lists what will be lost.
    function format(dev, fs, label, table, erase) {
        if (busy) return
        formatDev = dev
        formatProc.command = ["hs-drives", "format", dev, fs, label, table, erase]
        formatProc.running = true
    }

    Process {
        id: formatProc
        stdout: SplitParser {
            onRead: line => {
                let r = { ok: false, msg: "" }
                try { r = JSON.parse(line) } catch (e) {}
                if (r.ok) Quickshell.execDetached(["notify-send", "-a", "Drives", "Drive formatted", "Ready to use"])
                else root.report(line, "Format failed")
            }
        }
        onExited: root.formatDev = ""
    }

    // ---- long jobs (hs-flash) ----
    // stage: "" idle · auth · prepare · write · copy · verify · sync · format · … · done · error
    property string jobKind: ""
    property string jobDev: ""
    property string jobTitle: ""      // what the job is about: "Linux Mint 22.3", "Speed test"
    property string jobIcon: ""       // PanelIcon name, or…
    property string jobLogo: ""       // …a distribution logo path
    property string jobStage: ""
    property string jobLabel: ""      // the current step in words, from hs-flash
    property real jobDone: 0
    property real jobTotal: 0
    property real jobSpeed: 0
    property string jobError: ""
    property string jobResult: ""
    property bool jobGood: true       // a finished test that found a problem (fake stick) is not "good"
    property string jobPath: ""       // a file the job produced (backup, import folder)
    readonly property bool jobRunning: jobProc.running
    readonly property bool busy: jobProc.running || formatProc.running
    readonly property real jobRatio: jobTotal > 0 ? Math.min(1, jobDone / jobTotal) : 0
    // Raw writes, Windows and Ventoy rewrite the whole drive; the strip shows them as "writing".
    readonly property bool writing: jobRunning

    function run(kind, dev, title, icon, logo, args) {
        if (busy) return
        jobKind = kind
        jobDev = dev
        jobTitle = title
        jobIcon = icon
        jobLogo = logo
        jobStage = "prepare"
        jobLabel = "Starting"
        jobDone = 0
        jobTotal = 0
        jobSpeed = 0
        jobError = ""
        jobResult = ""
        jobGood = true
        jobPath = ""
        jobProc.command = ["hs-flash"].concat(args)
        jobProc.running = true
    }

    function writeImage(it, dev) {
        const title = it.name + (it.version !== "" ? " " + it.version : "")
        if (it.windows) run("windows", dev, title, "", it.logo, ["windows", it.path, dev])
        else run("write", dev, title, "", it.logo, ["write", it.path, dev, Theme.cfg.drives.verify ? "verify" : "noverify"])
    }
    function copyToVentoy(it, dev) {
        run("copy", dev, it.name + (it.version !== "" ? " " + it.version : ""), "", it.logo, ["copy", it.path, dev])
    }
    function installVentoy(dev, upgrade) {
        run("ventoy", dev, "Ventoy", "layers", "", ["ventoy", dev, upgrade ? "upgrade" : "install"])
    }
    function backup(d) {
        const name = (d.label !== "" ? d.label : d.model).replace(/[^A-Za-z0-9._-]+/g, "-")
        const stamp = new Date().toISOString().slice(0, 10)
        run("backup", d.dev, "Backup of " + title(d), "save", "",
            ["backup", d.dev, IsoLibrary.dir + "/" + name + "-" + stamp + ".img.zst"])
    }
    function speedTest(d) { run("speed", d.dev, "Speed test", "pulse", "", ["speed", d.dev]) }
    function probe(d, fs, label) { run("probe", d.dev, "Capacity check", "shieldCheck", "", ["probe", d.dev, fs, label]) }
    function wipe(d, fs, label) { run("erase", d.dev, "Secure erase", "eraser", "", ["erase", d.dev, fs, label]) }
    function importPhotos(d) {
        run("import", d.dev, "Photos from " + title(d), "image", "",
            ["import", d.dev, Theme.cfg.drives.importDir.replace(/^~/, Quickshell.env("HOME"))])
    }

    function cancel() { if (jobProc.running) jobProc.signal(15) }
    function clearJob() { if (!jobProc.running) jobStage = "" }

    // Kept for the strip and the rail menu (they show progress of any job).
    readonly property real writeRatio: jobRatio
    function cancelWrite() { cancel() }

    Process {
        id: jobProc
        stdout: SplitParser {
            onRead: line => {
                let r = {}
                try { r = JSON.parse(line) } catch (e) { return }
                if (r.total !== undefined) root.jobTotal = r.total
                if (r.done !== undefined) root.jobDone = r.done
                if (r.speed !== undefined) root.jobSpeed = r.speed
                if (r.label !== undefined) root.jobLabel = r.label
                if (r.stage === "error") root.jobError = r.msg || "Failed"
                if (r.stage === "done") {
                    root.jobResult = r.result || "Done"
                    root.jobGood = r.ok !== false
                    root.jobPath = r.path || ""
                }
                if (r.stage) root.jobStage = r.stage
                if (r.stage === "done")
                    Quickshell.execDetached(["notify-send", "-a", "Drives", root.jobTitle, root.jobResult])
                else if (r.stage === "error" && !r.cancelled)
                    Quickshell.execDetached(["notify-send", "-a", "Drives", "-u", "critical", root.jobTitle, root.jobError])
            }
        }
        onExited: {
            if (root.jobStage !== "done" && root.jobStage !== "error") {
                root.jobStage = "error"
                root.jobError = "The job stopped unexpectedly"
            }
            root.refreshCaps()
        }
    }

    // ---- formatting helpers ----
    function size(bytes) {
        const units = ["B", "KB", "MB", "GB", "TB"]
        let v = bytes || 0, i = 0
        while (v >= 1000 && i < units.length - 1) { v /= 1000; i++ }
        return (v >= 100 || i === 0 ? Math.round(v) : v.toFixed(1)) + " " + units[i]
    }

    readonly property var fsNames: ({ vfat: "FAT32", exfat: "exFAT", ntfs: "NTFS", ext4: "ext4", btrfs: "btrfs",
        f2fs: "F2FS", xfs: "XFS", udf: "UDF", iso9660: "ISO 9660" })
    function fsName(fs) { return fsNames[fs] || fs }

    function title(d) { return d ? (d.ventoy ? "Ventoy" : d.label !== "" ? d.label : d.model) : "" }

    // The filesystem a test or an erase leaves behind: what the drive had, or the most portable one installed.
    function refill(d) {
        const fs = d && d.fstype !== "" && d.fstype !== "iso9660" && fsCaps[d.fstype] ? d.fstype
            : fsCaps.exfat ? "exfat" : "ext4"
        const label = d && d.label !== "" && !d.iso && !d.ventoy ? d.label : "USB"
        return { fs: fs, label: label }
    }

    Process {
        running: root.sampling
        command: [Quickshell.env("HOME") + "/.local/bin/hs-drives", "watch"]
        stdout: SplitParser { onRead: line => root.parse(line) }
    }

    function refreshCaps() { capsProc.running = true }
    Process {
        id: capsProc
        command: ["sh", "-c", "hs-drives caps; command -v 7z >/dev/null && command -v wimlib-imagex >/dev/null && echo win"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                try { root.fsCaps = JSON.parse(lines[0]).fs } catch (e) {}
                root.hasWinTools = lines.indexOf("win") >= 0
            }
        }
    }

    IpcHandler {
        target: "drives"
        function mount(dev: string): void { root.mount(dev) }
        function unmount(dev: string): void { root.unmount(dev) }
        function eject(dev: string): void { root.eject(dev) }
        function open(dev: string): void { root.open(dev, "") }
        function cancel(): void { root.cancel() }
        function state(): string {
            return JSON.stringify({ drives: root.drives.map(d => d.dev), selected: root.selected ? root.selected.dev : "",
                job: root.jobKind, stage: root.jobStage, done: root.jobDone, total: root.jobTotal,
                error: root.jobError, result: root.jobResult })
        }
    }
}
