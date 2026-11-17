import QtQuick
import qs.theme

// Text whose old value slides up and fades while the new one rises from below.
Item {
    id: root

    property string text
    property alias color: cur.color
    property alias font: cur.font
    property int elide: Text.ElideNone
    property int horizontalAlignment: Text.AlignLeft

    property string shown: ""
    property bool ready: false

    implicitWidth: cur.implicitWidth
    implicitHeight: cur.implicitHeight

    Component.onCompleted: { shown = text; ready = true }

    onTextChanged: {
        if (!ready || text === shown) return
        old.text = shown
        shown = text
        roll.restart()
    }

    Text { id: old; width: root.width; color: cur.color; font: cur.font; opacity: 0; elide: root.elide; horizontalAlignment: root.horizontalAlignment }
    Text { id: cur; width: root.width; text: root.shown; elide: root.elide; horizontalAlignment: root.horizontalAlignment }

    ParallelAnimation {
        id: roll
        NumberAnimation { target: old; property: "y"; from: 0; to: -root.height / 3; duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot }
        NumberAnimation { target: old; property: "opacity"; from: 1; to: 0; duration: Theme.durNormal; easing.type: Theme.easingCalm }
        NumberAnimation { target: cur; property: "y"; from: root.height / 3; to: 0; duration: Theme.durNormal; easing.type: Theme.easing; easing.overshoot: Theme.overshoot }
        NumberAnimation { target: cur; property: "opacity"; from: 0; to: 1; duration: Theme.durNormal; easing.type: Theme.easingCalm }
    }
}
