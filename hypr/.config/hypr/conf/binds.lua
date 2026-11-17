local mod = "SUPER"

-- launch
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
-- Copilot key: on this laptop it sends a bare Right Ctrl; fire on release so RCtrl+<key> combos keep working.
hl.bind("CTRL + Control_R", hl.dsp.exec_cmd("notify-send -a hypr-shell \"Test notification\" \"fuck microsoft copilot\""), { release = true })
hl.bind(mod .. " + T", hl.dsp.exec_cmd("hs-quickterm"))
hl.bind(mod .. " + D", hl.dsp.exec_cmd("qs -c hypr-shell ipc call omnibox toggle || fuzzel"))
hl.bind(mod .. " + slash", hl.dsp.exec_cmd("qs -c hypr-shell ipc call omnibox toggle"))
hl.bind(mod .. " + ALT + N", hl.dsp.exec_cmd("qs -c hypr-shell ipc call omnibox notes"))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("qs -c hypr-shell ipc call omnibox clipboard || (cliphist list | fuzzel --dmenu | cliphist decode | wl-copy)"))
-- zh-* come from the personal stow package (--no-personal skips it); the binds do nothing where they are missing.
local function optional(cmd) return hl.dsp.exec_cmd("command -v " .. cmd:match("^%S+") .. " >/dev/null && " .. cmd) end
hl.bind(mod .. " + Z", optional("zh-fuzzel"))
hl.bind(mod .. " + SHIFT + Z", optional("zh-fuzzel --ask"))
hl.bind(mod .. " + O", optional("zh-open"))
hl.bind(mod .. " + N", optional("zh-pick-note"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exit())
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("qs -c hypr-shell ipc call screenshot region"))
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("qs -c hypr-shell ipc call screenshot edit"))
hl.bind("Print", hl.dsp.exec_cmd("qs -c hypr-shell ipc call screenshot region"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("qs -c hypr-shell ipc call screenshot screen"))

-- windows
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
-- Super+Space collapses a fullscreen window; otherwise it toggles floating.
hl.bind(mod .. " + Space", function()
    local win = hl.get_active_window()
    if win and win.fullscreen and win.fullscreen ~= 0 then
        hl.dispatch(hl.dsp.window.fullscreen())
    else
        hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    end
end)
hl.bind(mod .. " + R", hl.dsp.layout("colresize +conf"))

-- window height in a column
hl.bind(mod .. " + ALT + J", hl.dsp.window.resize({ x = 0, y = 60, relative = true }), { repeating = true })
hl.bind(mod .. " + ALT + K", hl.dsp.window.resize({ x = 0, y = -60, relative = true }), { repeating = true })

-- focus
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))

-- move
hl.bind(mod .. " + SHIFT + H", hl.dsp.layout("swapcol l"))
hl.bind(mod .. " + SHIFT + L", hl.dsp.layout("swapcol r"))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + CTRL + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + CTRL + K", hl.dsp.window.move({ direction = "up" }))

-- column stacking
hl.bind(mod .. " + W", hl.dsp.layout("consume"))
hl.bind(mod .. " + E", hl.dsp.layout("promote"))

-- workspaces
for i = 1, 9 do
    hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- wallpapers
hl.bind(mod .. " + CTRL + W", hl.dsp.exec_cmd("hs-wallpaper next"))
hl.bind(mod .. " + CTRL + SHIFT + W", hl.dsp.exec_cmd("hs-wallpaper random"))

-- shell
hl.bind(mod .. " + grave", hl.dsp.exec_cmd("qs -c hypr-shell ipc call panel toggle dashboard"))
hl.bind(mod .. " + M", hl.dsp.exec_cmd("qs -c hypr-shell ipc call panel multi"))
hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("qs -c hypr-shell ipc call notifications toggleDnd"))
hl.bind(mod .. " + CTRL + L", hl.dsp.exec_cmd("hs-lock"))
hl.bind(mod .. " + SHIFT + V", hl.dsp.exec_cmd("hs-lock"))
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("hs-lock"))
hl.bind(mod .. " + comma", hl.dsp.exec_cmd("qs -c hypr-shell ipc call settings toggle"))

-- sound: the OSD reacts to volume changes on its own
local lr = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), lr)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), lr)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), lr)
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), lr)

local bright = "brightnessctl -e4 -n2 set 5%%%s && qs -c hypr-shell ipc call osd brightness"
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(string.format(bright, "+")), lr)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(string.format(bright, "-")), lr)

local locked = { locked = true }
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), locked)
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), locked)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), locked)
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), locked)
