pragma Singleton

import QtQuick
import Quickshell
import qs.theme

// Single list of all settings. A new setting is one line here: the page, search and highlight pick it up automatically.
Singleton {
    id: root

    readonly property var pages: [
        { id: "colors", title: "Colors", schema: true },
        { id: "shapes", title: "Shapes", schema: true },
        { id: "glass", title: "Glass", schema: true },
        { id: "panel", title: "Panel", schema: true },
        { id: "motion", title: "Motion & fonts", schema: true },
        { id: "wallpaper", title: "Wallpapers", source: "pages/WallpaperPage.qml" },
        { id: "network", title: "Network", source: "pages/NetworkPage.qml" },
        { id: "bluetooth", title: "Bluetooth", source: "pages/BluetoothPage.qml" },
        { id: "sound", title: "Sound", source: "pages/SoundPage.qml" }
    ]

    readonly property var collapsedSections: ["Blur tuning", "Advanced"]

    // Duo settings only matter on black-and-color wallpapers; elsewhere the frame is neutral and they are hidden.
    readonly property bool frameDuo: Theme.wallcolorType === "duo"

    // Whether a row is shown at all: some depend on the wallpaper or on the layout mode.
    function shown(it) {
        if (it.duoOnly && !frameDuo) return false
        if (it.legacyOnly && Theme.cfg.panel.railFlush) return false
        return true
    }

    function pageTitle(id) {
        for (const p of pages) if (p.id === id) return p.title
        return id
    }

    function row(type, page, section, group, key, title, o) {
        return Object.assign({
            id: group + "." + key, page, type, section, group, key, title, description: "", keywords: ""
        }, o)
    }

    function slider(page, section, group, key, title, o) {
        return row("slider", page, section, group, key, title, Object.assign({ from: 0, to: 1, step: 0.01, decimals: 0, scale: 1, suffix: "" }, o))
    }

    function toggle(page, section, group, key, title, o) { return row("toggle", page, section, group, key, title, o) }
    function text(page, section, group, key, title, o) { return row("text", page, section, group, key, title, o) }
    function choice(page, section, group, key, title, options, o) { return row("choice", page, section, group, key, title, Object.assign({ options }, o)) }

    // A visual block: `preview` is the name of a component in components/ that draws it (and may edit settings itself).
    function preview(page, section, id, name, title, keywords) {
        return { id, page, type: "preview", preview: name, section, title, description: "", keywords }
    }

    function link(page, id, title, keywords) {
        return { id, page, type: "link", section: pageTitle(page), title, description: "", keywords }
    }

    readonly property var items: [
        // Colors
        slider("colors", "Wallpaper colors", "accents", "count", "Colors used", { from: 1, to: 4, step: 1, description: "1 is the main accent alone. 2 adds a secondary accent from the wallpaper, 3 tints the frame with a muted wallpaper color instead of plain gray, 4 tints the surfaces too", keywords: "colors count how many accent secondary muted tint frame wallpaper palette" }),
        slider("colors", "Wallpaper colors", "accents", "tint", "Muted tint", { from: 0, to: 0.3, scale: 100, suffix: " %", description: "How much of the wallpaper color the gray frame takes (needs 3 or more colors, and the Muted frame color)", keywords: "tint muted frame gray color strength" }),
        preview("colors", "Wallpaper colors", "accents.preview", "ColorRolesPreview", "Color scheme", "colors scheme preview swatches accent secondary muted"),
        preview("colors", "Palette", "theme.preset", "PaletteGallery", "Color palette", "palette colors preset matugen material you catppuccin tokyo nord wallpaper"),
        choice("colors", "Palette", "theme", "mode", "Color mode", [
            { value: "auto", label: "Auto (light for light wallpapers)" },
            { value: "dark", label: "Dark" },
            { value: "light", label: "Light" }
        ], { description: "Dark or light Material You scheme (wallpaper palette only). Auto picks light when the wallpaper has a light background", keywords: "dark light mode" }),
        choice("colors", "Advanced", "theme", "schemeType", "Accent style", [
            { value: "auto", label: "Automatic (follows the wallpaper)" },
            { value: "scheme-tonal-spot", label: "Tonal spot" },
            { value: "scheme-content", label: "Content" },
            { value: "scheme-expressive", label: "Expressive" },
            { value: "scheme-fidelity", label: "Fidelity" },
            { value: "scheme-monochrome", label: "Monochrome" },
            { value: "scheme-neutral", label: "Neutral" },
            { value: "scheme-rainbow", label: "Rainbow" },
            { value: "scheme-vibrant", label: "Vibrant" },
            { value: "scheme-smart", label: "Smart" }
        ], { description: "How matugen derives the accent from the wallpaper", keywords: "scheme type accent style tonal spot material you matugen" }),

        // Shapes
        preview("shapes", "Layout", "shapes.preview", "ScreenPreview", "Screen layout", "layout screen preview frame windows gaps rounding corners"),
        toggle("shapes", "Layout", "panel", "railFlush", "Screen frame", { description: "A frame around the whole screen with a thin strip on the left that holds all controls", keywords: "panel rail flush edge strip frame thin" }),
        slider("shapes", "Layout", "panel", "frameWidth", "Frame thickness", { from: 0, to: 16, step: 1, suffix: " px", keywords: "frame border thickness edge" }),
        slider("shapes", "Layout", "panel", "screenRadius", "Screen corner radius", { from: 8, to: 40, step: 1, suffix: " px", keywords: "screen corner radius round pill tile" }),
        slider("shapes", "Layout", "panel", "cornerInset", "Corner buttons inset", { from: 0, to: 60, step: 1, suffix: " px", description: "How far the distro logo and the power button sit from the top and bottom screen edges", keywords: "logo power button corner inset distro top bottom move" }),
        slider("shapes", "Layout", "window", "rounding", "Rounding", { from: 0, to: 28, step: 1, suffix: " px", keywords: "corners radius rounding corner" }),
        slider("shapes", "Layout", "window", "roundingPower", "Corner shape", { from: 2, to: 6, step: 1, description: "2 is a plain arc, 4 is a superellipse", keywords: "superellipse squircle" }),
        slider("shapes", "Layout", "window", "gapsIn", "Gap between windows", { from: 0, to: 24, step: 1, suffix: " px", keywords: "gaps spacing" }),
        slider("shapes", "Layout", "window", "gapsOut", "Gap from screen edge", { from: 0, to: 48, step: 1, suffix: " px", keywords: "gaps margin" }),
        toggle("shapes", "Layout", "window", "roundingFollowScreen", "Match screen corners", { description: "With the screen frame on, the window corner radius is computed so the gap to the frame stays constant around the corner. The rounding above then only sets the shell's own elements", keywords: "corners radius concentric screen round" }),
        slider("shapes", "Layout", "window", "cornerFit", "Even corner gap", { scale: 100, suffix: " %", description: "0% gives rounder windows with a slightly thicker gap in the corners, 100% keeps the gap even but the corners get squarer", keywords: "corners gap thickness round square fit" }),

        preview("shapes", "Frame color", "glass.surfaceColor", "FrameColorPicker", "Frame color", "panel color frame accent black gray muted wallpaper"),
        choice("shapes", "Frame color", "glow", "color", "Glow color", [
            { value: "bright", label: "Brighter than frame" },
            { value: "frame", label: "Frame color" },
            { value: "black", label: "Black" }
        ], { description: "A soft bloom along the frame edge: a brighter version of the frame hue, the frame color itself, or black", keywords: "glow frame color bloom edge accent bright black" }),
        slider("shapes", "Frame color", "glow", "strength", "Glow strength", { scale: 100, suffix: " %", description: "Opacity of the glow; 0 turns it off", keywords: "glow strength opacity intensity" }),
        slider("shapes", "Frame color", "glow", "brightness", "Glow brightness", { scale: 100, suffix: " %", description: "Extra brightness for the brighter preset", keywords: "glow brightness lighten" }),

        slider("shapes", "Shadow", "shadow", "strength", "Shadow strength", { scale: 100, suffix: " %", description: "A soft shadow that lifts the frame and the dashboards off the desktop; 0 turns it off", keywords: "shadow depth float drop lift" }),
        slider("shapes", "Shadow", "shadow", "size", "Shadow softness", { scale: 100, suffix: " %", keywords: "shadow blur soft spread" }),

        toggle("shapes", "Focused window", "focus", "enabled", "Focus outline", { description: "A colored edge on the window that has the keyboard focus", keywords: "window border outline focus active edge enable disable on off" }),
        preview("shapes", "Focused window", "focus.preview", "FocusOutlinePreview", "Focus outline", "window border outline focus active gradient color preview"),
        slider("shapes", "Focused window", "focus", "size", "Thickness", { from: 1, to: 6, step: 1, suffix: " px", keywords: "focus outline border thickness width" }),
        slider("shapes", "Focused window", "focus", "colors", "Colors", { from: 1, to: 3, step: 1, description: "1 is the main wallpaper color, 2 adds the third color, 3 adds the second", keywords: "focus outline border colors count gradient" }),
        slider("shapes", "Focused window", "focus", "lightness", "Brightness", { from: 0.3, to: 0.85, step: 0.01, scale: 100, suffix: " %", keywords: "focus outline border brightness lightness bright dark" }),
        slider("shapes", "Focused window", "focus", "saturation", "Saturation", { from: 0.2, to: 1, step: 0.01, scale: 100, suffix: " %", description: "Low values wash the color toward white or gray", keywords: "focus outline border saturation vivid pale white color" }),
        slider("shapes", "Focused window", "focus", "shade", "Shading", { from: 0, to: 0.3, step: 0.01, scale: 100, suffix: " %", description: "How far each color swings lighter and darker around the edge; 0 is a flat color", keywords: "focus outline border gradient shade contrast" }),
        slider("shapes", "Focused window", "focus", "angle", "Angle", { from: 0, to: 360, step: 15, suffix: "°", keywords: "focus outline border gradient angle direction" }),
        slider("shapes", "Focused window", "focus", "opacity", "Opacity", { from: 0.3, to: 1, step: 0.05, scale: 100, suffix: " %", keywords: "focus outline border opacity transparent" }),

        preview("shapes", "Borders", "border.preview", "BorderPreview", "Borders", "border outline focus active inactive"),
        slider("shapes", "Borders", "border", "active", "Active border", { scale: 100, suffix: " %", keywords: "border frame brightness" }),
        slider("shapes", "Borders", "border", "inactive", "Inactive border", { scale: 100, suffix: " %", keywords: "border frame" }),

        // Glass
        choice("glass", "Design", "design", "mode", "Design mode", [
            { value: "glass", label: "Transparent (glass)" },
            { value: "solid", label: "Opaque (solid)" }
        ], { description: "Glass is translucent and blurred, for photos. Solid is flat and opaque in the wallpaper's background color. Also a switch in the Quick menu; the terminal stays transparent in both", keywords: "design mode style glass solid flat opaque transparent caelestia" }),
        preview("glass", "Design", "design.preview", "SolidPreview", "Solid design preview", "solid design preview flat opaque frame layers outlines"),
        choice("glass", "Design", "design", "frame", "Solid frame color", [
            { value: "wallpaper", label: "Wallpaper background" },
            { value: "scheme", label: "Color scheme" }
        ], { description: "Where the solid frame takes its color: the wallpaper's flat background, or the scheme's surface tone", keywords: "solid frame color wallpaper scheme surface" }),
        choice("glass", "Design", "design", "layers", "Solid layers", [
            { value: "tonal", label: "Tonal steps" },
            { value: "veil", label: "White veils" }
        ], { description: "Tonal steps use the scheme's own surface tones for cards, tiles and buttons; white veils keep the glass look", keywords: "solid layers tonal veil surface container" }),
        choice("glass", "Design", "design", "outlines", "Solid outlines", [
            { value: "none", label: "None" },
            { value: "subtle", label: "Subtle" }
        ], { description: "Outlines around cards, the frame cutout and fields; none separates by tone only", keywords: "solid outlines border lines" }),
        preview("glass", "Panel glass", "glass.preview", "GlassPreview", "Panel glass", "glass panel transparency opacity blur frosted preview"),
        slider("glass", "Panel glass", "glass", "opacity", "Panel opacity", { from: 0.4, to: 1, scale: 100, suffix: " %", description: "How transparent the panel and its branches are", keywords: "transparency opacity glass panel background" }),
        preview("glass", "Terminal", "terminal.preview", "TerminalPreview", "Terminal", "terminal kitty preview transparency blur"),
        slider("glass", "Terminal", "terminal", "opacity", "Terminal opacity (glass)", { from: 0.1, to: 1, scale: 100, suffix: " %", description: "Terminal density in the transparent design; low keeps it almost invisible", keywords: "terminal kitty opacity transparency" }),
        slider("glass", "Terminal", "terminal", "solidOpacity", "Terminal opacity (solid)", { from: 0.4, to: 1, scale: 100, suffix: " %", description: "Terminal density in the opaque design, tinted with the system color", keywords: "terminal kitty opacity transparency solid" }),
        slider("glass", "Terminal", "terminal", "tint", "Terminal tint", { from: 0, to: 0.4, step: 0.01, scale: 100, suffix: " %", description: "How much color the terminal body takes from the wallpaper. 0 is plain gray, low values give a gray with a hint of hue", keywords: "terminal kitty tint saturation color hue gray wallpaper" }),
        toggle("glass", "Terminal", "terminal", "blur", "Terminal blur", { description: "Blur the wallpaper behind the transparent terminal. Off keeps it sharp", keywords: "terminal kitty blur frosted sharp" }),
        preview("glass", "Lock screen", "lock.preview", "LockPreview", "Lock screen", "lock screen preview background blur wallpaper"),
        preview("glass", "Lock screen", "lock.dotShape", "LockDotsPreview", "Password marks", "lock screen password dots marks shape square circle bar diamond"),
        slider("glass", "Lock screen", "lock", "dotSize", "Mark size", { from: 10, to: 32, step: 1, suffix: " px", description: "Long passwords shrink the marks so the row stays inside the field", keywords: "lock screen password dots marks size" }),
        slider("glass", "Lock screen", "lock", "blur", "Background blur", { description: "How strongly the wallpaper is blurred behind the lock card", scale: 100, suffix: " %", keywords: "lock screen background blur wallpaper blur radius" }),
        slider("glass", "Panel glass", "blur", "vibrancy", "Vibrancy", { to: 1, description: "Lets the colors of the wallpaper glow through the blur instead of washing out", keywords: "vibrancy glass color saturation blur wallpaper" }),
        slider("glass", "Vignette", "vignette", "strength", "Vignette", { to: 0.4, scale: 100, suffix: " %", description: "A faint darkening toward the screen edges, under the windows", keywords: "vignette edges dark corners shade" }),
        slider("glass", "Blur tuning", "blur", "size", "Blur radius", { from: 1, to: 20, step: 1, keywords: "blur" }),
        slider("glass", "Blur tuning", "blur", "passes", "Passes", { from: 1, to: 6, step: 1, keywords: "blur quality" }),
        slider("glass", "Blur tuning", "blur", "noise", "Grain", { to: 0.15, step: 0.005, decimals: 3, keywords: "noise grain matte" }),
        slider("glass", "Blur tuning", "blur", "vibrancyDarkness", "Vibrancy darkness", { to: 0.5, decimals: 2, keywords: "vibrancy darkness" }),
        slider("glass", "Blur tuning", "blur", "contrast", "Contrast", { from: 0.5, to: 1.5, decimals: 2, keywords: "blur contrast" }),
        slider("glass", "Blur tuning", "blur", "brightness", "Brightness", { from: 0.3, to: 1.3, decimals: 2, keywords: "blur brightness" }),

        // Panel
        preview("panel", "Edge hot zones", "dashboard.hotZones", "HotZonesPreview", "Edge hot zones", "dashboard control center search utility edge hover hot zone open top right bottom"),
        preview("panel", "Dock", "dock.pinned", "DockEditor", "Pinned apps", "dock pinned apps applications favorites launcher"),
        text("panel", "Weather", "dashboard", "weatherCity", "Weather city", { allowEmpty: true, placeholder: "Detect automatically", description: "Type the name in any language; it is shown in English. Empty finds the place by IP, which follows your VPN exit", keywords: "weather city location place forecast china russia" }),
        choice("panel", "Weather", "dashboard", "weatherUnits", "Temperature units", [{ value: "metric", label: "Celsius, km/h" }, { value: "imperial", label: "Fahrenheit, mph" }], { keywords: "weather temperature units celsius fahrenheit" }),
        choice("panel", "Weather", "dashboard", "weatherSource", "Weather source", [
            { value: "auto", label: "Automatic" }, { value: "cma", label: "CMA (China)" }, { value: "openmeteo", label: "Open-Meteo" },
            { value: "metno", label: "MET Norway" }, { value: "wttr", label: "wttr.in" }
        ], { description: "Automatic tries CMA first in China, then Open-Meteo, MET Norway and wttr.in until one answers", keywords: "weather source provider api cma open-meteo yr" }),
        text("panel", "Notes", "notes", "dir", "Notes folder", { description: "Quick notes are plain .md files here; point it into an Obsidian vault to see them there", keywords: "notes folder directory obsidian markdown sticky" }),
        text("panel", "Drives", "drives", "isoDir", "ISO folder", { description: "Images here show up in the Drives menu, ready to write to a USB stick", keywords: "iso image usb flash write distro folder drives" }),
        choice("panel", "Drives", "drives", "onConnect", "When a drive is plugged in", [
            { value: "nothing", label: "Nothing" }, { value: "menu", label: "Open menu" },
            { value: "mount", label: "Mount" }, { value: "files", label: "Open files" }
        ], { description: "The strip icon always lights up; this adds one more step", keywords: "usb plug connect automount auto open" }),
        toggle("panel", "Drives", "drives", "autoImport", "Import photos from camera cards", { description: "New photos and videos in DCIM are copied as soon as the card shows up", keywords: "camera sd card dcim photos import auto" }),
        text("panel", "Drives", "drives", "importDir", "Photo import folder", { description: "Imported photos land here, one folder per day", keywords: "camera photos import folder dcim" }),
        preview("panel", "Screenshots", "screenshot.preview", "ScreenshotNamePreview", "Screenshot files", "screenshot folder file name template save"),
        text("panel", "Screenshots", "screenshot", "dir", "Folder", { description: "Where Save puts screenshots; the folder is created when missing", keywords: "screenshot folder directory pictures save" }),
        text("panel", "Screenshots", "screenshot", "filename", "File name", { description: "A template: %Y year, %m month, %d day, %H hour, %M minute, %S second", keywords: "screenshot file name template date time" }),
        slider("panel", "OLED care", "oled", "shift", "Strip drift", { from: 0, to: 2, step: 1, suffix: " px", description: "The strip slowly moves by this much so no pixel stays lit in the same place", keywords: "oled burn in drift shift pixel" }),
        slider("panel", "OLED care", "oled", "dimAfter", "Dim after", { from: 0, to: 60, step: 1, suffix: " min", description: "The strip and the frame glow dim after this long without input; 0 turns it off", keywords: "oled burn in dim idle strip" }),
        slider("panel", "OLED care", "oled", "dimLevel", "Dim level", { from: 0.1, to: 0.9, scale: 100, suffix: " %", keywords: "oled dim brightness level" }),
        slider("panel", "OLED care", "oled", "hideAfter", "Fade out after", { from: 0, to: 180, step: 5, suffix: " min", description: "The strip fades out completely after this long without input; 0 keeps it dimmed only", keywords: "oled hide fade idle strip" }),
        toggle("panel", "Legacy layout", "panel", "joined", "L-shaped panel", { legacyOnly: true, description: "The left and bottom panels merge into one. The position sliders have no effect in this mode", keywords: "panel merge shape joined split" }),
        slider("panel", "Legacy layout", "panel", "offsetX", "Bottom panel: left to right", { legacyOnly: true, from: -1, to: 1, scale: 100, suffix: " %", keywords: "panel shift position horizontal offset" }),
        slider("panel", "Legacy layout", "panel", "offsetY", "Left panel: up to down", { legacyOnly: true, from: -1, to: 1, scale: 100, suffix: " %", keywords: "panel shift position vertical offset" }),

        // Motion and fonts
        preview("motion", "Window animation", "motion.windowStyle", "WindowAnimPreview", "Opening and closing", "window animation open close style pop popin slide genie gnomed fade preview"),
        slider("motion", "Window animation", "motion", "windowOpen", "Opening speed", { description: "How long a new window takes to appear", from: 100, to: 800, step: 10, suffix: " ms", keywords: "window animation speed open duration slow" }),
        slider("motion", "Window animation", "motion", "windowClose", "Closing speed", { description: "How long a closing window takes to leave", from: 80, to: 600, step: 10, suffix: " ms", keywords: "window animation speed close duration" }),
        slider("motion", "Window animation", "motion", "windowScale", "Start size", { description: "How small a window starts when it pops in (Pop style only)", from: 60, to: 99, step: 1, suffix: " %", keywords: "window animation pop scale size start" }),
        preview("motion", "Motion", "motion.preview", "MotionPreview", "Interface speed", "motion animation speed duration preview easing"),
        slider("motion", "Motion", "motion", "fast", "Fast", { description: "Hover and small controls", from: 50, to: 400, step: 10, suffix: " ms", keywords: "animations speed animation" }),
        slider("motion", "Motion", "motion", "normal", "Normal", { description: "Menus and focus", from: 50, to: 400, step: 10, suffix: " ms", keywords: "animations speed animation" }),
        slider("motion", "Motion", "motion", "slow", "Smooth", { description: "Workspace switching", from: 50, to: 600, step: 10, suffix: " ms", keywords: "animations speed animation" }),
        slider("motion", "Motion", "motion", "spring", "Bounce", { description: "How much things overshoot and settle back, in the shell and for windows (0 is a plain ease-out)", from: 0, to: 1, step: 0.05, scale: 100, suffix: " %", keywords: "spring bounce springy overshoot elastic animation" }),
        preview("motion", "Fonts", "fonts.preview", "FontPreview", "Fonts", "font typeface preview text"),
        text("motion", "Fonts", "fonts", "ui", "Interface", { keywords: "font" }),
        text("motion", "Fonts", "fonts", "mono", "Monospace", { keywords: "font terminal" }),

        link("wallpaper", "wallpaper", "Wallpapers", "wallpaper background image palette colors accent"),
        link("network", "wifi", "Wi-Fi", "wifi network internet wireless connect password"),
        link("bluetooth", "bluetooth", "Bluetooth", "bluetooth headphones devices connect"),
        link("sound", "volume", "Volume and devices", "sound volume speakers headphones microphone output input")
    ]

    function score(item, tokens) {
        const title = item.title.toLowerCase()
        const rest = [item.section, item.description, item.keywords, pageTitle(item.page)].join(" ").toLowerCase()
        let total = 0
        for (const t of tokens) {
            if (title.startsWith(t)) total += 100
            else if (title.indexOf(t) >= 0) total += 80
            else if (item.keywords.toLowerCase().indexOf(t) >= 0) total += 50
            else if (rest.indexOf(t) >= 0) total += 25
            else return -1
        }
        return total
    }

    function search(query) {
        const tokens = query.toLowerCase().split(/\s+/).filter(t => t !== "")
        if (tokens.length === 0) return []
        const found = []
        for (const it of items) {
            if (!root.shown(it)) continue
            const s = score(it, tokens)
            if (s >= 0) found.push({ item: it, score: s })
        }
        found.sort((a, b) => b.score - a.score)
        return found.slice(0, 9).map(f => f.item)
    }
}
