import QtQuick
import Quickshell
import qs.services
import qs.modules.panel
import qs.modules.osd
import qs.modules.screenshot
import qs.modules.lock
import qs.modules.settings
import qs.modules.crop
import qs.modules.stealthcast
import qs.modules.notes
import qs.modules.vignette
import qs.modules.picker

ShellRoot {
    Component.onCompleted: {
        Events.start()
        Perf.start()
        Drives.start()
        Omnibox.start()
        Notes.start()
        GameMode.start()
        TimerService.start()
        NightLight.start()
    }

    Variants {
        model: Quickshell.screens
        Panel {}
    }

    Variants {
        model: Quickshell.screens
        PanelReserve { edge: "left" }
    }

    Variants {
        model: Quickshell.screens
        PanelReserve { edge: "bottom" }
    }

    Variants {
        model: Quickshell.screens
        PanelReserve { edge: "top" }
    }

    Variants {
        model: Quickshell.screens
        PanelReserve { edge: "right" }
    }

    Variants {
        model: Quickshell.screens
        Vignette {}
    }

    Variants {
        model: Quickshell.screens
        PaintHud {}
    }

    Variants {
        model: Quickshell.screens
        Osd {}
    }

    Variants {
        model: Quickshell.screens
        OsdSide {}
    }

    Variants {
        model: Quickshell.screens
        OsdLayout {}
    }

    Variants {
        model: Quickshell.screens
        ShotOverlay {}
    }

    Variants {
        model: Quickshell.screens
        CropOverlay {}
    }

    Variants {
        model: Quickshell.screens
        CastOverlay {}
    }

    Variants {
        model: Notes.pinned
        Sticky {}
    }

    Lock {}

    Settings {}
}
