-- Icon theme for the shell (Quickshell reads QS_ICON_THEME); Veil is Papirus-Dark with neutral grey folders.
hl.env("QS_ICON_THEME", "Veil")
-- Cursor: Bibata, white on the dark scheme and black on the light one. hs-apps picks it with the scheme and writes
-- "<theme> <size>" here; read at start so the first windows get it too (hs-apps also switches it live).
local cursor_theme, cursor_size = "Bibata-Modern-Ice", "24"
local cf = io.open(os.getenv("HOME") .. "/.local/state/hypr-shell/apps/cursor")
if cf then
    local line = cf:read("*l") or ""
    cf:close()
    local t, s = line:match("^(%S+)%s+(%d+)")
    if t then cursor_theme, cursor_size = t, s end
end
hl.env("XCURSOR_THEME", cursor_theme)
hl.env("XCURSOR_SIZE", cursor_size)
hl.env("HYPRCURSOR_THEME", cursor_theme)
hl.env("HYPRCURSOR_SIZE", cursor_size)
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("KITTY_CONFIG_DIRECTORY", os.getenv("HOME") .. "/.config/hypr-shell/kitty")

-- Binds and autostart call our scripts (hs-lock, hs-wallpaper, ...) from ~/.local/bin, which the session PATH lacks.
local bin = os.getenv("HOME") .. "/.local/bin"
local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
if not path:find(bin, 1, true) then hl.env("PATH", bin .. ":" .. path) end
