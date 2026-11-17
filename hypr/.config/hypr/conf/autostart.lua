hl.on("hyprland.start", function()
    -- tty1 logs in automatically (getty autologin), so the shell starts locked; the nested session stays unlocked.
    -- The shell goes first so the lock lands before the wallpaper.
    if os.getenv("HS_NESTED") then
        hl.exec_cmd("qs -c hypr-shell")
    else
        hl.exec_cmd("HS_LOCK_ON_START=1 qs -c hypr-shell")
    end
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("hs-wallpaper restore")

    -- Nested mode (HS_NESTED=1) leaves the main session's system services alone.
    if os.getenv("HS_NESTED") then return end
    -- Guards the startup lock: hyprlock takes over if the shell dies, or never comes up.
    hl.exec_cmd("hs-lock --wait")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("fcitx5 -d")
    hl.exec_cmd("hs-edge-slider")
    hl.exec_cmd("hypridle -c $HOME/.config/hypr-shell/hypridle.conf")
end)
