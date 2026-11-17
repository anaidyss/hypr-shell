import QtQuick
import qs.theme
import qs.services
import qs.components

// Equalizer view of the Media tab: on/off and the preset stepper above one graph of the preamp and ten bands.
// Works on all system audio.
Item {
    id: root

    Item {
        id: bar
        width: parent.width
        height: 28

        Switch {
            id: toggle
            anchors.verticalCenter: parent.verticalCenter
            checked: Equalizer.enabled
            enabled: Equalizer.available
            opacity: enabled ? 1 : 0.38
            onToggled: v => Equalizer.setEnabled(v)
        }
        Text {
            anchors { left: toggle.right; leftMargin: 8; verticalCenter: parent.verticalCenter }
            text: Equalizer.enabled ? "Equalizer on" : "Equalizer off"
            color: Equalizer.enabled ? Theme.text : Theme.textDim
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 4
            enabled: Equalizer.available
            opacity: enabled ? 1 : 0.38

            PanelButton {
                icon: "chevronLeft"; vertical: false; clickOpens: false; iconSize: 16
                width: 28; height: 28
                onClicked: Equalizer.stepPreset(-1)
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 88
                horizontalAlignment: Text.AlignHCenter
                text: Equalizer.preset !== "" ? Equalizer.preset : "Custom"
                color: Equalizer.preset !== "" ? Theme.text : Theme.textDim
                elide: Text.ElideRight
                font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wStrong }
            }
            PanelButton {
                icon: "chevronRight"; vertical: false; clickOpens: false; iconSize: 16
                width: 28; height: 28
                onClicked: Equalizer.stepPreset(1)
            }
            PanelButton {
                icon: "restart"; vertical: false; clickOpens: false; iconSize: 16
                width: 28; height: 28
                onClicked: Equalizer.reset()
            }
        }
    }

    EqGraph {
        id: graph
        anchors { top: bar.bottom; topMargin: 12; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: Equalizer.available
    }

    Column {
        anchors.centerIn: graph
        width: parent.width
        spacing: 4
        visible: !Equalizer.available

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Equalizer service is not running"
            color: Theme.danger
            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "systemctl --user enable --now filter-chain"
            color: Theme.textDim
            font { family: Theme.fontMono; pixelSize: 12; weight: Theme.wBold }
        }
    }
}
