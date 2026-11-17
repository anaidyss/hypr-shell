local theme = require("lib.theme")
local t = theme.t
local ms = theme.ms

hl.config({ animations = { enabled = true } })

hl.curve("out", { type = "bezier", points = { { 0.33, 1 }, { 0.68, 1 } } })
-- Springy motion (motion.spring, 0..1, shared with the shell): an ease-out-back curve whose overshoot grows with the
-- setting; at 0 it is the plain "out" curve. Used for things that arrive or move, never for closing or fading.
local spring = math.max(0, math.min(1, tonumber(t.motion.spring) or 0))
hl.curve("spring", { type = "bezier", points = { { 0.34, 1 + 0.8 * spring }, { 0.64, 1 } } })
-- Window opening: a quicker pop with an early overshoot (about 40% in): at spring 0.7 the curve peaks near 11% past
-- the target, under 2% of the window size from an 85% start. 18% (4% of the window) was too much.
hl.curve("pop", { type = "bezier", points = { { 0.2, 1 + 0.85 * spring }, { 0.4, 1 } } })

local normal, fast = ms(t.motion.normal), ms(t.motion.fast)

hl.animation({ leaf = "global", enabled = true, speed = normal, bezier = "out" })
-- Window open and close: the style, the two durations and the start size of "popin" come from the settings
-- (Motion & fonts). Closing is the same motion, a little shallower and shorter.
local style = t.motion.windowStyle
local scale = t.motion.windowScale
local function window_style(closing)
    if style == "popin" then return "popin " .. (closing and math.min(100, scale + 6) or scale) .. "%" end
    if style == "fade" then return "popin 100%" end
    if style == "gnomed" then return "gnomed" end
    return "slide"
end
local open_speed, close_speed = ms(t.motion.windowOpen), ms(t.motion.windowClose)
hl.animation({ leaf = "windows", enabled = true, speed = open_speed, bezier = "spring" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = open_speed, bezier = "pop", style = window_style(false) })
hl.animation({ leaf = "windowsOut", enabled = true, speed = close_speed, bezier = "out", style = window_style(true) })
hl.animation({ leaf = "fade", enabled = true, speed = normal, bezier = "out" })
-- The window is opaque well before the pop settles, so it never looks like a slow fade.
hl.animation({ leaf = "fadeIn", enabled = true, speed = open_speed * 0.6, bezier = "out" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = close_speed, bezier = "out" })
hl.animation({ leaf = "border", enabled = true, speed = normal, bezier = "out" })
hl.animation({ leaf = "layers", enabled = false })
hl.animation({ leaf = "workspaces", enabled = true, speed = ms(t.motion.slow) * 1.4, bezier = "spring", style = "slide" })
