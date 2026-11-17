pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Lyrics of the current track from LRCLIB (lrclib.net: free, no key). Synced lyrics come as timed lines, plain
// ones as text. Looked up only while something shows them (`wanted`), cached on disk per track.
Singleton {
    id: root

    // Set by the views that show lyrics; nothing is fetched while it is false.
    property bool wanted: false
    // Shift in seconds for lyrics that run early or late (per session, reset on track change).
    property real offset: 0

    // idle | loading | synced | plain | none | error
    property string status: "idle"
    property string error: ""
    property var lines: []          // [{ t: seconds, text }]
    property string plain: ""
    property string loadedKey: ""

    readonly property bool synced: status === "synced"
    readonly property bool has: status === "synced" || status === "plain"

    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/hypr-shell/lyrics"

    // The track as LRCLIB knows it: browser players put "Artist - Title (Official Video)" in the title.
    readonly property var track: {
        if (!Players.has) return null
        let title = Players.player.trackTitle || ""
        let artist = (Players.artist || "").replace(/\s*-\s*Topic$/i, "").replace(/VEVO$/i, "").trim()
        title = title.replace(/\s*[\(\[][^\)\]]*(official|video|audio|lyric|visuali[sz]er|remaster|hd|4k|mv|clip)[^\)\]]*[\)\]]/gi, "")
            .replace(/\s*\|.*$/, "").trim()
        const dash = title.match(/^(.+?)\s+[-–—]\s+(.+)$/)
        const squash = t => t.toLowerCase().replace(/[^a-z0-9а-яё]+/g, "")
        if (dash && (artist === "" || squash(dash[1]).indexOf(squash(artist)) >= 0 || squash(artist).indexOf(squash(dash[1])) >= 0)) {
            artist = dash[1].trim()
            title = dash[2].trim()
        }
        title = title.replace(/\s+(feat\.?|ft\.?)\s.*$/i, "").trim()
        if (title === "") return null
        const len = Players.player.lengthSupported && Players.player.length > 0 ? Math.round(Players.player.length) : 0
        return { title: title, artist: artist, album: Players.album || "", length: len }
    }
    readonly property string key: track ? (track.artist + "|" + track.title).toLowerCase() : ""

    // Playback position, sampled while lyrics are shown (MPRIS does not push it; reading it is local).
    property real position: 0
    Timer {
        running: root.wanted && root.synced && Players.playing
        interval: 200
        repeat: true
        triggeredOnStart: true
        onTriggered: { Players.refreshPosition(); root.position = Players.player.position }
    }
    Connections {
        target: Players
        function onPlayingChanged() { if (Players.has) { Players.refreshPosition(); root.position = Players.player.position } }
    }

    // Index of the line being sung, -1 before the first one.
    readonly property int current: indexAt(position)

    // Line sung at playback time p (seconds), -1 before the first one.
    function indexAt(p) {
        if (!synced) return -1
        p += offset
        let lo = 0, hi = lines.length - 1, ans = -1
        while (lo <= hi) {
            const mid = (lo + hi) >> 1
            if (lines[mid].t <= p) { ans = mid; lo = mid + 1 } else hi = mid - 1
        }
        return ans
    }

    // How far line i has been sung at time p, 0..1 (the last line counts as 4 s long).
    function progressAt(i, p) {
        if (!synced || i < 0 || i >= lines.length) return 0
        const start = lines[i].t, end = i + 1 < lines.length ? lines[i + 1].t : start + 4
        return Math.max(0, Math.min(1, (p + offset - start) / Math.max(0.1, end - start)))
    }
    readonly property string currentText: current >= 0 ? lines[current].text : ""

    function seekToLine(i) {
        if (!synced || i < 0 || i >= lines.length || !Players.canSeek) return
        Players.player.position = Math.max(0, lines[i].t - offset + 0.05)
        position = lines[i].t - offset + 0.05
    }

    function nudge(d) { offset = Math.round((offset + d) * 10) / 10 }

    function retry() { loadedKey = ""; settle.restart() }

    onKeyChanged: { offset = 0; settle.restart() }
    onWantedChanged: if (wanted) settle.restart()

    // Players report the new title and artist in separate updates; wait for them to settle.
    Timer {
        id: settle
        interval: 350
        onTriggered: root.load()
    }

    function reset(s) {
        lines = []
        plain = ""
        error = ""
        status = s
    }

    function load() {
        if (!wanted || key === loadedKey) return
        if (!track) { reset("idle"); loadedKey = ""; return }
        loadedKey = key
        reset("loading")
        cache.want = key
        cache.path = cacheDir + "/" + fileName(key) + ".json"
        cache.reload()
    }

    function fileName(k) {
        let h = 5381
        for (let i = 0; i < k.length; i++) h = ((h * 33) ^ k.charCodeAt(i)) >>> 0
        return h.toString(16) + "-" + k.replace(/[^a-z0-9]+/g, "-").slice(0, 60)
    }

    function parseLrc(s) {
        const out = []
        for (const raw of s.split("\n")) {
            const tags = []
            let rest = raw
            let m
            while ((m = rest.match(/^\s*\[(\d+):(\d+(?:\.\d+)?)\]/)) !== null) {
                tags.push(parseInt(m[1]) * 60 + parseFloat(m[2]))
                rest = rest.slice(m[0].length)
            }
            const text = rest.trim()
            for (const t of tags) out.push({ t: t, text: text })
        }
        out.sort((a, b) => a.t - b.t)
        // A long intro gets an empty line of its own, shown as the waiting dots.
        if (out.length > 0 && out[0].t >= 3) out.unshift({ t: 0, text: "" })
        return out
    }

    // Applies one LRCLIB record; returns false when it carries no lyrics.
    function use(rec) {
        if (!rec) return false
        if (rec.instrumental) { reset("plain"); plain = "Instrumental"; return true }
        if (rec.syncedLyrics) {
            const l = parseLrc(rec.syncedLyrics)
            if (l.length > 0) { reset("synced"); lines = l; return true }
        }
        if (rec.plainLyrics) { reset("plain"); plain = rec.plainLyrics.trim(); return true }
        return false
    }

    function store(k, rec) {
        if (k !== loadedKey) return
        writer.command = ["sh", "-c", 'mkdir -p "$1" && printf %s "$3" > "$2"', "sh", cacheDir,
            cacheDir + "/" + fileName(k) + ".json", JSON.stringify(rec || { none: true, at: Date.now() })]
        writer.running = true
    }

    // Best record from a search: synced first, then the closest length.
    function pick(list) {
        if (!Array.isArray(list) || list.length === 0) return null
        const len = track ? track.length : 0
        let best = null, score = -1e9
        for (const r of list) {
            let s = r.syncedLyrics ? 100 : (r.plainLyrics ? 40 : (r.instrumental ? 10 : -100))
            if (len > 0 && r.duration) s -= Math.min(60, Math.abs(r.duration - len))
            if (s > score) { score = s; best = r }
        }
        return score > -100 ? best : null
    }

    FileView {
        id: cache
        property string want: ""
        printErrors: false
        blockLoading: false
        watchChanges: false
        onLoaded: {
            if (want !== root.loadedKey) return
            try {
                const rec = JSON.parse(text())
                // A miss is remembered for a day, then asked again.
                if (rec.none) {
                    if (Date.now() - rec.at < 86400000) { root.reset("none"); return }
                } else if (root.use(rec)) return
            } catch (e) {}
            net.begin(want)
        }
        onLoadFailed: if (want === root.loadedKey) net.begin(want)
    }

    // get (exact) → search by fields → free search; one curl at a time.
    QtObject {
        id: net
        property string k: ""
        property int step: 0

        function begin(key) { k = key; step = 0; next() }

        function next() {
            const t = root.track
            if (!t || k !== root.loadedKey) return
            const base = ["curl", "-sS", "--fail", "-m", "12", "-A", "hypr-shell/0.1 (personal dotfiles)", "-G"]
            let args
            if (step === 0) {
                if (t.artist === "" || t.length === 0) { step = 1; next(); return }
                args = ["https://lrclib.net/api/get", "--data-urlencode", "track_name=" + t.title,
                    "--data-urlencode", "artist_name=" + t.artist, "--data-urlencode", "duration=" + t.length]
                if (t.album !== "") args.push("--data-urlencode", "album_name=" + t.album)
            } else if (step === 1) {
                if (t.artist === "") { step = 2; next(); return }
                args = ["https://lrclib.net/api/search", "--data-urlencode", "track_name=" + t.title,
                    "--data-urlencode", "artist_name=" + t.artist]
            } else {
                args = ["https://lrclib.net/api/search", "--data-urlencode", "q=" + (t.artist + " " + t.title).trim()]
            }
            http.key = k
            http.command = base.concat(args)
            http.running = true
        }
    }

    Process {
        id: http
        property string key: ""
        stdout: StdioCollector { id: body }
        stderr: StdioCollector { id: errs }
        onExited: code => {
            if (key !== root.loadedKey) return
            // 22: HTTP error (404 = not found, go on); anything else is the network.
            if (code !== 0 && code !== 22) {
                root.reset("error")
                root.error = code === 6 || code === 7 || code === 28 ? "No connection to lrclib.net" : "Lyrics lookup failed"
                return
            }
            let rec = null
            if (code === 0) {
                try {
                    const j = JSON.parse(body.text)
                    rec = Array.isArray(j) ? root.pick(j) : j
                } catch (e) {}
            }
            if (rec && root.use(rec)) { root.store(key, rec); return }
            if (net.step < 2) { net.step++; net.next(); return }
            root.reset("none")
            root.store(key, null)
        }
    }

    Process { id: writer }
}
