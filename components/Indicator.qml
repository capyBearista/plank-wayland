import QtQuick
import "../settings.js" as DockSettings

Rectangle {
    id: root

    property bool active: false
    property bool focused: false
    property real itemZoom: 1
    property var settings: null
    property color customColor: "transparent"
    readonly property var theme: settings ? settings.theme : DockSettings.theme

    readonly property bool lineStyle: theme.indicatorStyle === "line"
    readonly property bool legacyStyle: theme.indicatorStyle === "legacy"
    readonly property color themeText: theme.textColor || "white"
    readonly property bool lightTheme: themeText.r + themeText.g + themeText.b < 1.5
    readonly property color baseColor: theme.indicatorColor || (lightTheme ? "#303640" : "#eeeeee")
    // QML color is a value type, not a JS string. Compare alpha, not strict string equality.
    readonly property color indicatorColor: customColor.a > 0 ? customColor :
        (focused ? (lightTheme ? "#2165ce" : "#79b6ff") : Qt.rgba(baseColor.r, baseColor.g, baseColor.b, Math.max(0.85, baseColor.a)))

    width: active ? (lineStyle ? (root.settings ? root.settings.dockValues.indicatorSize : DockSettings.dock.indicatorSize) * (focused ? 4.5 : 3.2) : (root.settings ? root.settings.dockValues.indicatorSize : DockSettings.dock.indicatorSize) * Math.max(1, Math.min(itemZoom, 1.35))) : 0
    height: active ? (lineStyle ? Math.max(focused ? 3 : 2, (root.settings ? root.settings.dockValues.indicatorSize : DockSettings.dock.indicatorSize) / 2) : (root.settings ? root.settings.dockValues.indicatorSize : DockSettings.dock.indicatorSize)) : 0
    radius: height / 2
    color: indicatorColor
    opacity: active ? (legacyStyle ? 0.65 : 0.95) : 0

    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 2.4
        height: parent.height * 2.4
        radius: height / 2
        color: indicatorColor
        opacity: root.active && root.legacyStyle ? 0.18 : 0
    }
}
