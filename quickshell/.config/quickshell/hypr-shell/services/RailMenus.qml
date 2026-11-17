pragma Singleton

import QtQuick

// The tool menus of the left strip, grouped into categories: hovering a category on the strip unfolds its options
// (the "menu" flyout) and hovering an option opens its branch (Branch<Kind>.qml) in place of the flyout.
QtObject {
    // `layout` picks how the flyout draws a category: rows (icon, name and a line of what it does), hero (the first option big,
    // the others as tiles under it) or grid (equal tiles). `short` is the label of an option when it is drawn as a tile.
    readonly property var categories: [
        { id: "windows", icon: "tabWindows", title: "Windows", layout: "rows", options: [
            { kind: "layout", icon: "layout", label: "Layout", hint: "Columns, gaps, floating" },
            { kind: "wsview", icon: "layers", label: "Workspaces", hint: "Overview and moving" },
            { kind: "gamemode", icon: "gamepad", label: "Game mode", hint: "Faster, fewer effects" }
        ] },
        { id: "quick", icon: "tabQuick", title: "Quick", layout: "hero", options: [
            { kind: "toggles", icon: "tabQuick", label: "Toggles", hint: "Theme, DND, Wi-Fi and more" },
            { kind: "nightlight", icon: "moon", label: "Night light", short: "Night light", hint: "Warmer screen" },
            { kind: "timer", icon: "timer", label: "Timer", short: "Timer", hint: "Countdown and stopwatch" }
        ] },
        { id: "tools", icon: "tabTools", title: "Tools", layout: "grid", options: [
            { kind: "picker", icon: "pipette", label: "Color picker", short: "Picker", hint: "Pick or paint colors" },
            { kind: "emoji", icon: "smile", label: "Emoji", short: "Emoji", hint: "Search and insert" },
            { kind: "notes", icon: "note", label: "Notes", short: "Notes", hint: "Quick notes and stickies" }
        ] },
        { id: "files", icon: "tabFiles", title: "Files", layout: "hero", options: [
            { kind: "drives", icon: "usb", label: "Drives", hint: "Write ISO, format, browse" },
            { kind: "recent", icon: "folder", label: "Recent folders", short: "Recent folders", hint: "Folders you used lately" }
        ] },
        { id: "shell", icon: "tabShell", title: "Shell", layout: "grid", options: [
            { kind: "railedit", icon: "sliders", label: "Edit strip", short: "Edit strip", hint: "Order and zones" },
            { kind: "oled", icon: "monitor", label: "OLED care", short: "OLED care", hint: "Dimming and drift" }
        ] }
    ]

    // A short live value shown next to an option ("On", "3800 K", a running time); empty when there is nothing to say.
    function stateOf(kind) {
        if (kind === "gamemode") return GameMode.on ? "On" : "Off"
        if (kind === "nightlight") return NightLight.on ? NightLight.shownKelvin + " K" : "Off"
        if (kind === "timer") return TimerService.running ? TimerService.remainingText : ""
        if (kind === "drives" && Drives.writing) return Math.floor(Drives.writeRatio * 100) + "%"
        if (kind === "drives" && IsoMirror.downloading && IsoMirror.dlTotal > 0) return Math.floor(IsoMirror.dlRatio * 100) + "%"
        if (kind === "drives") return Drives.hasDrives ? Drives.drives.length + (Drives.drives.length === 1 ? " drive" : " drives") : "None"
        if (kind === "layout") return WinCtl.layout.length > 0 ? WinCtl.layout.charAt(0).toUpperCase() + WinCtl.layout.slice(1) : ""
        return ""
    }

    // ---- Category indicators ----
    // A category tab shows a dot while one of its options is "on" (game mode running, a timer counting down,
    // night light active).
    //  Each service says when its option is on; `activeKinds` below lists the kinds that are on right now.
    //  A service may also report itself at runtime with RailMenus.setActive("timer", true) (no import needed there).
    readonly property var activeKinds: [].concat(GameMode.on ? ["gamemode"] : [])
        .concat(TimerService.running ? ["timer"] : []).concat(Drives.writing || IsoMirror.downloading ? ["drives"] : []).concat(NightLight.on ? ["nightlight"] : [])
    property var flags: ({})

    function setActive(kind, on) {
        if (!!flags[kind] === !!on) return
        const f = Object.assign({}, flags)
        if (on) f[kind] = true
        else delete f[kind]
        flags = f
    }

    function kindActive(kind) { return activeKinds.indexOf(kind) >= 0 || flags[kind] === true }

    function categoryActive(id) {
        for (const o of category(id).options) if (kindActive(o.kind)) return true
        return false
    }

    function category(id) {
        for (const c of categories) if (c.id === id) return c
        return categories[0]
    }
}
