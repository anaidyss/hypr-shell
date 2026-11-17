pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pam

// State of the lock screen: the typed password, PAM authentication and the OLED dimming.
// `locked` mirrors the real session lock (see modules/lock/Lock.qml); `preview` shows the same card in an
// ordinary overlay window with the same PAM check, so the lock screen can be tried without locking the session.
Singleton {
    id: root

    property bool locked: false
    property bool preview: false
    readonly property bool showing: locked || preview

    property string password: ""
    property bool busy: false
    property string message: ""
    property bool messageIsError: false
    property int failCount: 0
    property bool dimmed: false
    property point shift: Qt.point(0, 0)
    property string wallpaper: ""

    // Keyboard layout as a short code ("EN", "RU"). Hyprland keeps a layout per keyboard and does not say which one is in use,
    // so the code follows the keyboard that switched last and is corrected by the letters actually typed.
    property string layoutCode: ""
    property string lastLayoutKeyboard: ""
    property var layoutByKeyboard: ({})

    function codeOf(name) {
        const codes = { English: "EN", Russian: "RU", Ukrainian: "UA", Belarusian: "BY", Bulgarian: "BG", German: "DE", French: "FR", Spanish: "ES", Italian: "IT", Chinese: "ZH", Japanese: "JA", Korean: "KO", Polish: "PL", Turkish: "TR" }
        const word = name.split(/[ (]/)[0]
        return codes[word] || word.slice(0, 2).toUpperCase()
    }

    function isCyrillic(code) { return ["RU", "UA", "BY", "BG"].indexOf(code) >= 0 }

    // A typed letter shows the real layout: Cyrillic under a Latin code (or the reverse) means the code is stale.
    function noteTyped(ch) {
        if (/[\u0400-\u04FF]/.test(ch)) { if (!isCyrillic(layoutCode)) layoutCode = "RU" }
        else if (/[A-Za-z\u00C0-\u024F]/.test(ch)) { if (layoutCode === "" || isCyrillic(layoutCode)) layoutCode = "EN" }
    }

    signal lockRequested()
    signal unlockRequested()
    signal rejected()
    signal snapshotRequested(string path)

    property string pending: ""
    // Dots shown in the field: what is typed, or what was sent while PAM is checking it.
    property int submittedLength: 0
    readonly property int dotCount: busy ? submittedLength : password.length

    function requestLock() {
        if (locked) return
        reset()
        lockRequested()
    }

    function reset() {
        password = ""
        pending = ""
        busy = false
        message = ""
        messageIsError = false
        failCount = 0
        dimmed = false
        shift = Qt.point(0, 0)
    }

    function markActive() {
        if (!showing) return
        dimmed = false
        dimTimer.restart()
    }

    function type(text) {
        if (busy) return
        if (messageIsError) { message = ""; messageIsError = false }
        if (password.length < 128) password += text
    }

    function backspace() {
        if (busy) return
        password = password.slice(0, -1)
    }

    function clear() {
        if (busy) return
        password = ""
    }

    function submit() {
        if (busy || password === "") return
        pending = password
        submittedLength = password.length
        password = ""
        busy = true
        message = ""
        messageIsError = false
        if (!pam.start()) fail("Authentication is not available")
    }

    function fail(text) {
        busy = false
        pending = ""
        failCount++
        message = text
        messageIsError = true
        rejected()
    }

    function succeed() {
        busy = false
        pending = ""
        const wasPreview = preview
        preview = false
        reset()
        if (!wasPreview) unlockRequested()
    }

    onShowingChanged: {
        if (showing) { dimmed = false; dimTimer.restart(); Toasts.clearUnread(); switcher.running = true }
        else { dimTimer.stop(); dimmed = false }
    }

    function readLayout() {
        if (!devices.running) devices.running = true
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout") return
            const i = event.data.indexOf(",")
            const kb = event.data.slice(0, i)
            if (i < 0 || /virtual/i.test(kb)) return
            const code = root.codeOf(event.data.slice(i + 1))
            const map = Object.assign({}, root.layoutByKeyboard)
            map[kb] = code
            root.layoutByKeyboard = map
            root.lastLayoutKeyboard = kb
            root.layoutCode = code
        }
    }

    // Passwords are typed in Latin, so the lock screen always starts on the first layout (English).
    Process {
        id: switcher
        command: ["hyprctl", "switchxkblayout", "all", "0"]
        onRunningChanged: if (!running) root.readLayout()
    }

    Process {
        id: devices
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(text).keyboards.filter(k => !/virtual|mouse|button|hotkeys|control|video-bus/i.test(k.name))
                    const map = ({})
                    for (const k of list) map[k.name] = root.codeOf(k.active_keymap)
                    root.layoutByKeyboard = map
                    // The keyboard that switched last is the best guess, then the built-in one.
                    const k = list.find(x => x.name === root.lastLayoutKeyboard)
                        || list.find(x => /at-translated|internal|laptop/i.test(x.name))
                        || list.find(x => /keyboard/i.test(x.name)) || list[0]
                    if (k) root.layoutCode = map[k.name]
                } catch (e) {}
            }
        }
    }

    PamContext {
        id: pam
        config: "hs-lock.conf"
        configDirectory: Quickshell.shellPath("pam")

        onPamMessage: {
            if (responseRequired) {
                if (root.pending !== "") {
                    respond(root.pending)
                    root.pending = ""
                } else {
                    abort()
                }
            } else if (message !== "") {
                root.message = message
                root.messageIsError = messageIsError
            }
        }

        onCompleted: result => {
            if (result === PamResult.Success) root.succeed()
            else if (result === PamResult.MaxTries) root.fail("Too many attempts, try again later")
            else if (result === PamResult.Failed) root.fail("Wrong password")
            else root.fail("Authentication failed")
        }

        onError: error => root.fail("Authentication is not available")
    }

    // A conversation that never answers must not leave the field stuck.
    Timer {
        interval: 15000
        running: root.busy
        onTriggered: { pam.abort(); root.fail("Authentication timed out") }
    }

    // OLED: after a while the screen goes nearly black; any input brings it back.
    Timer {
        id: dimTimer
        interval: 45000
        onTriggered: root.dimmed = true
    }

    // OLED: the card drifts a few pixels every half minute so nothing burns in.
    Timer {
        interval: 30000
        repeat: true
        running: root.showing
        onTriggered: root.shift = Qt.point(Math.round((Math.random() - 0.5) * 24), Math.round((Math.random() - 0.5) * 24))
    }

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/hypr-shell/wallpaper"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.wallpaper = text().trim()
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.requestLock() }
        function state(): string { return root.locked ? "locked" : "unlocked" }
        function preview(): void { if (!root.locked) { root.reset(); root.preview = true } }
        function closePreview(): void { if (root.preview) { root.preview = false; root.reset() } }
        function snapshot(path: string): void { root.snapshotRequested(path) }
        // Test aid: types a password into the preview (never into the real lock) and submits it.
        function previewType(text: string): void { if (root.preview && !root.locked) { root.password = text; if (text !== "") root.noteTyped(text.slice(-1)) } }
        function previewTry(text: string): void { if (root.preview && !root.locked) { root.password = text; root.submit() } }
    }
}
