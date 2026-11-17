import QtQuick
import qs.theme
import qs.services
import qs.components

// The running or finished long job from Drives (write, Windows installer, Ventoy, backup, tests, erase, import):
// logo or icon, the big percentage, the current step with speed and time left, then the result. It covers the tabs
// of the branch while it runs, so the drive is not touched from two places at once.
Item {
    id: root

    property var disk: null

    readonly property string stage: Drives.jobStage
    readonly property bool running: Drives.jobRunning
    readonly property bool measured: Drives.jobTotal > 0
    readonly property bool bad: stage === "error" || (stage === "done" && !Drives.jobGood)

    function eta() {
        if (Drives.jobSpeed <= 0 || !measured) return ""
        const s = Math.max(0, (Drives.jobTotal - Drives.jobDone) / Drives.jobSpeed)
        return s < 60 ? Math.ceil(s) + " s left" : Math.ceil(s / 60) + " min left"
    }

    Rectangle {
        id: badge
        anchors.horizontalCenter: parent.horizontalCenter
        y: 4
        width: 64
        height: 64
        radius: Theme.radiusMd
        color: Theme.panelPill
        DistroLogo {
            anchors.centerIn: parent
            visible: Drives.jobLogo !== ""
            path: Drives.jobLogo
            name: Drives.jobTitle
            size: 30
            color: root.bad ? Theme.danger : Theme.accent
        }
        PanelIcon {
            anchors.centerIn: parent
            visible: Drives.jobLogo === ""
            name: Drives.jobIcon !== "" ? Drives.jobIcon : "usb"
            size: 30
            color: root.bad ? Theme.danger : Theme.accent
        }
    }

    Text {
        id: headline
        anchors { top: badge.bottom; topMargin: Theme.padTile; horizontalCenter: parent.horizontalCenter }
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        color: root.bad ? Theme.danger : Theme.text
        font { family: Theme.fontUi; pixelSize: root.running && !root.measured ? 18 : 26; weight: Theme.wHeavy }
        text: root.stage === "error" ? "Failed"
            : root.stage === "done" ? (Drives.jobGood ? "Done" : "Problem found")
            : root.measured ? Math.floor(Drives.jobRatio * 100) + "%"
            : Drives.jobLabel
    }

    Text {
        id: detail
        anchors { top: headline.bottom; topMargin: 4; horizontalCenter: parent.horizontalCenter }
        width: parent.width - 2 * Theme.padTile
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        maximumLineCount: 3
        elide: Text.ElideRight
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        text: {
            if (root.stage === "error") return Drives.jobError
            if (root.stage === "done") return Drives.jobResult
            const bits = [Drives.jobTitle]
            if (root.measured) {
                bits.push(Drives.jobLabel)
                if (Drives.jobSpeed > 0) bits.push(Drives.size(Drives.jobSpeed) + "/s")
                const e = root.eta()
                if (e !== "") bits.push(e)
            } else if (root.stage === "auth") {
                bits.push("allow it in the password prompt")
            }
            return bits.join(" · ")
        }
    }

    Item {
        visible: root.running
        anchors { top: detail.bottom; topMargin: Theme.padTile; horizontalCenter: parent.horizontalCenter }
        width: parent.width - 4 * Theme.padTile
        height: 8
        Rectangle { anchors.fill: parent; radius: 4; color: Theme.panelTrack }
        Rectangle {
            width: parent.width * (root.measured ? Drives.jobRatio : 1)
            height: parent.height
            radius: 4
            color: Theme.accent
            opacity: root.measured ? 1 : Theme.disabledOpacity
            Behavior on width { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easingCalm } }
        }
    }

    Row {
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
        spacing: Theme.gapTile

        ActionButton {
            visible: root.running
            text: root.stage === "verify" ? "Skip check" : "Cancel"
            danger: root.stage !== "verify"
            onClicked: Drives.cancel()
        }
        ActionButton {
            visible: root.stage === "done" && Drives.jobPath !== ""
            icon: "folder"
            text: "Show"
            onClicked: Drives.jobKind === "import" ? Qt.openUrlExternally("file://" + Drives.jobPath)
                : Qt.openUrlExternally("file://" + Drives.jobPath.replace(/\/[^/]*$/, ""))
        }
        ActionButton {
            visible: root.stage === "done" && ["write", "windows", "ventoy", "copy", "import"].indexOf(Drives.jobKind) >= 0
                && Drives.drives.some(d => d.dev === Drives.jobDev)
            icon: "eject"
            text: "Eject"
            primary: true
            onClicked: { Drives.eject(Drives.jobDev); Drives.clearJob() }
        }
        ActionButton {
            visible: !root.running
            text: root.stage === "error" ? "Close" : "Done"
            onClicked: Drives.clearJob()
        }
    }
}
