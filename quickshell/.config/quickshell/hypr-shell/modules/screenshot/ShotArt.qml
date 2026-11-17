import QtQuick
import qs.theme

// The picture that gets exported: the frozen frame cropped to the selection, with the marks on top.
// Marks live in screen coordinates, so they stay where they are while the selection is resized.
Item {
    id: root

    property url frame
    property var model
    // Screen size in logical pixels.
    property real screenW: 0
    property real screenH: 0
    // Development snapshots swap the real frame for a neutral backdrop.
    property bool plain: false

    clip: true

    Item {
        id: world

        x: -root.x
        y: -root.y
        width: root.screenW
        height: root.screenH

        Item {
            id: baseHost
            anchors.fill: parent

            Image {
                anchors.fill: parent
                visible: !root.plain
                asynchronous: true
                cache: true
                smooth: true
                source: root.frame
            }

            Rectangle {
                anchors.fill: parent
                visible: root.plain
                gradient: Gradient {
                    GradientStop { position: 0; color: "#34373f" }
                    GradientStop { position: 1; color: "#1d1f24" }
                }

                Column {
                    x: 60
                    y: 70
                    spacing: 10
                    Repeater {
                        model: ["Account  4417 2203 9981", "Token  sk-live-83hf9q2", "alice@example.com"]
                        Text { text: modelData; color: "#d8dbe2"; font { family: Theme.fontMono; pixelSize: 22 } }
                    }
                }
            }
        }

        Repeater {
            model: root.model ? root.model.items : []

            ShotMark {
                required property var modelData
                m: modelData
                base: baseHost
                width: world.width
                height: world.height
            }
        }

        ShotMark {
            m: root.model ? root.model.cur : null
            base: baseHost
            visible: m !== null
            width: world.width
            height: world.height
        }
    }
}
