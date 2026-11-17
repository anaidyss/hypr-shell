pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/hypr-shell"
    readonly property string configDir: Quickshell.env("HOME") + "/.config/hypr-shell"

    // Palette (Material You): the full role set comes from the wallpaper via matugen, or from a preset.
    readonly property var colors: palette
    // Colors the user painted over parts of the interface (the color picker's paint mode); transparent when unset.
    readonly property color ovAccent: tokens.overrides.accent !== "" ? tokens.overrides.accent : "transparent"
    readonly property color ovFrame: tokens.overrides.frame !== "" ? tokens.overrides.frame : "transparent"
    readonly property color ovCard: tokens.overrides.card !== "" ? tokens.overrides.card : "transparent"
    readonly property color ovTile: tokens.overrides.tile !== "" ? tokens.overrides.tile : "transparent"
    readonly property color ovPill: tokens.overrides.pill !== "" ? tokens.overrides.pill : "transparent"
    readonly property color ovText: tokens.overrides.text !== "" ? tokens.overrides.text : "transparent"
    readonly property color ovSelected: tokens.overrides.selected !== "" ? tokens.overrides.selected : "transparent"
    readonly property color accent: ovAccent.a > 0 ? ovAccent : palette.primary
    readonly property color accentText: ovAccent.a > 0 ? (ovAccent.hslLightness > 0.55 ? palette.crust : palette.text) : palette.primaryText

    // Color scheme of the shell: one main accent (`accent`), one secondary accent taken from the wallpaper
    // (`accent2`) and two muted tones (gray tinted with the wallpaper hue) for the frame and the surfaces.
    // `accents.count` switches them on in that order: 1 accent · 2 + secondary accent · 3 + muted frame · 4 + muted surfaces.
    readonly property var extraColors: tokens.theme.preset !== "matugen"
        ? [palette.secondary, palette.tertiary]
        : wallpalette.colors
    readonly property int colorCount: Math.max(1, Math.min(4, tokens.accents.count))
    readonly property bool hasSecondary: colorCount >= 2
    // Which of the wallpaper's extra colors is the secondary accent (chosen in the settings preview).
    // Without a distinct second color in the picture, a neighbouring hue of the accent stands in.
    readonly property color secondaryColor: extraColors.length > 0
        ? extraColors[Math.min(tokens.accents.pick, extraColors.length - 1)]
        : Qt.hsla((palette.primary.hslHue + 0.1) % 1, palette.primary.hslSaturation, palette.primary.hslLightness, 1)
    readonly property color accent2: hasSecondary ? secondaryColor : textDim
    // Gray tinted with the main hue, as strong as `accents.tint`; plain gray while the muted tones are off.
    // On two-color (black plus one hue) wallpapers the gray is black with only a faint tint.
    readonly property bool duoWall: wallcolor.type === "duo"
    // In the light scheme the gray is a pale one, so dark text keeps reading on it.
    readonly property color mutedBase: isLight ? "#efeeec" : duoWall ? "#0b0b0e" : tokens.palette.panel
    readonly property real mutedTint: tokens.accents.tint * (duoWall ? 0.4 : 1)
    readonly property color mutedGray: colorCount >= 3 ? Qt.tint(mutedBase, Qt.alpha(palette.primary, mutedTint)) : mutedBase
    // Base of the thin veils that layer tiles over the panel: white, or white with a hint of the secondary hue.
    // In tonal mode the layers are veils of the scheme's own surface tone (a real surface-container ladder) instead of white.
    readonly property color veil: tonal ? (isLight ? palette.surface2 : Qt.tint(palette.surface2, Qt.rgba(1, 1, 1, 0.1)))
        : Qt.tint("#ffffff", Qt.alpha(colorCount >= 4 && hasSecondary ? secondaryColor : palette.primary, 0.35))
    readonly property color bg: palette.crust
    readonly property color surface: Qt.alpha(palette.base, tokens.glass.opacity)
    readonly property color surfaceRaised: Qt.alpha(palette.surface1, Math.min(1, tokens.glass.opacity + 0.05))
    readonly property color island: Qt.alpha(palette.crust, tokens.glass.islandOpacity)
    // Glass style for shell surfaces: "blur" is the classic blurred backdrop, "liquid" (later) adds specular/refraction.
    readonly property string glassStyle: tokens.glass.blurStyle
    // Strength of the in-shell wallpaper blur (0..1 of blurMax).
    readonly property real glassBlurAmount: tokens.glass.blurAmount
    // Lock screen: a simple blur of the wallpaper behind the card (0..1 of blurMax).
    readonly property real lockBlur: tokens.lock.blur
    // Frame glow: a soft bloom along the frame's inner edge (toward the desktop cutout).
    readonly property string glowColorMode: tokens.glow.color
    readonly property real glowStrength: solid ? 0 : tokens.glow.strength
    readonly property real glowBrightness: tokens.glow.brightness
    // Drop shadow of the frame and its branches onto the desktop.
    readonly property real shadowStrength: solid ? 0 : tokens.shadow.strength
    readonly property real shadowSize: tokens.shadow.size
    // Darkening toward the screen edges, under the windows.
    readonly property real vignetteStrength: solid ? 0 : tokens.vignette.strength
    // A vivid, hue-preserving glow: lightening toward white read as grey/white, so the color is rebuilt in HSL
    // (same hue, boosted saturation) instead. Neutral frames glow neutral.
    readonly property color glowColor: {
        const sat = panelBase.hslSaturation
        if (sat < 0.1) {
            const l = glowColorMode === "bright" ? 0.6 + glowBrightness * 0.25
                : (glowColorMode === "black" ? 0.12 : 0.45)
            return Qt.hsla(0, 0, l, 1)
        }
        const hue = panelBase.hslHue
        if (glowColorMode === "black") return Qt.hsla(hue, 0, 0.12, 1)
        const s = Math.max(sat, 0.55)
        const l = glowColorMode === "bright" ? 0.48 + glowBrightness * 0.4 : 0.46
        return Qt.hsla(hue, s, l, 1)
    }
    // The frame reads its color from the wallpaper classification (wallcolor.json): the second color of a
    // black-and-color picture (or black), and a neutral gray otherwise — as chosen by `surfaceColor`.
    readonly property string surfaceColor: tokens.glass.surfaceColor
    readonly property string wallcolorType: wallcolor.type
    // The accent panel/frame color: the wallpaper's second color on two-color pictures, a tinted base otherwise.
    readonly property color accentColor: wallcolor.type === "duo" && wallcolor.color !== ""
        ? wallcolor.color
        : Qt.tint(palette.base, Qt.alpha(palette.primary, 0.22))
    // Design mode, chosen by the user: "glass" is the translucent, blurred look; "solid" drops transparency, shadow and glow
    // and paints the frame in the flat background color of the wallpaper (the scheme's base on busy photos).
    // The light scheme (chosen, or picked for a light wallpaper in the "auto" color mode) flips the ink of lines and veils.
    readonly property bool isLight: palette.mode === "light"
    readonly property real ink: isLight ? 0 : 1
    readonly property string designMode: tokens.design.mode
    readonly property bool solid: designMode === "solid"
    // Solid-mode options (all live): where the frame color comes from, how the layers are toned, whether outlines are drawn.
    readonly property string solidFrame: tokens.design.frame
    readonly property bool tonal: solid && tokens.design.layers === "tonal"
    readonly property bool outlines: !solid || tokens.design.outlines === "subtle"
    readonly property color solidColor: solidFrame === "wallpaper" && wallcolor.flat && wallcolor.solid !== ""
        ? (isLight && wallcolor.bg !== "" ? wallcolor.bg : wallcolor.solid) : palette.base
    readonly property color schemeTarget: solid ? solidColor
        : (surfaceColor === "black" ? (isLight ? "#fbfbfa" : "#0b0b0e")
        : (surfaceColor === "gray" ? mutedGray : (surfaceColor === "shade" ? palette.crust : accentColor)))
    // Text on the frame is dark in the light scheme, so a dark frame color (a deep duo tone) is washed toward white
    // while keeping its hue; a color the user painted on the frame stays as it is.
    readonly property color panelTarget: ovFrame.a > 0 ? ovFrame
        : isLight && schemeTarget.hslLightness < 0.75 ? Qt.tint(schemeTarget, Qt.rgba(1, 1, 1, 0.82)) : schemeTarget
    // Light glass needs a denser fill: Hyprland's blur darkens what is behind, and a thin light veil over it turns
    // mid-gray, where neither dark nor light text reads.
    readonly property real panelAlphaTarget: solid ? 1 : isLight ? Math.max(0.86, tokens.glass.opacity) : tokens.glass.opacity
    // Both ease toward the target so a wallpaper change recolors the shell together with the transition.
    property color panelBase: panelTarget
    property real panelAlpha: panelAlphaTarget
    Behavior on panelBase { ColorAnimation { duration: 900; easing.type: Easing.OutCubic } }
    Behavior on panelAlpha { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
    // Fill of the panel itself: translucent, so the blurred wallpaper shows through.
    readonly property color panelFill: Qt.alpha(panelBase, panelAlpha)
    readonly property color panelFillHigh: solid ? panelFill : Qt.alpha(Qt.tint(panelBase, Qt.rgba(1, 1, 1, 0.07)), panelAlpha)
    // Dark ring on the desktop side of the cutout edge: depth for glass, nothing for flat solid surfaces.
    readonly property color frameRing: Qt.rgba(0, 0, 0, solid ? 0 : 0.28)
    // Layers on top of the panel are thin veils of white, not solid patches, so the glass stays one material.
    readonly property color panelRaised: Qt.alpha(veil, tonal ? 0.5 : 0.085)
    readonly property color panelPill: Qt.alpha(veil, tonal ? 0.6 : 0.115)
    readonly property color panelHigh: Qt.alpha(veil, tonal ? 0.75 : 0.18)
    // Tinted containers for selected items and colored tiles (solid mode): surface tone with a share of the hue.
    // A second hue only where the wallpaper really has one (a vivid secondary or tertiary color); otherwise the
    // containers differ by how much of the main hue they take, so the groups stay in one family but read apart.
    readonly property color hueTwo: hasSecondary && secondaryColor.hslSaturation > 0.35 ? secondaryColor : palette.primary
    readonly property color hueThree: palette.tertiary.hslSaturation > 0.35 ? palette.tertiary : palette.primary
    readonly property color accentContainer: ovSelected.a > 0 ? ovSelected : Qt.tint(palette.surface1, Qt.alpha(palette.primary, 0.42))
    readonly property color secondaryContainer: Qt.tint(palette.surface1, Qt.alpha(hueTwo, 0.28))
    readonly property color tertiaryContainer: Qt.tint(palette.surface1, Qt.alpha(hueThree, 0.14))
    // Light "milk" surfaces for solid mode: a pale cream from the wallpaper's primary hue, with dark text on it.
    // Only used by the light scheme, where a hero card is lighter than its surroundings.
    readonly property color milk: Qt.tint("#ffffff", Qt.alpha(palette.primary, 0.1))
    readonly property color milkTile: Qt.darker(milk, 1.05)
    readonly property color onMilk: palette.text
    readonly property color onMilkDim: Qt.alpha(onMilk, 0.62)
    readonly property color milkAccent: palette.primary
    readonly property color milkLine: Qt.alpha(onMilk, 0.14)
    readonly property color panelDeep: Qt.darker(panelBase, 1.35)
    readonly property color tile: Qt.rgba(ink, ink, ink, 0.05)
    // Faint divider / gridline between tiles and under rows (the only literal veil below panelRaised).
    readonly property color separator: Qt.rgba(ink, ink, ink, 0.055)
    // A bright hover fill for thumbnails and window cells, one step above panelHigh.
    readonly property color hoverStrong: Qt.rgba(ink, ink, ink, 0.22)
    readonly property color danger: palette.error
    // Text and icons are not pure white: a faint touch of the accent hue.
    readonly property color text: ovText.a > 0 ? ovText : Qt.tint(palette.text, Qt.alpha(palette.primary, 0.14))
    readonly property color textDim: Qt.alpha(text, 0.55)
    readonly property color textOff: Qt.alpha(text, 0.38)
    readonly property real disabledOpacity: 0.38
    readonly property color success: tokens.palette.success
    readonly property color warning: tokens.palette.warning
    readonly property color info: tokens.palette.info
    // Lock screen cards in solid mode keep the hue of the frame (the wallpaper's dark tone) and only lift its lightness.
    // A veil of the scheme's own surface tone would mix with a differently hued frame (a teal sky, brown rocks) into plain gray.
    readonly property real lockHue: (panelBase.hslSaturation > 0.08 ? panelBase : palette.primary).hslHue
    readonly property real lockSat: Math.min(0.35, Math.max(0.16, panelBase.hslSaturation))
    readonly property real lockLift: panelBase.hslLightness
    function lockStep(step) {
        return isLight ? Qt.darker(panelBase, 1 + step * 0.8)
            : Qt.hsla(lockHue, lockSat, Math.min(0.32, lockLift + step), 1)
    }
    // Card, a tile on it, and a pill or field on that.
    readonly property color lockBlock: lockStep(0.07)
    readonly property color lockTile: solid ? lockStep(0.12) : panelRaised
    readonly property color lockPill: solid ? lockStep(0.17) : panelPill
    // Block over a wallpaper (lock screen) and the groove of a slider.
    readonly property color blockGlass: solid ? lockBlock
        : Qt.alpha(Qt.tint(panelBase, Qt.alpha(palette.primary, 0.1)), 0.82)
    readonly property color panelTrack: Qt.rgba(ink, ink, ink, 0.10)
    readonly property color panelTrackHigh: Qt.rgba(ink, ink, ink, 0.14)
    // The thin glass edge: white at a few percent, so a flat fill reads as a pane with a lit rim.
    readonly property color border: Qt.rgba(ink, ink, ink, outlines ? tokens.border.inactive * (solid ? 0.5 : 1) : 0)
    readonly property color borderActive: Qt.rgba(ink, ink, ink, tokens.border.active)

    // One radius drives everything: Hyprland windows, shell panels and the elements inside them.
    readonly property int rounding: tokens.window.rounding
    // Solid mode uses plain circular arcs and rounder corners; glass keeps the superellipse of the windows.
    readonly property real roundingPower: solid ? 2 : tokens.window.roundingPower
    readonly property real radiusScale: solid ? 1.25 : 1
    // Physical corner radius of the display; big tiles and the corner buttons of the strip follow it.
    readonly property int screenRadius: tokens.panel.screenRadius
    // Nested corners stay concentric: an inner radius is the outer one minus the gap between the edges
    // (scaled for the superellipse, the same rule as the mini terminal cutout), never below a floor.
    function nest(outer, gap, floor) {
        const k = roundingPower === 2 ? 1 : (Math.SQRT2 - 1) / (Math.SQRT2 * (1 - Math.pow(2, -1 / roundingPower)))
        return Math.round(Math.max(floor, outer - k * gap))
    }
    // Outer edge of branches (and the frame cutout): the levels below are derived from it.
    readonly property int radiusBranch: Math.round(cfg.panel.railFlush ? Math.max(rounding * 1.5 * radiusScale, screenRadius) : rounding * 1.5 * radiusScale)
    // Blocks and cards sit `branchPad` inside a branch, tiles `padBlock` inside a block, chips `padTile` inside a tile.
    readonly property int branchPad: 12
    readonly property int radiusLg: nest(radiusBranch, branchPad, rounding * 1.5 * radiusScale)
    readonly property int radiusMd: nest(radiusLg, padBlock, rounding * radiusScale)
    readonly property int radiusSm: nest(radiusMd, padTile, rounding * 0.75 * radiusScale)
    // How far the corner buttons (32 px circles) sit from the screen edge so their hover circle stays inside the rounded corner.
    readonly property real railEndInset: {
        const r = screenRadius - 16 - 2
        const dx = screenRadius - railWidth / 2
        if (r <= Math.abs(dx)) return 4
        return Math.max(4, screenRadius - Math.sqrt(r * r - dx * dx) - 16)
    }
    readonly property int gapsIn: tokens.window.gapsIn
    readonly property int gapsOut: tokens.window.gapsOut
    // Spacing inside shell surfaces (DESIGN.md section 3).
    readonly property int padBlock: 16
    readonly property int padTile: 12
    readonly property int gapBlock: gapsOut
    readonly property int gapTile: gapsIn

    // Left panel width: a thin edge strip when flush, a normal card otherwise.
    readonly property int railWidth: tokens.panel.railFlush ? 44 : 48
    readonly property int frameWidth: solid ? Math.max(10, tokens.panel.frameWidth) : tokens.panel.frameWidth

    // Access for settings pages: read via Theme.cfg.<group>.<key>, write via Theme.set().
    readonly property var cfg: tokens

    property bool needsRecolor: false
    property bool needsApps: false

    function set(group, key, value) {
        if (tokens[group][key] === value) return
        tokens[group][key] = value
        if (group === "theme") needsRecolor = true
        else if (group !== "overrides" && group !== "oled" && group !== "drives") needsApps = true
        saveTimer.restart()
    }

    Timer {
        id: saveTimer
        interval: 250
        onTriggered: {
            ownWrite.restart()
            configFile.writeAdapter()
            if (needsRecolor) {
                needsRecolor = false
                needsApps = false
                Quickshell.execDetached(["hs-wallpaper", "restore"])
            } else if (needsApps) {
                needsApps = false
                Quickshell.execDetached(["hs-apps"])
                if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE"))
                    Quickshell.execDetached(["hyprctl", "reload"])
            }
        }
    }

    // Our own write triggers watchChanges; reloading in the middle of a slider drag would cause jitter.
    Timer { id: ownWrite; interval: 600 }

    readonly property int durFast: tokens.motion.fast
    readonly property int durNormal: tokens.motion.normal
    readonly property int durSlow: tokens.motion.slow
    // Springy motion (motion.spring, 0..1): things overshoot their target a little and settle back. 0 is a plain ease-out.
    // Every animation that uses `easing` also passes `overshoot`; fades and closing motions use `easingCalm`.
    readonly property real spring: tokens.motion.spring
    readonly property bool expressive: spring > 0.01
    readonly property real overshoot: spring * 2.2
    readonly property int easing: expressive ? Easing.OutBack : Easing.OutCubic
    readonly property int easingCalm: Easing.OutCubic
    readonly property int easingOpen: easing
    readonly property int durOpen: expressive ? 320 : durSlow

    // Solid mode reads in Rubik, which looks heavier than the glass font, so the three weights step down one notch.
    readonly property string fontUi: solid ? "Rubik" : tokens.fonts.ui
    readonly property int wBold: solid ? Font.Medium : Font.Bold
    readonly property int wStrong: solid ? Font.DemiBold : Font.ExtraBold
    readonly property int wHeavy: solid ? Font.Bold : Font.Black
    readonly property string fontMono: tokens.fonts.mono

    FileView {
        path: root.stateDir + "/colors.json"
        watchChanges: true
        onFileChanged: reload()
        adapter: JsonAdapter {
            id: palette
            property string mode: "dark"
            property string source: ""
            property color crust: "#0c0e13"
            property color mantle: "#111318"
            property color base: "#1a1b20"
            property color surface0: "#1e1f25"
            property color surface1: "#282a2f"
            property color surface2: "#33353a"
            property color text: "#e2e2e9"
            property color subtext: "#c4c6d0"
            property color outline: "#8e9099"
            property color inverseSurface: "#e2e2e9"
            property color primary: "#8ab4a0"
            property color primaryText: "#07120d"
            property color secondary: "#bfc6dc"
            property color tertiary: "#debcdf"
            property color error: "#ff6b6b"
            property color errorText: "#2b0909"
        }
    }

    FileView {
        path: root.stateDir + "/wallpalette.json"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        adapter: JsonAdapter {
            id: wallpalette
            property list<string> colors: []
        }
    }

    FileView {
        path: root.stateDir + "/panel.json"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        adapter: JsonAdapter {
            id: adaptivePanel
            property string color: ""
            property real floor: 0
        }
    }

    FileView {
        path: root.stateDir + "/wallcolor.json"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        adapter: JsonAdapter {
            id: wallcolor
            property string type: "photo"
            property string color: "#2a2a2c"
            property bool flat: false
            property string bg: ""
            property string solid: ""
        }
    }

    FileView {
        id: configFile
        path: root.configDir + "/theme.json"
        watchChanges: true
        onFileChanged: if (!ownWrite.running) reload()
        adapter: JsonAdapter {
            id: tokens
            property JsonObject motion: JsonObject {
                property int fast: 150
                property int normal: 200
                property int slow: 220
                // Window open and close animation of the compositor (see conf/animations.lua).
                property string windowStyle: "popin"
                property int windowOpen: 320
                property int windowClose: 220
                property int windowScale: 88
                // How springy the shell and the windows move (0 = no overshoot).
                property real spring: 0.7
            }
            property JsonObject window: JsonObject {
                property int rounding: 12
                property bool roundingFollowScreen: true
                property real cornerFit: 0.5
                property int roundingPower: 4
                property int gapsIn: 8
                property int gapsOut: 14
            }
            // The outline of the focused window (see conf/look.lua).
            property JsonObject focus: JsonObject {
                property bool enabled: true
                property int size: 2
                property int colors: 1
                property real lightness: 0.62
                property real saturation: 0.85
                property real shade: 0.12
                property int angle: 45
                property real opacity: 1
            }
            property JsonObject border: JsonObject {
                property real active: 0.35
                property real inactive: 0.08
            }
            property JsonObject palette: JsonObject {
                property string bg: "#000000"
                property string surface: "#171719"
                property string surfaceRaised: "#242426"
                property string panel: "#2a2a2c"
                property string text: "#ececec"
                property string danger: "#ff6b6b"
                property string success: "#8fbf9f"
                property string warning: "#e5c07b"
                property string info: "#7aa2f7"
            }
            property JsonObject overrides: JsonObject {
                property string accent: ""
                property string frame: ""
                property string card: ""
                property string tile: ""
                property string pill: ""
                property string text: ""
                property string selected: ""
            }
            property JsonObject design: JsonObject {
                property string mode: "glass"
                property string layers: "tonal"
                property string frame: "wallpaper"
                property string outlines: "none"
            }
            property JsonObject accents: JsonObject {
                property int count: 4
                property real tint: 0.12
                property int pick: 0
            }
            property JsonObject dock: JsonObject {
                property list<string> pinned: ["kitty", "org.mozilla.firefox", "org.gnome.Nautilus", "steam"]
            }
            property JsonObject panel: JsonObject {
                property bool joined: false
                property bool railFlush: true
                property int frameWidth: 8
                property int screenRadius: 36
                property int cornerInset: 12
                property real offsetX: 0
                property real offsetY: 0
                property bool adaptive: true
                property real opacity: 1
            }
            property JsonObject dashboard: JsonObject {
                property bool hotZone: true
                property bool controlHotZone: true
                property bool utilityHotZone: true
                property bool notifHotZone: true
                property string weatherCity: ""
                property string weatherUnits: "metric"
                property string weatherSource: "auto"
            }
            property JsonObject lock: JsonObject {
                property real blur: 0.3
                property int dotSize: 24
                property bool notifHotZone: true
                property string dotShape: "square"
            }
            // OLED care (see OledCare): drift in px, idle dimming and fading of the left strip.
            property JsonObject oled: JsonObject {
                property int shift: 1
                property int dimAfter: 10
                property real dimLevel: 0.5
                property int hideAfter: 0
            }
            property JsonObject vignette: JsonObject {
                property real strength: 0.14
            }
            property JsonObject shadow: JsonObject {
                property real strength: 0.35
                property real size: 0.4
            }
            property JsonObject glow: JsonObject {
                property string color: "bright"
                property real strength: 0.6
                property real brightness: 0.5
            }
            property JsonObject screenshot: JsonObject {
                property string dir: "~/Pictures/Screenshots"
                property string filename: "Screenshot_%Y-%m-%d_%H-%M-%S"
            }
            property JsonObject notes: JsonObject {
                property string dir: "~/Documents/Obsidian Vault/Quick Notes"
            }
            property JsonObject drives: JsonObject {
                property string isoDir: "~/ISO"
                property bool verify: true
                property string onConnect: "nothing"
                property bool autoImport: false
                property string importDir: "~/Pictures/Imports"
            }
            property JsonObject glass: JsonObject {
                property real opacity: 0.95
                property real islandOpacity: 0.9
                property string blurStyle: "blur"
                property real blurAmount: 1
                property string surfaceColor: "auto"
            }
            property JsonObject blur: JsonObject {
                property int size: 16
                property int passes: 5
                property real noise: 0.05
                property real contrast: 0.9
                property real brightness: 0.85
                property real vibrancy: 0.17
                property real vibrancyDarkness: 0.05
            }
            property JsonObject terminal: JsonObject {
                property bool blur: false
                property real opacity: 0.25
                property real solidOpacity: 0.8
                // Saturation of the terminal body: a gray with this much of the wallpaper's hue (0 is plain gray).
                property real tint: 0.12
            }
            property JsonObject fonts: JsonObject {
                property string ui: "Geist"
                property string mono: "JetBrains Mono"
            }
            property JsonObject theme: JsonObject {
                property string mode: "dark"
                property string schemeType: "auto"
                property string preset: "matugen"
            }
        }
    }
}
