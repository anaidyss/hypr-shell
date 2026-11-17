import QtQuick
import Quickshell
import qs.theme

Item {
    id: root

    implicitWidth: 276
    implicitHeight: 304

    readonly property var loc: Qt.locale("en_US")
    readonly property date now: clock.date
    readonly property int firstDow: (new Date(now.getFullYear(), now.getMonth(), 1).getDay() + 6) % 7
    readonly property int days: new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
    readonly property var weekdays: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    SystemClock { id: clock; precision: SystemClock.Minutes }

    function cap(s) { return s.charAt(0).toUpperCase() + s.slice(1) }

    Rectangle {
        x: 12; y: 52
        width: parent.width - 24
        height: parent.height - 64
        radius: Theme.radiusLg
        color: Theme.panelRaised
    }

    Text {
        x: 22; y: 20
        text: root.cap(root.loc.standaloneMonthName(root.now.getMonth(), Locale.LongFormat)) + " " + root.now.getFullYear()
        color: Theme.text
        font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
    }

    Text {
        anchors { right: parent.right; rightMargin: 22 }
        y: 23
        text: root.now.toLocaleDateString(root.loc, "dddd, d")
        color: Theme.textDim
        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
    }

    Row {
        x: 26; y: 64
        Repeater {
            model: root.weekdays
            Text {
                required property string modelData
                width: 32
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Theme.textDim
                font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wBold }
            }
        }
    }

    Grid {
        x: 26; y: 90
        columns: 7
        rowSpacing: 2

        Repeater {
            model: root.firstDow + root.days

            Item {
                required property int index
                readonly property int day: index - root.firstDow + 1

                width: 32
                height: 30

                Rectangle {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    radius: Theme.radiusSm
                    visible: parent.day === root.now.getDate()
                    color: Theme.accent
                }

                Text {
                    anchors.centerIn: parent
                    visible: parent.day >= 1
                    text: parent.day
                    color: parent.day === root.now.getDate() ? Theme.accentText : Theme.text
                    font { family: Theme.fontUi; pixelSize: 12; weight: parent.day === root.now.getDate() ? Theme.wStrong : Theme.wBold }
                }
            }
        }
    }
}
