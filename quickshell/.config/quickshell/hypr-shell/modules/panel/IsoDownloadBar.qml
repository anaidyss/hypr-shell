import QtQuick
import qs.theme
import qs.services
import qs.components

// The running (or failed) mirror download in one line: logo, what, percent, speed and time left, a thin bar, and a
// button that pauses it (the next try resumes) or dismisses the error.
Item {
    id: root

    readonly property var e: IsoMirror.current
    readonly property bool failed: IsoMirror.dlStage === "error"
    readonly property var info: e ? (IsoLibrary.distro(e.id) || IsoLibrary.distro("linux")) : null

    height: 30

    function eta() {
        if (IsoMirror.dlSpeed <= 0 || IsoMirror.dlTotal <= 0) return ""
        const s = (IsoMirror.dlTotal - IsoMirror.dlDone) / IsoMirror.dlSpeed
        return s < 60 ? Math.ceil(s) + " s" : s < 3600 ? Math.ceil(s / 60) + " min" : (s / 3600).toFixed(1) + " h"
    }

    DistroLogo {
        id: logo
        anchors.verticalCenter: parent.verticalCenter
        path: root.info ? root.info.path : ""
        name: root.info ? root.info.name : ""
        size: 16
        color: root.failed ? Theme.danger : Theme.textDim
    }
    Text {
        anchors { left: logo.right; leftMargin: 8; right: btn.left; rightMargin: 8; top: parent.top; topMargin: 2 }
        elide: Text.ElideRight
        color: root.failed ? Theme.danger : Theme.text
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        text: {
            if (!root.e) return ""
            if (root.failed) return IsoMirror.dlError
            const bits = [IsoMirror.title(root.e)]
            if (IsoMirror.dlTotal > 0) {
                bits.push(Math.floor(IsoMirror.dlRatio * 100) + "%")
                if (IsoMirror.dlSpeed > 0) bits.push(Drives.size(IsoMirror.dlSpeed) + "/s")
                const t = root.eta()
                if (t !== "") bits.push(t)
            } else {
                bits.push(IsoMirror.dlLabel)
            }
            if (IsoMirror.queue.length > 0) bits.push("+" + IsoMirror.queue.length + " queued")
            return bits.join(" · ")
        }
    }
    Item {
        visible: !root.failed
        anchors { left: logo.right; leftMargin: 8; right: btn.left; rightMargin: 8; bottom: parent.bottom; bottomMargin: 4 }
        height: 4
        Rectangle { anchors.fill: parent; radius: 2; color: Theme.panelTrack }
        Rectangle {
            width: parent.width * (IsoMirror.dlTotal > 0 ? IsoMirror.dlRatio : 1)
            height: parent.height
            radius: 2
            color: Theme.accent
            opacity: IsoMirror.dlTotal > 0 ? 1 : Theme.disabledOpacity
            Behavior on width { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easingCalm } }
        }
    }
    IconButton {
        id: btn
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        icon: root.failed ? "close" : "pause"
        onClicked: root.failed ? IsoMirror.dismiss() : IsoMirror.cancel()
    }
}
