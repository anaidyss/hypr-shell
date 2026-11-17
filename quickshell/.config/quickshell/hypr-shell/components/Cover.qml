import QtQuick
import QtQuick.Effects
import qs.theme
import qs.components

// A picture clipped to a circle or a rounded square that fades in when it changes.
// Without a picture it shows a letter (when `fallback` is set) or a music note.
Item {
    id: root

    property url source
    property real corner: width / 2
    property string fallback: ""
    property bool dim: false

    opacity: dim ? 0.55 : 1
    Behavior on opacity { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easingCalm } }

    // The placeholder takes the high layer of the block it sits on (a hued one on the lock screen).
    readonly property color plate: {
        for (let it = parent; it; it = it.parent)
            if (it.layerHigh !== undefined) return it.layerHigh
        return Theme.panelHigh
    }

    Rectangle {
        anchors.fill: parent
        radius: root.corner
        color: root.plate
    }

    PanelIcon {
        anchors.centerIn: parent
        visible: root.fallback === ""
        name: "music"
        size: root.width * 0.32
        color: Theme.textDim
        opacity: img.status === Image.Ready ? 0 : 1
    }

    Text {
        anchors.centerIn: parent
        visible: root.fallback !== ""
        text: root.fallback
        color: Theme.textDim
        opacity: img.status === Image.Ready ? 0 : 1
        font { family: Theme.fontUi; pixelSize: root.width * 0.42; weight: Theme.wBold }
    }

    Image {
        id: img
        anchors.fill: parent
        visible: false
        asynchronous: true
        source: root.source
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.width * 2, root.height * 2)
        onStatusChanged: {
            if (status === Image.Ready) fade.restart()
            else if (status === Image.Error) retry.later()
        }
    }

    // A network picture that failed (a dropped TLS handshake while the VPN reconnects, say) is asked for again a few
    // times; Qt never retries by itself. The query string makes it a new request instead of the remembered failure.
    Timer {
        id: retry
        property int attempt: 0
        function later() {
            const u = String(root.source)
            if (!/^https?:/.test(u) || attempt >= 4) return
            interval = 1500 * Math.pow(2, attempt)
            start()
        }
        onTriggered: {
            attempt++
            const u = String(root.source)
            img.source = u + (u.indexOf("?") >= 0 ? "&" : "?") + "hs-retry=" + attempt
        }
    }
    onSourceChanged: { retry.stop(); retry.attempt = 0; img.source = Qt.binding(() => root.source) }

    Item {
        id: mask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle { anchors.fill: parent; radius: root.corner }
    }

    MultiEffect {
        id: fx
        anchors.fill: parent
        source: img
        maskEnabled: true
        maskSource: mask
        visible: img.status === Image.Ready
    }

    NumberAnimation { id: fade; target: fx; property: "opacity"; from: 0; to: 1; duration: Theme.durSlow; easing.type: Theme.easingCalm }
}
