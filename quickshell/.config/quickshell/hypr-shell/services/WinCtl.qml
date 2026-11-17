pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Window and layout controls of the compositor for the strip's Layout menu: everything is a Lua dispatch through hyprctl.
Singleton {
    id: root

    property string layout: ""
    property int gapsIn: 0
    property int gapsOut: 0

    function lua(code) { Quickshell.execDetached(["hyprctl", "dispatch", code]) }

    function setLayout(name) {
        layout = name
        lua('function() hl.config({ general = { layout = "' + name + '" } }) end')
    }

    // Width of the focused column of the scrolling layout, as a fraction of the screen.
    function columnWidth(fraction) { lua('hl.dsp.layout("colresize ' + fraction + '")') }

    // Same shape as conf/look.lua: the scrolling layout adds gaps_in on the left and right, so those sides shrink by it.
    function setGaps(inner, outer) {
        gapsIn = inner
        gapsOut = outer
        const side = Math.max(0, outer - inner)
        lua('function() hl.config({ general = { gaps_in = ' + inner + ', gaps_out = { top = ' + outer + ', bottom = ' + outer
            + ', left = ' + side + ', right = ' + side + ' } } }) end')
    }

    function windowAction(name) {
        const calls = {
            float: 'hl.dsp.window.float({ action = "toggle" })',
            fullscreen: 'hl.dsp.window.fullscreen()',
            pin: 'hl.dsp.window.pin({ action = "toggle" })',
            center: 'hl.dsp.window.center()',
            close: 'hl.dsp.window.close()'
        }
        if (calls[name]) lua(calls[name])
    }

    function refresh() { query.running = true }

    Process {
        id: query
        command: ["sh", "-c", "hyprctl -j getoption general:layout; hyprctl -j getoption general:gaps_in; hyprctl -j getoption general:gaps_out"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const o = JSON.parse(line)
                    if (o.option === "general:layout") root.layout = o.str
                    else if (o.option === "general:gaps_in") root.gapsIn = parseInt(o.css)
                    else if (o.option === "general:gaps_out") root.gapsOut = parseInt(o.css)
                } catch (e) {}
            }
        }
    }
}
