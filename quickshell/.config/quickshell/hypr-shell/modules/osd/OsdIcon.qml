import QtQuick
import QtQuick.Shapes
import qs.theme

Item {
    id: root

    property string kind: "volume"
    property bool muted: false
    property real level: 0

    implicitWidth: 22
    implicitHeight: 22

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeColor: root.kind === "volume" ? Theme.text : "transparent"
            strokeWidth: 1.6
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            startX: 3; startY: 8
            PathLine { x: 7; y: 8 }
            PathLine { x: 12; y: 4 }
            PathLine { x: 12; y: 18 }
            PathLine { x: 7; y: 14 }
            PathLine { x: 3; y: 14 }
            PathLine { x: 3; y: 8 }
        }

        ShapePath {
            strokeColor: root.kind === "volume" && !root.muted && root.level > 0 ? Theme.text : "transparent"
            strokeWidth: 1.6
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: 12; centerY: 11; radiusX: 5; radiusY: 5; startAngle: -40; sweepAngle: 80 }
        }

        ShapePath {
            strokeColor: root.kind === "volume" && !root.muted && root.level > 0.5 ? Theme.text : "transparent"
            strokeWidth: 1.6
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: 12; centerY: 11; radiusX: 8.5; radiusY: 8.5; startAngle: -42; sweepAngle: 84 }
        }

        ShapePath {
            strokeColor: root.kind === "volume" && root.muted ? Theme.text : "transparent"
            strokeWidth: 1.6
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 15.5; startY: 8
            PathLine { x: 20.5; y: 14 }
            PathMove { x: 20.5; y: 8 }
            PathLine { x: 15.5; y: 14 }
        }

        ShapePath {
            strokeColor: root.kind === "brightness" ? Theme.text : "transparent"
            strokeWidth: 1.6
            fillColor: "transparent"
            PathAngleArc { centerX: 11; centerY: 11; radiusX: 4; radiusY: 4; startAngle: 0; sweepAngle: 360 }
        }

        ShapePath {
            strokeColor: root.kind === "brightness" ? Theme.text : "transparent"
            strokeWidth: 1.6
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 17.5; startY: 11
            PathLine { x: 20; y: 11 }
            PathMove { x: 15.6; y: 15.6 }
            PathLine { x: 17.4; y: 17.4 }
            PathMove { x: 11; y: 17.5 }
            PathLine { x: 11; y: 20 }
            PathMove { x: 6.4; y: 15.6 }
            PathLine { x: 4.6; y: 17.4 }
            PathMove { x: 4.5; y: 11 }
            PathLine { x: 2; y: 11 }
            PathMove { x: 6.4; y: 6.4 }
            PathLine { x: 4.6; y: 4.6 }
            PathMove { x: 11; y: 4.5 }
            PathLine { x: 11; y: 2 }
            PathMove { x: 15.6; y: 6.4 }
            PathLine { x: 17.4; y: 4.6 }
        }
    }
}
