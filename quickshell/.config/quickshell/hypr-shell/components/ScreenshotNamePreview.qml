import QtQuick
import Quickshell
import qs.theme

// The file the next Save would write, built from the folder and the name template.
Item {
    id: root

    property date now: new Date()
    readonly property string home: Quickshell.env("HOME")

    function pad(n) { return (n < 10 ? "0" : "") + n }

    function expand(template) {
        const d = root.now
        const map = { Y: String(d.getFullYear()), m: pad(d.getMonth() + 1), d: pad(d.getDate()), H: pad(d.getHours()), M: pad(d.getMinutes()), S: pad(d.getSeconds()), "%": "%" }
        return template.replace(/%([YmdHMS%])/g, (m, c) => map[c])
    }

    function shortPath(p) { return p.startsWith(home + "/") ? "~" + p.slice(home.length) : p }

    readonly property string folder: {
        let f = Theme.cfg.screenshot.dir.trim()
        if (f.startsWith("~")) f = home + f.slice(1)
        return shortPath(f.replace(/\/+$/, ""))
    }
    readonly property string fileName: expand(Theme.cfg.screenshot.filename) + ".png"

    width: parent ? parent.width : implicitWidth
    implicitHeight: 12 + 44 + 4 + 14 + 8

    Timer { interval: 1000; repeat: true; running: root.visible; onTriggered: root.now = new Date() }

    Surface {
        y: 12
        width: parent.width
        height: 44
        radius: Theme.radiusSm
        color: Theme.panelRaised

        Rectangle {
            x: 8; anchors.verticalCenter: parent.verticalCenter
            width: 28; height: 28; radius: 8
            color: Theme.panelPill
            PanelIcon { anchors.centerIn: parent; name: "image"; size: 16; color: Theme.accent }
        }
        Text {
            anchors { left: parent.left; leftMargin: 48; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            elide: Text.ElideMiddle
            text: root.folder + "/" + root.fileName
            color: Theme.text
            font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold }
        }
    }

    Text {
        y: 12 + 44 + 4
        text: "Example for the next screenshot"
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
    }
}
