import QtQuick
import Quickshell
import qs.theme
import qs.services
import qs.components

// Month grid and, after picking a day, that day's events with a form to add more.
Block {
    id: root

    // Month view
    property int shift: 0
    property int shownShift: 0
    property int lastShift: 0
    property real gridOpacity: 1
    property real gridDx: 0

    // Day view
    property string selected: ""
    property real dayView: selected !== "" ? 1 : 0
    Behavior on dayView { NumberAnimation { duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot } }

    // Add form
    property int remind: 0
    property bool timeBad: false

    readonly property var loc: Qt.locale("en_US")
    readonly property date now: clock.date
    readonly property date first: new Date(now.getFullYear(), now.getMonth() + shownShift, 1)
    readonly property int firstDow: (first.getDay() + 6) % 7
    readonly property real cell: (width - 2 * pad) / 7
    readonly property real rowH: 40
    readonly property var weekdays: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    readonly property var dayEvents: selected !== "" ? Events.forDate(selected) : []
    readonly property date selectedDate: selected !== "" ? new Date(selected + "T12:00:00") : now
    readonly property bool hasTime: timeField.text.trim() !== ""
    readonly property var remindChoices: Events.remindChoices(hasTime)

    SystemClock { id: clock; precision: SystemClock.Minutes }

    function cap(s) { return s.charAt(0).toUpperCase() + s.slice(1) }

    onShiftChanged: {
        monthAnim.dir = shift > lastShift ? 1 : -1
        lastShift = shift
        monthAnim.restart()
    }

    onHasTimeChanged: if (remindChoices.indexOf(remind) < 0) remind = 0

    onVisibleChanged: if (!visible) {
        endTyping()
        selected = ""
        shift = 0
    }

    function pickDay(d) {
        selected = Events.key(d)
        const diff = (d.getFullYear() - now.getFullYear()) * 12 + d.getMonth() - now.getMonth()
        if (diff !== shift) shift = diff
    }

    function focusField(field) {
        PanelState.typing = true
        PanelState.typed()
        field.forceActiveFocus()
    }

    function endTyping() {
        PanelState.typing = false
        titleField.input.focus = false
        timeField.input.focus = false
    }

    function nextRemind() {
        const c = remindChoices
        remind = c[(c.indexOf(remind) + 1) % c.length]
    }

    function submit() {
        const title = titleInput.text.trim()
        if (title === "") return
        let time = ""
        const t = timeInput.text.trim()
        if (t !== "") {
            const m = t.match(/^(\d{1,2}):?(\d{2})$/)
            if (!m || +m[1] > 23 || +m[2] > 59) { timeBad = true; return }
            time = Events.pad(+m[1]) + ":" + m[2]
        }
        Events.add(selected, time, title, remind)
        titleInput.text = ""
        timeInput.text = ""
        timeBad = false
        PanelState.typed()
    }

    WheelHandler {
        enabled: root.dayView < 0.5
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => root.shift += event.angleDelta.y > 0 ? -1 : 1
    }

    SequentialAnimation {
        id: monthAnim
        property int dir: 1
        ParallelAnimation {
            NumberAnimation { target: root; property: "gridOpacity"; to: 0; duration: Theme.durFast * 0.6; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "gridDx"; to: -monthAnim.dir * 14; duration: Theme.durFast * 0.6; easing.type: Easing.OutQuad }
        }
        ScriptAction { script: { root.shownShift = root.shift; root.gridDx = monthAnim.dir * 14 } }
        ParallelAnimation {
            NumberAnimation { target: root; property: "gridOpacity"; to: 1; duration: Theme.durNormal; easing.type: Theme.easingCalm }
            NumberAnimation { target: root; property: "gridDx"; to: 0; duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot }
        }
    }

    component IconButton: Item {
        id: btn
        property string icon
        property color tint: Theme.textDim
        signal clicked()
        width: 28
        height: 28

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusSm
            color: btnHover.hovered ? Theme.panelHigh : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }
        PanelIcon {
            anchors.centerIn: parent
            name: btn.icon
            size: 16
            color: btnHover.hovered ? Theme.text : btn.tint
        }
        HoverHandler { id: btnHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: btn.clicked() }
    }

    component Field: Rectangle {
        id: field
        property alias input: edit
        property alias text: edit.text
        property string placeholder
        property bool bad: false
        property alias validator: edit.validator
        property alias maximumLength: edit.maximumLength
        signal accepted()
        signal tab()

        height: 30
        radius: Theme.radiusSm
        color: edit.activeFocus ? Theme.panelHigh : Theme.panelPill
        border.width: 1
        border.color: bad ? Theme.danger : (edit.activeFocus ? Theme.borderActive : Theme.border)
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.durFast } }

        Text {
            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
            verticalAlignment: Text.AlignVCenter
            visible: edit.text === ""
            text: field.placeholder
            color: Theme.textOff
            elide: Text.ElideRight
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
        }

        TextInput {
            id: edit
            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentText
            clip: true
            font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
            onTextChanged: PanelState.typed()
            Keys.onReturnPressed: field.accepted()
            Keys.onEnterPressed: field.accepted()
            Keys.onEscapePressed: root.endTyping()
            Keys.onTabPressed: field.tab()
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onClicked: root.focusField(edit)
        }
    }

    // ---- Month view -------------------------------------------------------------------------------
    Item {
        id: monthView
        anchors.fill: parent
        opacity: 1 - root.dayView
        visible: opacity > 0.01
        transform: Translate { x: -16 * root.dayView }

        Item {
            id: header
            width: parent.width
            height: 28

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.cap(root.loc.standaloneMonthName(root.first.getMonth(), Locale.LongFormat)) + " " + root.first.getFullYear()
                color: Theme.text
                opacity: root.gridOpacity
                font { family: Theme.fontUi; pixelSize: 18; weight: Theme.wStrong }

                HoverHandler { cursorShape: root.shift !== 0 ? Qt.PointingHandCursor : Qt.ArrowCursor }
                TapHandler { onTapped: root.shift = 0 }
            }

            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                IconButton { icon: "chevronLeft"; onClicked: root.shift -= 1 }
                IconButton { icon: "chevronRight"; onClicked: root.shift += 1 }
            }
        }

        Row {
            y: 38
            Repeater {
                model: root.weekdays
                Text {
                    required property string modelData
                    width: root.cell
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.textDim
                    font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wHeavy }
                }
            }
        }

        Grid {
            x: root.gridDx
            y: 58
            columns: 7
            opacity: root.gridOpacity

            Repeater {
                model: 42

                Item {
                    id: day
                    required property int index
                    readonly property date d: new Date(root.first.getFullYear(), root.first.getMonth(), 1 - root.firstDow + index)
                    readonly property string dayKey: Events.key(d)
                    readonly property bool inMonth: d.getMonth() === root.first.getMonth()
                    readonly property bool today: d.toDateString() === root.now.toDateString()
                    readonly property int count: Events.byDate[dayKey] || 0

                    width: root.cell
                    height: root.rowH

                    Rectangle {
                        anchors.centerIn: parent
                        width: 32
                        height: 32
                        radius: Theme.radiusSm
                        color: day.today ? Theme.accent : (dayHover.hovered ? Theme.panelHigh : "transparent")
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    }

                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: day.count > 0 ? -2 : 0
                        text: day.d.getDate()
                        color: day.today ? Theme.accentText : (day.inMonth ? Theme.text : Theme.textOff)
                        font { family: Theme.fontUi; pixelSize: 14; weight: day.today ? Theme.wStrong : Theme.wBold }
                    }

                    Row {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 0 }
                        spacing: 2
                        Repeater {
                            model: Math.min(3, day.count)
                            Rectangle {
                                width: 3; height: 3; radius: 1.5
                                color: day.today ? Theme.accentText : Theme.accent
                                opacity: day.inMonth ? 1 : 0.45
                            }
                        }
                    }

                    HoverHandler { id: dayHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.pickDay(day.d) }
                }
            }
        }
    }

    // ---- Day view ---------------------------------------------------------------------------------
    Item {
        id: dayPane
        anchors.fill: parent
        opacity: root.dayView
        visible: opacity > 0.01
        transform: Translate { x: 16 * (1 - root.dayView) }

        Item {
            id: dayHeader
            width: parent.width
            height: 28

            IconButton {
                id: back
                icon: "chevronLeft"
                onClicked: { root.endTyping(); root.selected = "" }
            }

            Text {
                anchors { left: back.right; leftMargin: 4; verticalCenter: parent.verticalCenter }
                text: root.cap(root.loc.dayName(root.selectedDate.getDay(), Locale.LongFormat)) + ", " + root.selectedDate.toLocaleDateString(root.loc, "d MMMM")
                color: Theme.text
                font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wStrong }
            }
        }

        Flickable {
            id: listView
            y: 38
            width: parent.width
            height: form.y - 8 - y
            clip: true
            contentHeight: rows.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: rows
                width: parent.width

                Repeater {
                    model: root.dayEvents

                    Item {
                        id: row
                        required property var modelData
                        width: rows.width
                        height: 34

                        Rectangle {
                            anchors { fill: parent; topMargin: 1; bottomMargin: 1 }
                            radius: Theme.radiusSm
                            color: rowHover.hovered ? Theme.panelHigh : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.durFast } }
                        }

                        Text {
                            x: 8
                            width: 42
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.time !== "" ? row.modelData.time : "all day"
                            color: row.modelData.time !== "" ? Theme.accent : Theme.textDim
                            font { family: Theme.fontUi; pixelSize: 11; weight: Theme.wStrong }
                        }

                        Text {
                            x: 54
                            width: parent.width - 54 - 56
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.title
                            color: row.modelData.fired ? Theme.textDim : Theme.text
                            elide: Text.ElideRight
                            font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
                        }

                        PanelIcon {
                            anchors { right: parent.right; rightMargin: 34; verticalCenter: parent.verticalCenter }
                            visible: row.modelData.remind >= 0
                            name: "bell"
                            size: 14
                            color: row.modelData.fired ? Theme.textOff : Theme.accent
                        }

                        IconButton {
                            anchors { right: parent.right; rightMargin: 2; verticalCenter: parent.verticalCenter }
                            icon: "close"
                            opacity: rowHover.hovered ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
                            onClicked: Events.remove(row.modelData.id)
                        }

                        HoverHandler { id: rowHover }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.dayEvents.length === 0
                text: "No events"
                color: Theme.textDim
                font { family: Theme.fontUi; pixelSize: 14; weight: Theme.wBold }
            }
        }

        Item {
            id: form
            y: parent.height - height
            width: parent.width
            height: 68

            Field {
                id: titleField
                width: parent.width
                placeholder: "New event"
                onAccepted: root.submit()
                onTab: root.focusField(timeField.input)
            }

            Row {
                y: 38
                width: parent.width
                spacing: 6

                Field {
                    id: timeField
                    width: 62
                    placeholder: "all day"
                    bad: root.timeBad
                    maximumLength: 5
                    validator: RegularExpressionValidator { regularExpression: /^\d{0,2}:?\d{0,2}$/ }
                    onTextChanged: root.timeBad = false
                    onAccepted: root.submit()
                    onTab: root.focusField(titleField.input)
                }

                Rectangle {
                    width: parent.width - timeField.width - addButton.width - 12
                    height: 30
                    radius: Theme.radiusSm
                    color: remindHover.hovered ? Theme.panelHigh : Theme.panelPill
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }

                    PanelIcon {
                        x: 9
                        anchors.verticalCenter: parent.verticalCenter
                        name: "bell"
                        size: 14
                        color: root.remind >= 0 ? Theme.accent : Theme.textDim
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: 29; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        text: Events.remindLabel(root.remind, root.hasTime)
                        color: root.remind >= 0 ? Theme.text : Theme.textDim
                        elide: Text.ElideRight
                        font { family: Theme.fontUi; pixelSize: 12; weight: Theme.wBold }
                    }
                    HoverHandler { id: remindHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.nextRemind() }
                }

                Rectangle {
                    id: addButton
                    width: 30
                    height: 30
                    radius: width / 2
                    color: titleField.text.trim() === "" ? Theme.panelPill : Theme.accent
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }

                    PanelIcon {
                        anchors.centerIn: parent
                        name: "plus"
                        size: 16
                        color: titleField.text.trim() === "" ? Theme.textDim : Theme.accentText
                    }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.submit() }
                }
            }
        }
    }
}
