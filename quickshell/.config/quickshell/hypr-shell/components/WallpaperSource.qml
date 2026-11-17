pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The active wallpaper file, watched for changes. Glass backdrops read this to blur the wallpaper inside the shell.
Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/hypr-shell"
    property string path: ""
    readonly property string url: path !== "" ? "file://" + path : ""

    FileView {
        path: root.stateDir + "/wallpaper"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.path = text().trim()
    }
}