local json = require("lib.json")

local home = os.getenv("HOME")

local defaults = {
    motion = { fast = 150, normal = 200, slow = 220, windowStyle = "popin", windowOpen = 320, windowClose = 220, windowScale = 88, spring = 0.7 },
    window = { rounding = 12, roundingPower = 4, gapsIn = 8, gapsOut = 14 },
    focus = { enabled = true, size = 2, colors = 1, lightness = 0.62, saturation = 0.85, shade = 0.12, angle = 45, opacity = 1 },
    border = { active = 0.35, inactive = 0.08 },
    blur = { size = 16, passes = 5, noise = 0.05, contrast = 0.9, brightness = 0.85, vibrancy = 0.17, vibrancyDarkness = 0.05 },
    terminal = { blur = false, opacity = 0.25, solidOpacity = 0.8 },
}

local function read(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local s = f:read("a")
    f:close()
    return s
end

local function merge(base, over)
    for k, v in pairs(over) do
        if type(v) == "table" and type(base[k]) == "table" then
            merge(base[k], v)
        else
            base[k] = v
        end
    end
    return base
end

local tokens = defaults
local raw = read(home .. "/.config/hypr-shell/theme.json")
if raw then
    local ok, parsed = pcall(json.decode, raw)
    if ok and type(parsed) == "table" then merge(tokens, parsed) end
end

-- Solid design (mirrors Theme.solid in the shell): tighter gaps, circular corners, rounder radii.
local design = tokens.design or {}
local solid = design.mode == "solid"
tokens.window.radiusScale = 1
if solid then
    tokens.window.roundingPower = 2
    tokens.window.gapsIn = 4
    tokens.window.gapsOut = 6
    tokens.window.radiusScale = 1.25
end

local colors = { accent = "8ab4a0", accentText = "07120d" }
local ok, loaded = pcall(dofile, home .. "/.local/state/hypr-shell/colors.lua")
if ok and type(loaded) == "table" then merge(colors, loaded) end
-- The shared frame color (panel + focused window border), written by hs-apps.
local fok, floaded = pcall(dofile, home .. "/.local/state/hypr-shell/frame.lua")
if fok and type(floaded) == "table" then merge(colors, floaded) end

local function white(alpha)
    return string.format("rgba(ffffff%02x)", math.floor(alpha * 255 + 0.5))
end

return {
    t = tokens,
    solid = solid,
    c = colors,
    white = white,
    ms = function(v) return v / 100 end,
}
