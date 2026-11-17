import QtQuick
import qs.theme
import qs.services
import qs.components
import "shot.js" as Shot

// Result card of the editor: output size, folder and format on the left, the actions on the right.
Surface {
    id: root

    // Size of the selection in physical pixels.
    property int srcW: 0
    property int srcH: 0
    property int step: 1
    // Which pop-up is open: "", size, folder, choose or saveas.
    property string menu: ""

    signal copyRequested()
    signal saveRequested()
    signal saveAsRequested(string path)
    signal cancelRequested()

    readonly property var sizes: Shot.sizeOptions(srcW, srcH, step)
    readonly property var size: Shot.targetFor(Screenshot.sizeId, srcW, srcH, step)
    readonly property bool canSave: Screenshot.effectiveDir !== ""
    readonly property string dirNow: Screenshot.effectiveDir
    readonly property var dirs: {
        const list = [Screenshot.defaultDir]
        for (const d of Screenshot.recent) if (list.indexOf(d) < 0) list.push(d)
        return list
    }

    function tilde(p) { return p.startsWith(Screenshot.home) ? "~" + p.substring(Screenshot.home.length) : p }

    function toggle(name) { menu = menu === name ? "" : name }

    function openSaveAs() { menu = "saveas" }

    radius: Theme.radiusMd
    color: Theme.panelBase
    width: row.width + 16
    height: 46

    MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.AllButtons }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        ShotChip {
            id: sizeChip
            anchors.verticalCenter: parent.verticalCenter
            icon: "image"
            text: root.size.id === "orig" ? "Original" : root.size.label
            open: root.menu === "size"
            onClicked: root.toggle("size")
        }

        ShotChip {
            id: folderChip
            anchors.verticalCenter: parent.verticalCenter
            icon: root.canSave ? "folder" : "copy"
            text: Shot.dirLabel(root.dirNow, Screenshot.home)
            open: root.menu === "folder" || root.menu === "choose"
            onClicked: root.toggle("folder")
        }

        Row {
            id: formats
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            opacity: root.canSave ? 1 : 0.4

            Repeater {
                model: [{ id: "png", label: "PNG" }, { id: "jpg", label: "JPG" }, { id: "webp", label: "WebP" }]

                Item {
                    required property var modelData
                    readonly property bool on: Screenshot.format === modelData.id

                    width: tag.implicitWidth + 18
                    height: 34

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusSm
                        color: parent.on ? Qt.alpha(Theme.accent, 0.18) : (fmtArea.containsMouse && root.canSave ? Theme.panelHigh : "transparent")
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    }

                    Text {
                        id: tag
                        anchors.centerIn: parent
                        text: modelData.label
                        color: parent.on ? Theme.accent : Theme.textDim
                        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
                    }

                    MouseArea {
                        id: fmtArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.canSave
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Screenshot.setFormat(modelData.id)
                    }
                }
            }
        }

        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 22; color: Theme.border }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: copyRow.width + 28
            height: 34

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusSm
                color: copyArea.containsMouse ? Qt.lighter(Theme.accent, 1.12) : Theme.accent
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
            }

            Row {
                id: copyRow
                anchors.centerIn: parent
                spacing: 7

                PanelIcon { anchors.verticalCenter: parent.verticalCenter; name: "copy"; size: 16; color: Theme.accentText }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Copy"
                    color: Theme.accentText
                    font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
                }
            }

            MouseArea {
                id: copyArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.copyRequested()
            }
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: saveRow.width + 24
            height: 34
            opacity: root.canSave ? 1 : 0.4

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusSm
                color: saveArea.containsMouse && root.canSave ? Theme.panelHigh : Theme.panelRaised
                Behavior on color { ColorAnimation { duration: Theme.durFast } }
            }

            Row {
                id: saveRow
                anchors.centerIn: parent
                spacing: 7

                PanelIcon { anchors.verticalCenter: parent.verticalCenter; name: "save"; size: 16; color: Theme.text }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Save"
                    color: Theme.text
                    font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
                }
            }

            MouseArea {
                id: saveArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.canSave
                cursorShape: Qt.PointingHandCursor
                onClicked: root.saveRequested()
            }
        }

        ShotButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "folder"
            active: root.menu === "saveas"
            onClicked: root.toggle("saveas")
        }

        ShotButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "close"
            onClicked: root.cancelRequested()
        }
    }

    ShotMenu {
        visible: root.menu === "size"
        x: sizeChip.x + row.x
        y: -height - 8
        current: root.size.id
        entries: root.sizes.map(o => ({ id: o.id, label: o.label, hint: o.w + " × " + o.h }))
        onChosen: id => { Screenshot.setSize(id); root.menu = "" }
    }

    ShotMenu {
        visible: root.menu === "folder"
        x: folderChip.x + row.x
        y: -height - 8
        current: root.canSave ? root.dirNow : "@clip"
        entries: [{ id: "@clip", label: "Clipboard only", icon: "copy" }]
            .concat(root.dirs.map(d => ({ id: d, label: Shot.dirLabel(d, Screenshot.home), hint: root.tilde(d), icon: "folder" })))
            .concat([{ id: "@choose", label: "Choose…", icon: "plus" }])
        onChosen: id => {
            if (id === "@choose") { root.menu = "choose"; return }
            Screenshot.setDir(id === "@clip" ? "" : id)
            root.menu = ""
        }
    }

    ShotPathInput {
        visible: root.menu === "choose"
        x: Math.max(-root.x + 8, folderChip.x + row.x)
        y: -height - 8
        text: root.tilde(root.canSave ? root.dirNow : Screenshot.defaultDir)
        hint: "Folder · Enter to use, Esc to close"
        onAccepted: t => {
            if (t.trim() !== "") Screenshot.setDir(t)
            root.menu = ""
        }
        onDismissed: root.menu = ""
    }

    ShotPathInput {
        visible: root.menu === "saveas"
        x: Math.max(-root.x + 8, root.width - width)
        y: -height - 8
        text: {
            const j = Screenshot.makeJob(true, "")
            return root.tilde(j.dir) + "/" + j.base + "." + j.ext
        }
        hint: "File path · Enter to save, Esc to close"
        onAccepted: t => {
            if (t.trim() !== "") root.saveAsRequested(t.trim())
            root.menu = ""
        }
        onDismissed: root.menu = ""
    }
}
