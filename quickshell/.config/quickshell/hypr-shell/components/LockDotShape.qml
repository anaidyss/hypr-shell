import QtQuick

// One password mark of the lock screen in the chosen shape; `size` is the nominal edge length.
Rectangle {
    id: root

    property real size: 24
    property string shape: "square"

    width: shape === "bar" ? Math.max(4, Math.round(size * 0.4)) : (shape === "diamond" ? Math.round(size * 0.8) : size)
    height: shape === "diamond" ? width : size
    radius: shape === "circle" ? width / 2
        : shape === "bar" ? width / 2
        : (shape === "diamond" ? Math.round(width * 0.15) : Math.round(size * 0.2))
    rotation: shape === "diamond" ? 45 : 0
}
