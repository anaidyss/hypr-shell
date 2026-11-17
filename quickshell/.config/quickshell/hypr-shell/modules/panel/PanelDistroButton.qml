import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.theme
import qs.services
import qs.components

// Distribution logo in the top corner of the strip; opens search and the calculator.
Item {
    id: root

    property real size: 32
    property real iconSize: 18

    width: size
    height: size

    FileView { id: osRelease; path: "/etc/os-release"; blockLoading: true }

    readonly property string distroId: {
        const m = osRelease.text().match(/^ID=(.*)$/m)
        return m ? m[1].replace(/"/g, "") : ""
    }
    readonly property string iconName: "distributor-logo-" + (distroId === "arch" ? "archlinux" : distroId)
    readonly property string iconSource: Quickshell.iconPath(iconName, true)

    // Plain one-colour marks filled with the text colour; each carries its own viewBox.
    readonly property var glyphs: ({
        arch: { vb: "0 0 24 24", d: "M11.39.605C10.376 3.092 9.764 4.72 8.635 7.132c.693.734 1.543 1.589 2.923 2.554-1.484-.61-2.496-1.224-3.252-1.86C6.86 10.842 4.596 15.138 0 23.395c3.612-2.085 6.412-3.37 9.021-3.862a6.61 6.61 0 01-.171-1.547l.003-.115c.058-2.315 1.261-4.095 2.687-3.973 1.426.12 2.534 2.096 2.478 4.409a6.52 6.52 0 01-.146 1.243c2.58.505 5.375 1.785 8.953 3.85-.705-1.298-1.333-2.468-1.935-3.58-.947-.734-1.934-1.689-3.9-2.723 1.368.355 2.349.765 3.113 1.22-6.054-11.274-6.544-12.768-8.614-17.288z" },
        fedora: { vb: "10 12 26 26", d: "M28.5 12A6.5 6.5 0 0 0 22 18.5V31h-.04A3.5 3.5 0 0 1 18.5 34 3.5 3.5 0 0 1 15 30.5 3.5 3.5 0 0 1 18.5 27H20V23h-1.5A7.5 7.5 0 0 0 11 30.5 7.5 7.5 0 0 0 18.5 38 7.5 7.5 0 0 0 26 31v-.46V27h2a2 2 0 0 0 2-2 2 2 0 0 0-2-2h-2v-4.5A2.5 2.5 0 0 1 28.5 16 2.5 2.5 0 0 1 31 18.5V19a2 2 0 0 0 2 2 2 2 0 0 0 2-2v-1h-.02A6.5 6.5 0 0 0 28.5 12z" }
    })
    readonly property var glyph: glyphs[distroId] || null
    readonly property color tint: hover.hovered ? Theme.text : Theme.textDim

    function rgb(c) {
        return "rgb(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + ")"
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: hover.hovered ? Theme.panelHigh : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    Image {
        anchors.centerIn: parent
        width: root.iconSize + 2
        height: root.iconSize + 2
        visible: root.glyph !== null
        smooth: true
        sourceSize: Qt.size(width * 2, height * 2)
        source: root.glyph === null ? "" : "data:image/svg+xml;utf8," + encodeURIComponent("<svg xmlns='http://www.w3.org/2000/svg' viewBox='"
            + root.glyph.vb + "'><path d='" + root.glyph.d + "' fill='" + root.rgb(root.tint) + "' fill-opacity='" + root.tint.a + "'/></svg>")
    }

    Image {
        id: logo
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        visible: false
        source: root.iconSource
        sourceSize: Qt.size(root.iconSize * 2, root.iconSize * 2)
    }

    MultiEffect {
        anchors.fill: logo
        source: logo
        visible: root.glyph === null && root.iconSource !== ""
        colorization: 1.0
        colorizationColor: root.tint
    }

    PanelIcon {
        anchors.centerIn: parent
        visible: root.glyph === null && root.iconSource === ""
        name: "bolt"
        size: root.iconSize
        color: root.tint
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: Omnibox.toggle() }
}
