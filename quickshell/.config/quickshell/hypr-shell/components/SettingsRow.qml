import QtQuick
import qs.theme

Item {
    id: root

    required property var item
    property real flash: 0

    width: parent ? parent.width : implicitWidth
    implicitHeight: loader.item ? loader.item.implicitHeight : 52

    function highlight() { flashAnim.restart() }

    SequentialAnimation {
        id: flashAnim
        NumberAnimation { target: root; property: "flash"; to: 1; duration: 350; easing.type: Easing.OutCubic }
        PauseAnimation { duration: 1400 }
        NumberAnimation { target: root; property: "flash"; to: 0; duration: 800; easing.type: Easing.InOutSine }
    }

    Rectangle {
        anchors { fill: parent; leftMargin: -10; rightMargin: -10; topMargin: 2; bottomMargin: 2 }
        radius: Theme.radiusSm
        color: Qt.alpha(Theme.accent, 0.14 * root.flash)
        border.width: 1
        border.color: Qt.alpha(Theme.accent, 0.5 * root.flash)
    }

    Loader {
        id: loader
        anchors.fill: parent
        source: root.item.type === "preview" ? root.item.preview + ".qml" : ""
        sourceComponent: root.item.type === "slider" ? sliderC : (root.item.type === "text" ? textC : (root.item.type === "toggle" ? toggleC : (root.item.type === "choice" ? choiceC : null)))
    }

    Component {
        id: toggleC
        SettingsSwitch {
            title: root.item.title
            description: root.item.description
            checked: Theme.cfg[root.item.group][root.item.key]
            onToggled: v => Theme.set(root.item.group, root.item.key, v)
        }
    }

    Component {
        id: sliderC
        SettingsSlider {
            title: root.item.title
            description: root.item.description
            from: root.item.from
            to: root.item.to
            stepSize: root.item.step
            decimals: root.item.decimals
            displayScale: root.item.scale
            suffix: root.item.suffix
            value: Theme.cfg[root.item.group][root.item.key]
            onMoved: v => Theme.set(root.item.group, root.item.key, v)
        }
    }

    Component {
        id: textC
        SettingsText {
            title: root.item.title
            allowEmpty: root.item.allowEmpty === true
            placeholder: root.item.placeholder || ""
            value: Theme.cfg[root.item.group][root.item.key]
            onEdited: v => Theme.set(root.item.group, root.item.key, v)
        }
    }

    Component {
        id: choiceC
        SettingsChoice {
            title: root.item.title
            description: root.item.description
            options: root.item.options
            value: Theme.cfg[root.item.group][root.item.key]
            onPicked: v => Theme.set(root.item.group, root.item.key, v)
        }
    }
}
