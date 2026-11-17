pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Audio spectrum from cava (optional package). Runs only while a view shows it and audio plays (DESIGN.md 8.4, 9.3):
// cava reads the monitor of the default output through PipeWire (`source = auto`; with the equalizer on, WirePlumber
// hands it the filter's monitor) and prints one line of bar heights per frame. Do not name the output as the source:
// cava then cannot match it and PipeWire falls back to the default *input*, the microphone.
Singleton {
    id: root

    property bool wanted: false
    readonly property int bars: 16
    property var values: []
    property bool installed: false
    property bool ready: false

    readonly property bool running: proc.running
    readonly property string sink: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.name : ""
    // Another output: a running cava starts over to follow it.
    onSinkChanged: if (proc.running) { proc.running = false; retry.restart() }
    readonly property string config: Quickshell.env("HOME") + "/.local/state/hypr-shell/cava.conf"

    readonly property string configText: "[general]\nbars = " + bars + "\nframerate = 40\nautosens = 1\n"
        + "[input]\nmethod = pipewire\nsource = auto\n"
        + "[output]\nmethod = raw\nraw_target = /dev/stdout\ndata_format = ascii\nascii_max_range = 100\n"
        + "bar_delimiter = 59\nframe_delimiter = 10\nchannels = mono\n"
        + "[smoothing]\nnoise_reduction = 70\nmonstercat = 1\n"

    Process {
        id: probe
        running: true
        command: ["sh", "-c", "command -v cava >/dev/null"]
        // Installed while the shell runs: look again when someone wants the spectrum.
        onExited: code => root.installed = code === 0
    }

    FileView {
        id: conf
        path: root.config
        printErrors: false
        blockLoading: true
    }

    function ensureConfig() {
        if (conf.text() !== configText) conf.setText(configText)
    }

    Process {
        id: proc
        command: ["cava", "-p", root.config]
        onRunningChanged: if (!running) root.values = []
        // A crash or a missing config: try again a little later while still wanted.
        onExited: if (root.should) retry.restart()
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(";")
                const v = []
                for (let i = 0; i < root.bars; i++) v.push(i < parts.length ? (parseInt(parts[i]) || 0) / 100 : 0)
                root.values = v
            }
        }
    }

    readonly property bool should: wanted && ready && Players.playing
    onShouldChanged: if (should) proc.running = true; else { retry.stop(); proc.running = false }
    Timer { id: retry; interval: 3000; onTriggered: if (root.should) proc.running = true }

    onWantedChanged: if (wanted && !installed && !probe.running) probe.running = true

    onInstalledChanged: if (installed) { ensureConfig(); ready = true }
}
