local theme = require("lib.theme")

hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "opaque-media",
    match = { class = "^(firefox|librewolf|chromium|brave-browser|google-chrome|mpv|vlc|steam_app_.*)$" },
    opaque = true,
})

-- Glass: the terminal shows the wallpaper sharply unless the setting turns blur on. Solid always keeps the small blur.
if not theme.solid and theme.t.terminal and theme.t.terminal.blur == false then
    hl.window_rule({
        name = "terminal-no-blur",
        match = { class = "^kitty$" },
        no_blur = true,
    })
end

hl.layer_rule({
    name = "shell-blur",
    match = { namespace = "^hs-.*" },
    blur = true,
    ignore_alpha = 0.2,
    no_anim = true,
})

hl.layer_rule({
    name = "hs-vignette",
    match = { namespace = "^hs-vignette$" },
    blur = false,
    no_anim = true,
})

hl.layer_rule({
    name = "hs-screenshot",
    match = { namespace = "^hs-screenshot$" },
    blur = false,
    no_anim = true,
})

hl.layer_rule({
    name = "hs-crop",
    match = { namespace = "^hs-crop$" },
    blur = false,
    no_anim = true,
})

hl.layer_rule({
    name = "hs-stealthcast",
    match = { namespace = "^hs-stealthcast$" },
    blur = false,
    no_anim = true,
})

hl.layer_rule({
    name = "hs-sticky",
    match = { namespace = "^hs-sticky$" },
    blur = false,
    no_anim = true,
})

hl.window_rule({
    name = "hs-settings",
    match = { title = "^Settings$" },
    float = true,
    center = true,
    size = "980 660",
    opacity = "1.0 override 1.0 override",
})

hl.window_rule({
    name = "hs-miniterm",
    match = { class = "^hs-miniterm$" },
    float = true,
    size = "480 240",
    workspace = "special:hsterm silent",
    no_anim = true,
    opacity = "1.0 override 1.0 override",
    -- The frame of the branch cuts the corners (the window is slightly larger than the cutout), so the window itself stays square.
    rounding = 0,
    no_shadow = true,
    -- No outline either: the window sits behind the frame of the branch and only shows through the cutout.
    border_size = 0,
})

-- Quick terminal (Super+T): floating card in the bottom-left corner of the work area, kept off the strip and the
-- frame by the same gap the tiled windows use (strip 44 px wide; the frame is at least 10 px in solid).
local panel = theme.t.panel or {}
local frame_w = panel.frameWidth or 8
if theme.solid then frame_w = math.max(frame_w, 10) end
local gap = theme.t.window.gapsOut
hl.window_rule({
    name = "hs-quickterm",
    match = { class = "^hs-quickterm$" },
    float = true,
    move = string.format("%d (monitor_h-window_h-%d)", 44 + gap, frame_w + gap),
})

-- A window that is alone on its workspace gets no focus outline; the outline appears from two windows on (the
-- selector counts the visible windows, tiled or floating).
hl.workspace_rule({ workspace = "w[v1]", no_border = true })
