hl.config({
    input = {
        kb_layout = "us,ru",
        kb_options = "grp:alt_shift_toggle",
        -- Hovering never moves focus: the keyboard (binds) decides, and a click still focuses the window it lands on.
        -- 3 would make clicks leave the keyboard focus alone as well.
        follow_mouse = 2,
        float_switch_override_focus = 0,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
        },
    },
})

hl.gesture({
    fingers = 4,
    direction = "horizontal",
    action = "workspace",
})

-- Three-finger swipes drive the shell branches: down the dashboard, up the utility branch, left the control center;
-- the opposite swipe closes the open one (PanelState.swipe).
for _, dir in ipairs({ "up", "down", "left", "right" }) do
    hl.gesture({
        fingers = 3,
        direction = dir,
        action = function() hl.exec_cmd("qs -c hypr-shell ipc call panel swipe " .. dir) end,
    })
end
