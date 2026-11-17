import QtQuick
import Quickshell

// Click area of a wallpaper thumbnail that can also be dragged out of the window. Drop targets
// that accept the custom type do not exist, so a finished drag is always "ignored" by the
// compositor; hs-walldrop then decides from the cursor position whether it landed on the desktop.
MouseArea {
    id: root

    // Item grabbed as the picture that follows the cursor.
    required property Item source
    // Arguments for hs-walldrop: ["file", path] or ["search", thumbnailName].
    required property var dropArgs

    readonly property string tool: Quickshell.env("HOME") + "/.local/bin/hs-walldrop"

    hoverEnabled: true
    cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
    drag.target: proxy

    Item { id: proxy }

    Drag.active: root.drag.active
    Drag.dragType: Drag.Automatic
    Drag.supportedActions: Qt.CopyAction
    Drag.mimeData: ({ "application/x-hs-wallpaper": root.dropArgs.join("\n") })
    Drag.hotSpot: Qt.point(80, 50)
    Drag.onDragFinished: dropAction => {
        if (dropAction === Qt.IgnoreAction)
            Quickshell.execDetached([root.tool, ...root.dropArgs])
    }

    onPressed: root.source.grabToImage(result => { root.Drag.imageSource = result.url }, Qt.size(160, 100))
}
