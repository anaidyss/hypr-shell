import QtQuick
import QtQuick.Effects
import qs.theme

// Settings preview for the lock screen: a tiny 16:9 screen with the wallpaper blurred by `lock.blur`
// and a miniature of the lock card. Read-only.
Item {
    id: root

    width: parent ? parent.width : implicitWidth
    implicitHeight: 172

    Item {
        id: screen
        anchors.horizontalCenter: parent.horizontalCenter
        y: 6
        width: 284
        height: 160

        Image {
            id: wall
            anchors.fill: parent
            visible: false
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            source: WallpaperSource.url
            sourceSize: Qt.size(640, 360)
        }

        Rectangle { id: mask; anchors.fill: parent; radius: Theme.radiusSm; color: "white"; layer.enabled: true }
        MultiEffect {
            anchors.fill: parent
            source: wall
            blurEnabled: true
            autoPaddingEnabled: false
            blurMax: 24
            blur: Theme.lockBlur
            saturation: 0
            brightness: -0.2
            maskEnabled: true
            maskSource: mask
            maskThresholdMin: 0
            maskSpreadAtMin: 0
            maskThresholdMax: 1
            maskSpreadAtMax: 1
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusSm
            color: "transparent"
            border.width: 1
            border.color: Theme.border
        }

        Surface {
            anchors.centerIn: parent
            width: 168
            height: 136
            radius: Theme.radiusSm
            color: Theme.blockGlass

            Column {
                anchors.centerIn: parent
                width: parent.width - 24
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(new Date(), "HH:mm")
                    color: Theme.text
                    font { family: Theme.fontUi; pixelSize: 26; weight: Theme.wHeavy }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.locale("en_US").toString(new Date(), "dddd, d MMMM")
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
                }
                Item { width: 1; height: 4 }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24; height: 24; radius: 12
                        color: Theme.panelHigh
                        Text {
                            anchors.centerIn: parent
                            text: "A"
                            color: Theme.textDim
                            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "user"
                        color: Theme.text
                        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wHeavy }
                    }
                }
                Item { width: 1; height: 4 }
                Rectangle {
                    width: parent.width
                    height: 22
                    radius: 11
                    color: Theme.panelPill
                    border.width: 1
                    border.color: Theme.border
                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Repeater {
                            model: 4
                            LockDotShape { size: Math.max(4, Math.round(Theme.cfg.lock.dotSize * 0.28)); shape: Theme.cfg.lock.dotShape; color: Theme.text }
                        }
                    }
                }
            }
        }
    }
}
