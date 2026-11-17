import QtQuick
import qs.theme

// Line icons on a 24×24 grid, drawn as SVG in the requested color. In solid mode the same names draw Material Symbols
// Rounded glyphs instead (subset font in theme/.local/share/fonts, rebuilt with pyftsubset from the codepoints below).
Item {
    id: root

    property string name
    property color color: Theme.text
    property real size: 20

    width: size
    height: size

    readonly property var paths: ({
        layout: ["M3 5h18v14H3z", "M9 5v14", "M15 5v14"],
        gamepad: ["M7 8h10a4 4 0 0 1 4 4v1a3 3 0 0 1-5.5 1.7L15 14H9l-.5.7A3 3 0 0 1 3 13v-1a4 4 0 0 1 4-4z", "M8 10.5v3", "M6.5 12h3", "M16 11.5h.01", "M18 12.5h.01"],
        timer: ["M12 8a7 7 0 1 0 0 14 7 7 0 0 0 0-14z", "M12 11v4l2.5 1.5", "M9 3h6", "M12 3v2"],
        pipette: ["M17 3l4 4-3 3-4-4z", "M14 6l4 4", "M14 8L5 17l-1 3 3-1 9-9"],
        smile: ["M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z", "M8.5 14a4.2 4.2 0 0 0 7 0", "M9 10h.01", "M15 10h.01"],
        sliders: ["M4 7h10", "M18 7h2", "M16 5v4", "M4 17h2", "M10 17h10", "M8 15v4"],
        brush: ["M18 3l3 3-9 9-3-3z", "M9 12c-2.5 0-4 1.5-4 4 0 1.5-1 2.5-2 3 3 .5 7 .5 8-3"],
        tabWindows: ["M4 5h16v14H4z", "M4 10h16", "M10 10v9"],
        tabQuick: ["M8 7h8a5 5 0 0 1 0 10H8A5 5 0 0 1 8 7z", "M16 9.5a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5z"],
        tabTools: ["M14 6a4 4 0 0 0 5 5l-8.5 8.5a2.1 2.1 0 0 1-3-3L16 8z", "M14 6l2 2"],
        tabFiles: ["M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"],
        tabShell: ["M4 7h10", "M18 7h2", "M16 5v4", "M4 17h2", "M10 17h10", "M8 15v4"],
        plane: ["M21 16v-2l-8-5V3.5a1.5 1.5 0 0 0-3 0V9l-8 5v2l8-2.5V19l-2 1.5V22l3.5-1 3.5 1v-1.5L13 19v-5.5z"],
        cup: ["M5 9h11v5a5 5 0 0 1-5 5h-1a5 5 0 0 1-5-5z", "M16 10h2a2.5 2.5 0 0 1 0 5h-2", "M8 3v2", "M12 3v2"],
        contrast: ["M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z", "M12 3v18"],
        motion: ["M3 8h11a2.5 2.5 0 1 0-2.5-2.5", "M3 12h16a2.5 2.5 0 1 1-2.5 2.5", "M3 16h8"],
        monitorOff: ["M4 5h16a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z", "M9 20h6", "M12 17v3", "M3 3l18 18"],
        minus: ["M5 12h14"],
        download: ["M12 4v11", "M7 10l5 5 5-5", "M5 20h14"],
        tomato: ["M12 8a7 7 0 1 0 0 14 7 7 0 0 0 0-14z", "M12 8c0-2 1-3.5 3-4", "M12 8c-1-1.5-3-2-4.5-1.5"],
        wifi: ["M3 9.5a14 14 0 0 1 18 0", "M6 13a9.5 9.5 0 0 1 12 0", "M9.2 16.4a5 5 0 0 1 5.6 0", "M12 19.6h.01"],
        bluetooth: ["M7 8l10 8-5 4V4l5 4-10 8"],
        volume: ["M4 10v4h3l5 4V6L7 10z", "M16 9.5a4 4 0 0 1 0 5", "M18.5 7a7.5 7.5 0 0 1 0 10"],
        mute: ["M4 10v4h3l5 4V6L7 10z", "M16 10l5 5", "M21 10l-5 5"],
        battery: ["M5 8h11a2.5 2.5 0 0 1 2.5 2.5v3A2.5 2.5 0 0 1 16 16H5a2.5 2.5 0 0 1-2.5-2.5v-3A2.5 2.5 0 0 1 5 8z", "M21 11v2"],
        bolt: ["M13 3L5.5 13.5H11L10 21l8-11h-5.5z"],
        play: ["M8 5.5v13l11-6.5z"],
        pause: ["M8 5v14", "M16 5v14"],
        prev: ["M18 6v12L8.5 12z", "M6 6v12"],
        next: ["M6 6v12l9.5-6z", "M18 6v12"],
        bell: ["M6 16v-5a6 6 0 0 1 12 0v5l1.5 2h-15z", "M10 21h4"],
        bellOff: ["M6 16v-5a6 6 0 0 1 12 0v5l1.5 2h-15z", "M10 21h4", "M4 4l16 16"],
        image: ["M5 5h14a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2z", "M3 16l5-5 4 4 3-3 6 5"],
        gear: ["M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6z", "M12 4v2", "M12 18v2", "M4 12h2", "M18 12h2", "M6.3 6.3l1.4 1.4", "M16.3 16.3l1.4 1.4", "M17.7 6.3l-1.4 1.4", "M7.7 16.3l-1.4 1.4"],
        power: ["M12 3v8", "M6.5 6.8a8 8 0 1 0 11 0"],
        lock: ["M6 11h12a1 1 0 0 1 1 1v7a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1v-7a1 1 0 0 1 1-1z", "M8 11V8a4 4 0 0 1 8 0v3"],
        moon: ["M20 14.5A8 8 0 1 1 9.5 4 6.5 6.5 0 0 0 20 14.5z"],
        logout: ["M10 5H6a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1h4", "M14 8l4 4-4 4", "M18 12H9"],
        terminal: ["M5 5h14a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2z", "M7.5 10l3 2-3 2", "M12.5 15h4"],
        chevronDown: ["M6 9l6 6 6-6"],
        close: ["M6 6l12 12", "M18 6L6 18"],
        restart: ["M4 12a8 8 0 1 0 2.5-5.8", "M4 4v4h4"],
        dashboard: ["M4 4h6v6H4z", "M14 4h6v6h-6z", "M4 14h6v6H4z", "M14 14h6v6h-6z"],
        music: ["M9 18V6l11-2v12", "M9 18a3 3 0 1 1-3-3 3 3 0 0 1 3 3z", "M20 16a3 3 0 1 1-3-3 3 3 0 0 1 3 3z"],
        pulse: ["M3 12h4l2.5-6 4 12 2.5-6h5"],
        layers: ["M12 4l9 5-9 5-9-5z", "M3 14l9 5 9-5"],
        mic: ["M12 4a3 3 0 0 1 3 3v5a3 3 0 0 1-6 0V7a3 3 0 0 1 3-3z", "M6 11a6 6 0 0 0 12 0", "M12 17v3"],
        micOff: ["M12 4a3 3 0 0 1 3 3v5a3 3 0 0 1-6 0V7a3 3 0 0 1 3-3z", "M6 11a6 6 0 0 0 12 0", "M12 17v3", "M4 4l16 16"],
        sun: ["M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8z", "M12 3v2", "M12 19v2", "M3 12h2", "M19 12h2", "M5.6 5.6L7 7", "M17 17l1.4 1.4", "M18.4 5.6L17 7", "M7 17l-1.4 1.4"],
        chevronLeft: ["M15 6l-6 6 6 6"],
        plus: ["M12 5v14", "M5 12h14"],
        chevronRight: ["M9 6l6 6-6 6"],
        shuffle: ["M16 4h5v5", "M4 20L21 4", "M21 15v5h-5", "M15 15l6 5", "M4 4l5 5"],
        repeat: ["M17 3l4 4-4 4", "M3 11v-1a3 3 0 0 1 3-3h15", "M7 21l-4-4 4-4", "M21 13v1a3 3 0 0 1-3 3H3"],
        repeatOne: ["M17 3l4 4-4 4", "M3 11v-1a3 3 0 0 1 3-3h15", "M7 21l-4-4 4-4", "M21 13v1a3 3 0 0 1-3 3H3", "M11 10.5l1.5-1V15"],
        box: ["M12 3l8 4.5v9L12 21l-8-4.5v-9z", "M4 7.5l8 4.5 8-4.5", "M12 12v9"],
        monitor: ["M4 5h16a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z", "M9 20h6", "M12 17v3"],
        clock: ["M12 4a8 8 0 1 0 0 16 8 8 0 0 0 0-16z", "M12 8v4l3 2"],
        cloud: ["M7.5 17a4 4 0 0 1-.5-7.97 5.5 5.5 0 0 1 10.6-.6A4.3 4.3 0 0 1 17 17z"],
        cloudSun: ["M8 2.5V4", "M2.5 8H4", "M3.9 3.9l1 1", "M12.1 3.9l-1 1", "M5 10.5A3.5 3.5 0 1 1 10.8 7", "M9.5 21a3.5 3.5 0 0 1-.4-7 4.8 4.8 0 0 1 9.3.5 3.8 3.8 0 0 1-.4 6.5z"],
        cloudMoon: ["M10 3a4 4 0 1 0 4.2 5.6A3.3 3.3 0 0 1 10 3z", "M9.5 21a3.5 3.5 0 0 1-.4-7 4.8 4.8 0 0 1 9.3.5 3.8 3.8 0 0 1-.4 6.5z"],
        rain: ["M7.5 14a4 4 0 0 1-.5-7.97 5.5 5.5 0 0 1 10.6-.6A4.3 4.3 0 0 1 17 14z", "M8 17l-1 3", "M12 17l-1 3", "M16 17l-1 3"],
        snow: ["M7.5 14a4 4 0 0 1-.5-7.97 5.5 5.5 0 0 1 10.6-.6A4.3 4.3 0 0 1 17 14z", "M8 18h.01", "M12 20h.01", "M16 18h.01", "M10 17.5h.01", "M14 17.5h.01"],
        storm: ["M7.5 14a4 4 0 0 1-.5-7.97 5.5 5.5 0 0 1 10.6-.6A4.3 4.3 0 0 1 17 14z", "M12.5 14.5l-2.5 3.5h3l-2 3.5"],
        fog: ["M5 9h14", "M3 13h18", "M6 17h12"],
        cpu: ["M7 7h10v10H7z", "M10 10h4v4h-4z", "M9 3v4", "M15 3v4", "M9 17v4", "M15 17v4", "M3 9h4", "M3 15h4", "M17 9h4", "M17 15h4"],
        memory: ["M3 8h18a1 1 0 0 1 1 1v6a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z", "M6 12h.01", "M10 12h.01", "M14 12h.01", "M18 12h.01"],
        chip: ["M3 7h18v10H3z", "M9 9.5a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5z", "M15.5 10h2", "M15.5 14h2"],
        thermo: ["M10 14.5V5a2 2 0 1 1 4 0v9.5a4 4 0 1 1-4 0z", "M12 8v8"],
        disk: ["M4 6a8 3 0 1 0 16 0 8 3 0 1 0-16 0z", "M4 6v12c0 1.7 3.6 3 8 3s8-1.3 8-3V6", "M4 12c0 1.7 3.6 3 8 3s8-1.3 8-3"],
        pointer: ["M6 4l12 6.5-5.2 1.6L10.5 18z"],
        pen: ["M4.5 19.5l1-4.2L16.3 4.5a2.1 2.1 0 0 1 3 3L8.7 18.5z", "M14.5 6.3l3.2 3.2"],
        marker: ["M14.5 4.5l5 5-8.2 8.2H6.2v-5.1z", "M4 20.5h8"],
        slash: ["M5 19L19 5"],
        arrowUpRight: ["M5 19L19 5", "M9.5 5H19v9.5"],
        square: ["M5 6h14v12H5z"],
        circle: ["M12 4a8 8 0 1 0 0 16 8 8 0 0 0 0-16z"],
        type: ["M5 7V5.5h14V7", "M12 5.5v13", "M9 18.5h6"],
        numbered: ["M12 4a8 8 0 1 0 0 16 8 8 0 0 0 0-16z", "M10.3 10.6L12.4 9v6.5"],
        mosaic: ["M5 5h14v14H5z", "M5 5h7v7H5z", "M12 12h7v7h-7z"],
        eraser: ["M4.5 15l8.3-8.3a2 2 0 0 1 2.8 0l3.7 3.7a2 2 0 0 1 0 2.8L12.3 19H8z", "M9.5 10.5l5.5 5.5", "M12.5 19.5H20"],
        undo: ["M9 6L4 11l5 5", "M4 11h10a5 5 0 0 1 0 10h-3"],
        redo: ["M15 6l5 5-5 5", "M20 11H10a5 5 0 0 0 0 10h3"],
        trash: ["M4 7h16", "M9 7V4h6v3", "M6 7l1 13h10l1-13", "M10 11v6", "M14 11v6"],
        check: ["M5 12.5l4.5 4.5L19 7"],
        shield: ["M12 3l7 2.8v5.4c0 4.4-2.8 8-7 9.8-4.2-1.8-7-5.4-7-9.8V5.8z"],
        shieldCheck: ["M12 3l7 2.8v5.4c0 4.4-2.8 8-7 9.8-4.2-1.8-7-5.4-7-9.8V5.8z", "M9 12l2.2 2.2L15.5 10"],
        copy: ["M9 9h11v11H9z", "M5 15V4h11"],
        selection: ["M4 8V4h4", "M16 4h4v4", "M20 16v4h-4", "M8 20H4v-4"],
        appWindow: ["M4 5h16v14H4z", "M4 9.5h16"],
        usb: ["M12 3v13", "M12 16a2 2 0 1 0 0 4 2 2 0 0 0 0-4z", "M12 9l-4 3v2", "M8 14.5h.01", "M12 7l4 2v3", "M16 12.5h.01", "M10.5 3h3"],
        eject: ["M12 5l7 9H5z", "M5 18h14"],
        star: ["M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8-5.2-2.8-5.2 2.8 1-5.8-4.3-4.1 5.9-.9z"],
        folder: ["M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"],
        save: ["M5 4h11l3 3v13H5z", "M8 4v5h7V4", "M8 20v-6h8v6"],
        clipboard: ["M9 4h6v3H9z", "M9 5.5H6.5a1 1 0 0 0-1 1V20a1 1 0 0 0 1 1h11a1 1 0 0 0 1-1V6.5a1 1 0 0 0-1-1H15", "M9 12h6", "M9 16h4"],
        note: ["M6 3h9l4 4v14H6z", "M15 3v4h4", "M9 12h6", "M9 16h4"],
        pin: ["M9 4h6l-.8 6 3 3.2H6.8L9.8 10z", "M12 13.2V20"],
        search: ["M11 4a7 7 0 1 0 0 14 7 7 0 0 0 0-14z", "M16.2 16.2L21 21"],
        calculator: ["M6 3h12a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z", "M8 7h8", "M8.5 12h.01", "M12 12h.01", "M15.5 12h.01", "M8.5 16h.01", "M12 16h.01", "M15.5 16h.01"]
    })

    readonly property var glyphs: ({
        wifi: "\ue63e",
        bluetooth: "\ue1a7",
        volume: "\ue050",
        mute: "\ue04f",
        battery: "\ue1a5",
        bolt: "\uea0b",
        play: "\ue037",
        pause: "\ue034",
        prev: "\ue045",
        next: "\ue044",
        bell: "\ue7f5",
        bellOff: "\ue7f6",
        image: "\ue3f4",
        gear: "\ue8b8",
        power: "\uf8c7",
        lock: "\ue899",
        moon: "\uf159",
        logout: "\ue9ba",
        terminal: "\ueb8e",
        chevronDown: "\ue5cf",
        close: "\ue5cd",
        restart: "\uf053",
        dashboard: "\ue871",
        music: "\ue405",
        pulse: "\uf190",
        layers: "\ue53b",
        mic: "\ue31d",
        micOff: "\ue02b",
        sun: "\ue518",
        chevronLeft: "\ue5cb",
        plus: "\ue145",
        chevronRight: "\ue5cc",
        shuffle: "\ue043",
        repeat: "\ue040",
        repeatOne: "\ue041",
        box: "\uf720",
        monitor: "\ue30c",
        clock: "\uefd6",
        cloud: "\uf15c",
        cloudSun: "\uf172",
        cloudMoon: "\uf174",
        rain: "\uf176",
        snow: "\ue2cd",
        storm: "\uebdb",
        fog: "\ue818",
        cpu: "\ue322",
        memory: "\uf7a3",
        chip: "\ue30d",
        thermo: "\uf076",
        disk: "\uf80e",
        pointer: "\ue569",
        pen: "\uf097",
        marker: "\ue6d1",
        slash: "\uf108",
        arrowUpRight: "\uf1e1",
        square: "\ue835",
        circle: "\uef4a",
        type: "\ue264",
        numbered: "\uf784",
        mosaic: "\ue9b0",
        eraser: "\ue6d0",
        undo: "\ue166",
        redo: "\ue15a",
        trash: "\ue92e",
        check: "\ue668",
        shield: "\ue9e0",
        shieldCheck: "\uf013",
        copy: "\ue14d",
        selection: "\ue3c2",
        appWindow: "\ue069",
        folder: "\ue2c7",
        save: "\ue161",
        clipboard: "\ue14f",
        note: "\uf1fc",
        pin: "\uf10d",
        search: "\uef7a",
        calculator: "\uea5f",
        layout: "\ue8ec",
        gamepad: "\ue6ec",
        timer: "\ue425",
        pipette: "\ue3b8",
        smile: "\ue24e",
        sliders: "\ue429",
        tabWindows: "\ue871",
        tabQuick: "\ue9f6",
        tabTools: "\ue869",
        tabFiles: "\ue2c7",
        tabShell: "\ue429",
        brush: "\ue3ae",
        usb: "\ue1e0",
        eject: "\ue8fb",
        star: "\ue838",
        plane: "\ue539",
        cup: "\uefef",
        contrast: "\ueb37",
        motion: "\ue71c",
        monitorOff: "\ue647",
        minus: "\ue15b",
        tomato: "\ue422",
    })
    readonly property bool useGlyph: Theme.solid && glyphs[name] !== undefined

    function rgb(c) {
        return "rgb(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + ")"
    }

    readonly property string svg: "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='" + rgb(color)
        + "' stroke-opacity='" + color.a + "' stroke-width='1.7' stroke-linecap='round' stroke-linejoin='round'>"
        + (paths[name] ? paths[name].map(d => "<path d='" + d + "'/>").join("") : "") + "</svg>"

    Text {
        anchors.fill: parent
        visible: root.useGlyph
        text: root.useGlyph ? root.glyphs[root.name] : ""
        color: root.color
        font { family: "Material Symbols Rounded"; pixelSize: root.size }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Image {
        anchors.fill: parent
        visible: !root.useGlyph
        source: "data:image/svg+xml;utf8," + encodeURIComponent(root.svg)
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        smooth: true
    }
}
