import QtQuick
import qs.theme

// The two configured fonts shown as type samples; a warning chip appears when a family is not installed.
Item {
    id: root

    readonly property string uiFamily: Theme.cfg.fonts.ui
    readonly property string monoFamily: Theme.cfg.fonts.mono
    readonly property var installed: Qt.fontFamilies()
    readonly property real cardW: (width - Theme.gapBlock) / 2

    function missing(family) { return installed.indexOf(family) < 0 }

    width: parent ? parent.width : implicitWidth
    implicitHeight: 12 + 212 + 8

    component FontCard: Surface {
        id: card
        property string family
        property string heading
        radius: Theme.radiusMd
        color: Theme.panelRaised
        width: root.cardW
        height: 212
        default property alias content: body.data

        Text {
            x: Theme.padBlock; y: 14
            text: card.heading.toUpperCase()
            color: Theme.textDim
            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy; letterSpacing: 1.3 }
        }
        Text {
            anchors { right: parent.right; rightMargin: Theme.padBlock; top: parent.top; topMargin: 14 }
            visible: !chip.visible
            width: Math.min(implicitWidth, card.width - 120)
            elide: Text.ElideRight
            text: card.family
            color: Theme.textDim
            font { family: Theme.fontMono; pixelSize: 11; weight: Theme.wBold }
        }
        Item {
            id: body
            x: Theme.padBlock; y: 38
            width: parent.width - 2 * Theme.padBlock
            height: parent.height - 38 - 40
        }
        Rectangle {
            id: chip
            visible: root.missing(card.family)
            x: Theme.padBlock
            y: parent.height - height - 12
            width: Math.min(chipText.implicitWidth + 24, parent.width - 2 * Theme.padBlock)
            height: 28
            radius: 14
            color: Qt.alpha(Theme.warning, 0.16)
            Text {
                id: chipText
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                text: "Not installed: " + card.family + ", using " + Qt.application.font.family
                color: Theme.warning
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
            }
        }
        Text {
            visible: !chip.visible
            x: Theme.padBlock
            y: parent.height - height - 12
            height: 28
            verticalAlignment: Text.AlignVCenter
            text: "Installed"
            color: Theme.textOff
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }
    }

    FontCard {
        y: 12
        heading: "Interface"
        family: root.uiFamily

        Column {
            spacing: 4
            Text {
                text: "CAPTION 11"
                color: Theme.textDim
                font { family: root.uiFamily; pixelSize: 11; weight: Theme.wHeavy; letterSpacing: 1.3 }
            }
            Text {
                text: "Body text, 14 Bold"
                color: Theme.text
                font { family: root.uiFamily; pixelSize: 14; weight: Theme.wBold }
            }
            Text {
                text: "Lead line 18"
                color: Theme.text
                font { family: root.uiFamily; pixelSize: 18; weight: Theme.wStrong }
            }
            Text {
                text: "Aa 0123456789"
                color: Theme.accent
                font { family: root.uiFamily; pixelSize: 26; weight: Theme.wStrong }
            }
        }
    }

    FontCard {
        x: root.cardW + Theme.gapBlock
        y: 12
        heading: "Monospace"
        family: root.monoFamily

        Column {
            spacing: 4
            Text {
                text: "$ hs-wallpaper next"
                color: Theme.text
                font { family: root.monoFamily; pixelSize: 14; weight: Theme.wBold }
            }
            Text {
                text: "gap = 14  // px"
                color: Theme.textDim
                font { family: root.monoFamily; pixelSize: 14; weight: Theme.wBold }
            }
            Text {
                text: "if (ok) return 0x2a;"
                color: Theme.accent
                font { family: root.monoFamily; pixelSize: 14; weight: Theme.wBold }
            }
            Text {
                text: "Il1 O0 {} [] => !="
                color: Theme.text
                font { family: root.monoFamily; pixelSize: 18; weight: Theme.wStrong }
            }
        }
    }
}
