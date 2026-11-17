import QtQuick
import qs.theme

// A distribution logo: one monochrome 24×24 path (see data/distros.js) filled in `color`, or a monogram of the name
// when there is no path. Logos are content, not interface icons, so they are filled marks rather than PanelIcon lines.
Item {
    id: root

    property string path
    property string name
    property color color: Theme.text
    property real size: 24

    width: size
    height: size

    function rgb(c) {
        return "rgb(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + ")"
    }

    Image {
        anchors.fill: parent
        visible: root.path !== ""
        source: root.path === "" ? "" : "data:image/svg+xml;utf8," + encodeURIComponent(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'><path fill='" + root.rgb(root.color)
            + "' fill-opacity='" + root.color.a + "' d='" + root.path + "'/></svg>")
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        smooth: true
    }

    Text {
        anchors.centerIn: parent
        visible: root.path === ""
        text: root.name.replace(/[^A-Za-z0-9]/g, "").slice(0, 2)
        color: root.color
        font { family: Theme.fontUi; pixelSize: root.size >= 26 ? 18 : root.size >= 18 ? 12 : 11; weight: Theme.wHeavy }
    }
}
