pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// The one input of the utility branch: it launches applications and evaluates math, currency and unit
// expressions with qalc. In clipboard mode ("/v " or Super+V) it lists the cliphist history instead, and in notes
// mode ("/n " or Super+Alt+N) the quick notes. Every row has a `key` that identifies it across list rebuilds.
// Rows: { kind: "app", entry }, { kind: "calc", title, sub }, { kind: "clip", id, ctype, title, meta, color },
// { kind: "note", path, title, mtime } and { kind: "newnote", title }.
Singleton {
    id: root

    readonly property bool active: PanelState.isOpen("utility")
    readonly property int maxRows: 6

    // "main", "clip" or "note"
    property string mode: "main"
    property string query: ""
    // Row to select once it appears in the list (a note that was just created).
    property string selectKey: ""
    signal editRequested()
    property string calc: ""
    property string calcExpr: ""
    property var usage: ({})
    // Recent calculations that were copied, newest first: [{ expr, result }].
    property var history: []

    readonly property var results: build()

    onActiveChanged: {
        if (!active) {
            Notes.flush()
            return
        }
        mode = "main"
        query = ""
        calc = ""
    }

    // Called once by the shell: a singleton is created on first use, and its IPC target must exist from the start.
    function start() {}

    function open(text) {
        const mon = Hyprland.focusedMonitor
        const name = mon ? mon.name : (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "")
        PanelState.open("utility", -1, name, false)
        mode = "main"
        query = text || ""
        PanelState.typing = true
        PanelState.typed()
    }

    function openClipboard() {
        open("")
        enterClip()
    }

    function openNotes() {
        open("")
        enterNotes()
    }

    function close() { if (active) PanelState.dismiss("utility") }


    function toggle() { active ? close() : open("") }

    // ---- Calculator -------------------------------------------------------------------------------

    function expression(q) { return q.trim().replace(/^=\s*/, "") }

    // A query is worth sending to qalc when it has a digit and an operator, a space or a bracket ("7zip" stays an app name);
    // a leading "=" forces it.
    function isMath(q) {
        const t = q.trim()
        if (t.startsWith("=")) return expression(t) !== ""
        return /\d/.test(t) && /[\s+\-*\/^%()=!]/.test(t)
    }

    property string asked: ""
    property bool rerun: false

    function evaluate() {
        if (!isMath(query)) { calc = ""; return }
        if (calcProc.running) { rerun = true; return }
        asked = expression(query)
        calcProc.command = ["hs-calc", asked]
        calcProc.running = true
    }

    onQueryChanged: {
        if (!active) return
        if (mode === "clip") return
        const m = query.match(/^\/(clip|v|notes?|n)\s(.*)$/)
        if (m) {
            if (m[1] === "clip" || m[1] === "v") enterClip()
            else enterNotes()
            query = m[2]
            return
        }
        if (isMath(query)) debounce.restart()
        else calc = ""
    }

    Timer {
        id: debounce
        interval: 200
        onTriggered: root.evaluate()
    }

    function squash(s) { return s.replace(/\s+/g, "").toLowerCase() }

    Process {
        id: calcProc
        stdout: SplitParser {
            onRead: line => {
                if (root.asked !== root.expression(root.query)) return
                try {
                    const r = JSON.parse(line)
                    const res = r.ok ? (r.result || "") : ""
                    root.calc = res !== "" && root.squash(res) !== root.squash(root.asked) ? res : ""
                    root.calcExpr = root.asked
                } catch (e) {
                    root.calc = ""
                }
            }
        }
        onExited: {
            if (!root.rerun) return
            root.rerun = false
            root.evaluate()
        }
    }

    // ---- Applications -----------------------------------------------------------------------------

    function fuzzy(text, q) {
        let ti = 0, gaps = 0, last = -1
        for (let qi = 0; qi < q.length; qi++) {
            const found = text.indexOf(q[qi], ti)
            if (found < 0) return -1
            if (last >= 0) gaps += found - last - 1
            last = found
            ti = found + 1
        }
        return Math.max(1, 30 - gaps)
    }

    function score(entry, q) {
        const name = entry.name.toLowerCase()
        let s = -1
        if (name === q) s = 100
        else if (name.startsWith(q)) s = 80
        else if (name.indexOf(" " + q) >= 0 || name.indexOf("-" + q) >= 0) s = 65
        else if (name.indexOf(q) >= 0) s = 50
        else {
            s = fuzzy(name, q)
            if (s < 0) {
                if ((entry.genericName || "").toLowerCase().indexOf(q) >= 0) s = 20
                else if ((entry.keywords || []).join(" ").toLowerCase().indexOf(q) >= 0) s = 15
                else if ((entry.comment || "").toLowerCase().indexOf(q) >= 0) s = 10
            }
        }
        if (s < 0) return -1
        return s + Math.min(usage[entry.name] || 0, 20) * 0.6
    }

    function search(text, limit) {
        const q = text.trim().toLowerCase()
        const found = []
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue
            const s = score(e, q)
            if (s >= 0) found.push({ entry: e, score: s })
        }
        found.sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name))
        return found.slice(0, limit)
    }

    function frequent(limit) {
        const found = []
        for (const e of DesktopEntries.applications.values) {
            const n = usage[e.name] || 0
            if (!e.noDisplay && n > 0) found.push({ entry: e, n: n })
        }
        found.sort((a, b) => b.n - a.n || a.entry.name.localeCompare(b.entry.name))
        return found.slice(0, limit)
    }

    function appRow(entry) { return { kind: "app", key: "app:" + entry.name, entry: entry, title: entry.name } }

    function build() {
        if (mode === "clip") return clipRows()
        if (mode === "note") return Notes.rows(query)
        const out = []
        if (query.trim() === "") {
            // Idle: the last calculations, then the applications used most.
            for (const h of history.slice(0, 2)) out.push({ kind: "calc", key: "calc:" + h.expr, title: h.result, sub: h.expr, recent: true })
            for (const f of frequent(maxRows - out.length)) out.push(appRow(f.entry))
            return out
        }
        const hasCalc = calc !== ""
        const apps = search(query, maxRows - (hasCalc ? 1 : 0))
        const row = hasCalc ? { kind: "calc", key: "calc:" + calcExpr, title: calc, sub: calcExpr } : null
        // A strong application match stays on top; otherwise the calculation leads.
        if (row && !(apps.length > 0 && apps[0].score >= 65)) out.push(row)
        for (const a of apps) out.push(appRow(a.entry))
        if (row && out.indexOf(row) < 0) out.push(row)
        return out
    }

    // ---- Clipboard --------------------------------------------------------------------------------

    property var clips: []
    property bool clipsLoading: false
    property string previewId: ""
    property string previewText: ""
    property string previewImage: ""
    property string ranId: ""

    // Switches the tab: "main", "clip" or "note". The query starts over.
    function setMode(m) {
        if (m === mode) return
        query = ""
        if (m === "clip") enterClip()
        else if (m === "note") enterNotes()
        else leaveMode()
    }

    function enterClip() {
        mode = "clip"
        calc = ""
        clips = []
        clipsLoading = true
        clipProc.running = true
    }

    function enterNotes() {
        mode = "note"
        calc = ""
        Notes.reload()
    }

    function leaveMode() {
        mode = "main"
        previewId = ""
        Notes.open("")
    }

    Connections {
        target: Notes
        function onCreated(path) {
            root.selectKey = "note:" + path
            root.editRequested()
        }
    }

    function clipRows() {
        const q = query.trim().toLowerCase()
        const out = []
        for (const c of clips) {
            if (q !== "" && c.title.toLowerCase().indexOf(q) < 0 && (c.meta || "").toLowerCase().indexOf(q) < 0) continue
            out.push({ kind: "clip", key: "clip:" + c.id, id: c.id, ctype: c.kind, title: c.title, meta: c.meta || "", color: c.color || "" })
        }
        return out
    }

    // Loads what the right pane shows for the selected row: the whole text, or the decoded image file.
    function loadPreview(row) {
        Notes.open(row && row.kind === "note" ? row.path : "")
        if (!row || row.kind !== "clip" || row.ctype === "color") { previewId = ""; return }
        if (previewId === row.id) return
        previewId = row.id
        previewText = ""
        previewImage = ""
        runPreview()
    }

    function runPreview() {
        if (previewProc.running || previewId === "") return
        const row = clips.find(c => c.id === previewId)
        if (!row) return
        ranId = previewId
        previewProc.command = ["hs-clip", row.kind === "image" ? "image" : "text", ranId]
        previewProc.running = true
    }

    function removeClip(id) {
        Quickshell.execDetached(["hs-clip", "delete", id])
        clips = clips.filter(c => c.id !== id)
        if (previewId === id) previewId = ""
    }

    function clearClips() {
        Quickshell.execDetached(["hs-clip", "clear"])
        clips = []
        previewId = ""
    }

    Process {
        id: clipProc
        command: ["hs-clip", "list", "200"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.split("\n")) {
                    if (line === "") continue
                    try { out.push(JSON.parse(line)) } catch (e) {}
                }
                root.clips = out
                root.clipsLoading = false
            }
        }
    }

    Process {
        id: previewProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.ranId !== root.previewId) return
                const row = root.clips.find(c => c.id === root.ranId)
                if (row && row.kind === "image") root.previewImage = text.trim()
                else root.previewText = text.replace(/^\s+/, "")
            }
        }
        onExited: if (root.ranId !== root.previewId) root.runPreview()
    }

    function record(key) {
        const next = Object.assign({}, usage)
        next[key] = (next[key] || 0) + 1
        usage = next
        usageStore.setText(JSON.stringify(next))
    }

    function launch(entry) {
        record(entry.name)
        close()
        if (entry.runInTerminal) Quickshell.execDetached(["kitty", "-e"].concat(entry.command))
        else entry.execute()
    }

    function activate(row) {
        if (!row) return
        if (row.kind === "app") { launch(row.entry); return }
        if (row.kind === "note") { editRequested(); return }
        if (row.kind === "newnote") { Notes.create(row.title); return }
        if (row.kind === "clip") {
            Quickshell.execDetached(["hs-clip", "copy", row.id])
            close()
            return
        }
        Quickshell.execDetached(["wl-copy", "--", row.title])
        const next = history.filter(h => h.result !== row.title || h.expr !== row.sub)
        next.unshift({ expr: row.sub, result: row.title })
        history = next.slice(0, 5)
        historyStore.setText(JSON.stringify({ history: history }))
        close()
    }

    FileView {
        id: usageStore
        path: Quickshell.env("HOME") + "/.local/state/hypr-shell/launcher.json"
        printErrors: false
        onLoaded: {
            try { root.usage = JSON.parse(text()) } catch (e) { root.usage = ({}) }
        }
    }

    FileView {
        id: historyStore
        path: Quickshell.env("HOME") + "/.local/state/hypr-shell/omnibox.json"
        printErrors: false
        onLoaded: {
            try { root.history = JSON.parse(text()).history || [] } catch (e) { root.history = [] }
        }
    }

    IpcHandler {
        target: "omnibox"
        function toggle(): void { root.toggle() }
        function open(): void { root.open("") }
        function close(): void { root.close() }
        function search(text: string): void { root.open(text) }
        function clipboard(): void { root.openClipboard() }
        function notes(): void { root.openNotes() }
    }
}
