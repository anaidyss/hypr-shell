local theme = require("lib.theme")
local t = theme.t
-- The focused window's outline comes from the `focus` tokens (Shapes page of the settings): on or off, thickness, how
-- many wallpaper colors it uses (1 primary, 2 adds tertiary, 3 adds secondary), their lightness and saturation, how far
-- each color shades lighter and darker, the angle of the gradient and its opacity.
local fo = t.focus or {}
local function hex_rgb(h)
    return tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255
end
local function hue_of(r, g, b)
    local mx, mn = math.max(r, g, b), math.min(r, g, b)
    if mx == mn then return 0 end
    local d = mx - mn
    local h
    if mx == r then h = (g - b) / d + (g < b and 6 or 0)
    elseif mx == g then h = (b - r) / d + 2
    else h = (r - g) / d + 4 end
    return h / 6
end
local function hue_rgb(p, q, t)
    if t < 0 then t = t + 1 elseif t > 1 then t = t - 1 end
    if t < 1 / 6 then return p + (q - p) * 6 * t end
    if t < 1 / 2 then return q end
    if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
    return p
end
-- The hue of `hex` at a given saturation and lightness.
local function tone(hex, s, l)
    local h = hue_of(hex_rgb(hex))
    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q
    local function c(t) return math.floor(hue_rgb(p, q, t) * 255 + 0.5) end
    return string.format("%02x%02x%02x", c(h + 1 / 3), c(h), c(h - 1 / 3))
end
local primary = theme.c.primary or theme.c.accent or "8ab4a0"
local order = { primary, theme.c.tertiary or primary, theme.c.secondary or primary }
local n = math.max(1, math.min(3, math.floor(fo.colors or 1)))
local light, sat, swing = fo.lightness or 0.62, fo.saturation or 0.85, fo.shade or 0.12
local alpha = string.format("%02x", math.floor((fo.opacity or 1) * 255 + 0.5))
local edge_colors = {}
for i = 1, n do
    edge_colors[#edge_colors + 1] = string.format("rgba(%s%s)", tone(order[i], sat, math.min(0.92, light + swing)), alpha)
    edge_colors[#edge_colors + 1] = string.format("rgba(%s%s)", tone(order[i], sat, math.max(0.12, light - swing)), alpha)
end
edge_colors[#edge_colors + 1] = edge_colors[1]
local focus_edge = { colors = edge_colors, angle = fo.angle or 45 }
local focus_size = fo.enabled == false and 0 or (fo.size or 2)
-- Unfocused windows: solid surfaces separate by tone, not by lines (design.outlines "none"), so no outline there;
-- otherwise a faint line in the scheme's ink (white on dark, black on light, where white would vanish).
local design = t.design or {}
local tr, tg, tb = hex_rgb(theme.c.text or "e2e2e9")
local ink = (0.2126 * tr + 0.7152 * tg + 0.0722 * tb < 0.5) and "000000" or "ffffff"
local inactive_border = (theme.solid and design.outlines ~= "subtle") and "rgba(00000000)"
    or string.format("rgba(%s14)", ink)

-- Constant gap between the cutout and the window corner. Offsetting a superellipse corner by d does not give a
-- superellipse of radius R - d: the diagonal gap grows by 2^(1/p). Matching the gap on the diagonal needs
-- r = R - k * d with k below (k = 1 for a circle). At full fit the gap stays within ~0.5 px of d.
local rounding = t.window.rounding
local panel = t.panel or {}
if panel.railFlush and t.window.roundingFollowScreen ~= false and panel.screenRadius then
    local cutout = math.max(math.floor(t.window.rounding * 1.5 * t.window.radiusScale + 0.5), panel.screenRadius)
    local power = t.window.roundingPower
    local k = (math.sqrt(2) - 1) / (math.sqrt(2) * (1 - 2 ^ (-1 / power)))
    -- cornerFit 1 = even gap (squarer windows), 0 = plain offset (rounder windows, thicker gap in the corner).
    k = 1 + (k - 1) * (t.window.cornerFit or 0.5)
    rounding = math.max(0, math.floor(cutout - k * t.window.gapsOut + 0.5))
end

hl.config({
    general = {
        gaps_in = t.window.gapsIn,
        -- The scrolling layout adds gaps_in on the left and right of the work area, so shrink those sides to keep all four gaps equal.
        gaps_out = {
            top = t.window.gapsOut,
            bottom = t.window.gapsOut,
            left = math.max(0, t.window.gapsOut - t.window.gapsIn),
            right = math.max(0, t.window.gapsOut - t.window.gapsIn),
        },
        border_size = focus_size,
        col = {
            active_border = focus_edge,
            inactive_border = inactive_border,
        },
        allow_tearing = false,
        layout = "scrolling",
    },

    decoration = {
        rounding = rounding,
        rounding_power = t.window.roundingPower,
        -- Solid is flat like the shell surfaces (no frame shadow, no glow there either); glass keeps the depth.
        shadow = {
            enabled = not theme.solid,
            range = 24,
            render_power = 3,
            color = 0x66000000,
        },

        blur = {
            enabled = true,
            size = t.blur.size,
            passes = t.blur.passes,
            noise = t.blur.noise,
            contrast = t.blur.contrast,
            brightness = t.blur.brightness,
            vibrancy = t.blur.vibrancy,
            vibrancy_darkness = t.blur.vibrancyDarkness,
            ignore_opacity = true,
            new_optimizations = true,
            popups = true,
        },
    },

    scrolling = {
        column_width = 0.5,
        explicit_column_widths = "0.33333, 0.5, 0.66667, 1.0",
        fullscreen_on_one_column = true,
    },

    misc = {
        allow_session_lock_restore = true,
        key_press_enables_dpms = true,
        mouse_move_enables_dpms = true,
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        background_color = 0x000000,
    },

    cursor = {
        no_warps = true,
    },
})
