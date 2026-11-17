import QtQuick
import qs.theme
import qs.services
import qs.components

// One image of the ISO library: distribution logo, name and version, size, build date and how old it is.
// Hover shows the checksum and edit buttons; a click selects it for writing.
Item {
    id: root

    required property var item
    property bool selected: false
    signal picked()
    signal edit()

    readonly property bool hashingThis: IsoLibrary.hashing && IsoLibrary.shaFile === item.file
    readonly property var sha: IsoLibrary.shaResult[item.file]
    readonly property bool hot: area.containsMouse || selected
    readonly property var update: item.update
    readonly property bool fetching: update !== null && IsoMirror.queued(update)

    height: 52

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMd
        color: root.selected ? Theme.accentContainer : area.containsMouse ? Theme.panelHigh : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked()
        onDoubleClicked: root.edit()
    }

    Rectangle {
        id: badge
        x: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        height: 36
        radius: Theme.radiusSm
        color: Theme.panelPill
        DistroLogo {
            anchors.centerIn: parent
            path: root.item.logo
            name: root.item.name
            size: 20
            color: Theme.text
        }
    }

    Column {
        anchors { left: badge.right; leftMargin: Theme.padTile; right: tools.left; rightMargin: Theme.gapTile
            verticalCenter: parent.verticalCenter }
        spacing: 2

        Row {
            width: parent.width
            spacing: 8
            Text {
                id: nameText
                width: Math.min(implicitWidth, parent.width - (verText.visible ? verText.implicitWidth + 8 : 0))
                elide: Text.ElideRight
                text: root.item.name
                color: Theme.text
                font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
            }
            Text {
                id: verText
                anchors.baseline: nameText.baseline
                visible: root.item.version !== ""
                text: root.item.version
                color: Theme.textDim
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            }
        }
        Text {
            width: parent.width
            elide: Text.ElideRight
            color: root.sha && root.sha.match === false ? Theme.danger : root.update !== null ? Theme.text : Theme.textDim
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            text: {
                if (root.hashingThis) return "Checking SHA-256 · " + Math.round(IsoLibrary.shaRatio * 100) + "%"
                if (root.sha) {
                    if (root.sha.match === true) return "SHA-256 matches " + root.sha.source
                    if (root.sha.match === false) return "SHA-256 does not match " + root.sha.source
                    return "SHA-256 copied · no checksum file next to it"
                }
                if (root.fetching) return root.update.version + " is downloading"
                const bits = [Drives.size(root.item.size), IsoLibrary.niceDate(root.item.created)]
                // A newer release on the mirror replaces the age: that is the freshness that matters.
                if (root.update !== null) return [root.update.version + " is out"].concat(bits).join(" · ")
                const age = IsoLibrary.age(root.item.created)
                if (age !== "") bits.push(age)
                if (root.item.windows) bits.push("Windows installer")
                else if (!root.item.hybrid) bits.push("may not boot from USB")
                return bits.join(" · ")
            }
        }
    }

    Row {
        id: tools
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 4
        opacity: root.hot ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easingCalm } }

        IconButton {
            visible: root.update !== null
            icon: "download"
            enabled: !root.fetching
            onClicked: IsoMirror.download(root.update)
        }
        IconButton {
            icon: "shieldCheck"
            enabled: !IsoLibrary.hashing
            onClicked: IsoLibrary.checksum(root.item.path, root.item.file)
        }
        IconButton { icon: "pen"; onClicked: root.edit() }
    }
}
