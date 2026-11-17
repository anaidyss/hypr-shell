import QtQuick
import QtQuick.Shapes
import qs.theme

// A ring that fills clockwise from the top with `value` (0..1); its content goes in the middle.
Item {
    id: root

    property real value: 0
    property real thickness: 10
    property color trackColor: Theme.panelTrack
    property color fillColor: Theme.accent
    default property alias content: middle.data

    implicitWidth: 200
    implicitHeight: 200

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.trackColor
            strokeWidth: root.thickness
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2; centerY: root.height / 2
                radiusX: (root.width - root.thickness) / 2; radiusY: (root.height - root.thickness) / 2
                startAngle: -90; sweepAngle: 359.9
            }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.fillColor
            strokeWidth: root.thickness
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2; centerY: root.height / 2
                radiusX: (root.width - root.thickness) / 2; radiusY: (root.height - root.thickness) / 2
                startAngle: -90; sweepAngle: Math.max(0.1, 359.9 * Math.max(0, Math.min(1, root.value)))
            }
        }
    }

    Item { id: middle; anchors.fill: parent }
}
