import QtQuick
import qs.theme
import qs.services
import qs.components

// The category tabs of the strip's tool menus: hover one to unfold its options, hover an option to open its menu.
// A dot on a tab means something in that category is on (RailMenus.categoryActive); tabs can be hidden in the strip editor.
PanelGroup {
    id: root

    property string screenName: ""

    readonly property var tabs: RailMenus.categories.filter(c => RailLayout.tabVisible(c.id))
    readonly property bool wanted: tabs.length > 0

    tone: Theme.tertiaryContainer
    padding: 4
    visible: wanted

    Repeater {
        model: root.tabs

        PanelButton {
            id: tab
            required property var modelData
            width: 32; height: 32; iconSize: 18
            icon: modelData.icon
            kind: "menu"
            clickOpens: false
            menuId: modelData.id
            screenName: root.screenName

            Rectangle {
                visible: RailMenus.categoryActive(tab.modelData.id)
                x: tab.width - width - 3
                y: 3
                width: 8; height: 8; radius: 4
                color: Theme.accent
            }
        }
    }
}
