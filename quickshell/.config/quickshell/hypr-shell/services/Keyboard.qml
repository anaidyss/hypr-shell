pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Current keyboard layout as a short code ("EN", "RU"). Hyprland keeps a layout per keyboard and does not say which one is
// in use, so the code follows the keyboard that switched last; at start the built-in keyboard is taken.
Singleton {
    id: root

    property string code: ""
    // Full layout name as Hyprland reports it ("English (US)", "Russian").
    property string name: ""
    property string lastKeyboard: ""
    // A real switch of the layout (not the initial read, not a repeated event from a second keyboard).
    signal switched()

    function codeOf(name) {
        const codes = { English: "EN", Russian: "RU", Ukrainian: "UA", Belarusian: "BY", Bulgarian: "BG", German: "DE", French: "FR", Spanish: "ES", Italian: "IT", Chinese: "ZH", Japanese: "JA", Korean: "KO", Polish: "PL", Turkish: "TR" }
        const word = name.split(/[ (]/)[0]
        return codes[word] || word.slice(0, 2).toUpperCase()
    }

    function next() { switcher.running = true }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout") return
            const i = event.data.indexOf(",")
            const kb = event.data.slice(0, i)
            if (i < 0 || /virtual/i.test(kb)) return
            root.lastKeyboard = kb
            const name = event.data.slice(i + 1)
            const code = root.codeOf(name)
            const changed = root.code !== "" && code !== root.code
            root.code = code
            root.name = name
            if (changed) root.switched()
        }
    }

    Process {
        id: switcher
        command: ["hyprctl", "switchxkblayout", "all", "next"]
    }

    Process {
        id: devices
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(text).keyboards.filter(k => !/virtual|mouse|button|hotkeys|control|video-bus/i.test(k.name))
                    const k = list.find(x => /at-translated|internal|laptop/i.test(x.name)) || list.find(x => /keyboard/i.test(x.name)) || list[0]
                    if (k && root.code === "") {
                        root.code = root.codeOf(k.active_keymap)
                        root.name = k.active_keymap
                    }
                } catch (e) {}
            }
        }
    }
}
