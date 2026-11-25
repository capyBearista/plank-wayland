import Quickshell.Widgets
import Quickshell
import QtQuick
import "../settings.js" as DockSettings

Rectangle {
    id: root

    required property var app
    property var settings: null
    readonly property var theme: settings ? settings.theme : DockSettings.theme
    readonly property bool followSystemIconTheme: settings ? settings.followSystemIconTheme : ((root.settings ? root.settings.dockValues.followSystemIconTheme : DockSettings.dock.followSystemIconTheme) !== false)
    readonly property int iconThemeRevision: settings ? settings.iconThemeRevision : 0
    readonly property string rawIcon: String(root.app.icon || "")
    readonly property bool rawFileIcon: rawIcon.startsWith("/")
    readonly property bool launcherIcon: root.app.launcherIcon === true
    readonly property string lookupIcon: rawFileIcon ? String(root.app.appId || root.app.name || "") : rawIcon
    readonly property var lookupIcons: buildLookupIcons()
    readonly property string resolvedThemeIcon: launcherIcon && rawFileIcon ? ("file://" + rawIcon) : (settings ? settings.iconSource(lookupIcons, iconThemeRevision, rawFileIcon ? rawIcon : "") : resolveThemeIcon(lookupIcon, followSystemIconTheme, iconThemeRevision, rawFileIcon ? rawIcon : ""))
    property int itemIndex: 0

    property real dockMouseX: -10000
    property real zoomProgress: 0
    property real dockWidth: 0
    property int itemCount: 0
    property real baseItemSize: 50
    property real zoomPercent: 1.5
    property real zoomIconSize: baseItemSize * zoomPercent
    property real dockSpacing: 8
    property real dockItemsWidth: 0
    property real bottomPadding: 0
    property real layerHeight: 118
    property bool hovered: false
    property bool dragEnabled: false
    property bool dragging: false
    signal dragStarted(var app, real dockX)
    signal dragMoved(real dockX)
    signal dragFinished(real dockX, bool accepted)
    property bool menuOpen: false
    readonly property bool hasMultipleWindows: root.app.running === true && (root.app.toplevels || []).length > 1

    signal activate(var app)
    signal openMenu(var app)
    signal closeMenuRequested()
    signal pointerMoved(real dockX)
    signal pointerExited()

    readonly property real baseStep: baseItemSize + dockSpacing
    readonly property real baseStart: (dockWidth - dockItemsWidth) / 2
    readonly property real staticCenter: Math.floor(baseStart + itemIndex * baseStep + baseItemSize / 2)
    property real distanceRaw: Math.abs(dockMouseX - staticCenter)
    property real offsetBase: Math.min(distanceRaw, zoomIconSize)
    property real offsetPercent: zoomIconSize > 0 ? Math.min(1, offsetBase / zoomIconSize) : 1
    property real zoomInPercent: 1 + (zoomPercent - 1) * zoomProgress
    property real zoomShape: 1 - Math.pow(offsetPercent, 2)
    property real zoom: 1 + zoomShape * (zoomInPercent - 1)
    property real offset: offsetBase * (zoomInPercent - 1) * (1 - offsetPercent / 3)
    property real centerPosition: staticCenter + (dockMouseX > staticCenter ? -offset : offset)
    property real lift: baseItemSize * zoom / 2 - baseItemSize / 2
    property real bounceLift: 0
    // Fixed-size icons must not share overlapping mouse hit areas.
    readonly property real hitHorizontalMargin: zoomPercent <= 1
        ? Math.floor(Math.max(0, dockSpacing / 2))
        : Math.ceil(Math.max(6, (baseItemSize * zoom - baseItemSize) / 2 + 8))
    readonly property real hitTopMargin: Math.ceil(Math.max(6, lift + bounceLift + (baseItemSize * zoom - baseItemSize) + 8))

    function trigger(button) {
        if (button === Qt.RightButton) {
            root.openMenu(root.app)
            return
        }

        if ((root.settings ? root.settings.dockValues.launchBounceHeight : DockSettings.dock.launchBounceHeight) > 0) launchBounce.restart()
        root.activate(root.app)
    }

    function reportPointer(localX) {
        pointerMoved(x + hitMouse.x + localX)
    }

    function buildLookupIcons() {
        const result = []
        const aliases = root.app.iconAliases || []
        for (let i = 0; i < aliases.length; i++) {
            const alias = String(aliases[i] || "")
            if (alias && result.indexOf(alias) < 0) result.push(alias)
        }
        if (lookupIcon && result.indexOf(lookupIcon) < 0) result.push(lookupIcon)
        return result
    }

    function resolveThemeIcon(icon, followTheme, revision, fallbackPath) {
        if (!icon) return fallbackPath ? "file://" + fallbackPath : ""
        const path = followTheme ? Quickshell.iconPath(icon, true) : ""
        return path || (fallbackPath ? "file://" + fallbackPath : "image://icon/" + icon)
    }

    width: baseItemSize
    height: baseItemSize
    x: centerPosition - width / 2
    y: layerHeight - baseItemSize - bottomPadding
    z: zoom
    opacity: 1.0
    scale: 1
    transformOrigin: Item.Bottom
    radius: 18
    color: app.urgent ? "#55e8a035" : (dragging ? "#5580aaff" : (app.running ? theme.runningItemColor : "transparent"))

    Item {
        id: iconShell
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.lift + root.bounceLift
        width: root.baseItemSize
        height: root.baseItemSize
        scale: Math.max(0.1, root.zoom)
        z: root.zoom
        transformOrigin: Item.Bottom

        IconImage {
            id: iconImage
            anchors.fill: parent
            anchors.margins: 5
            source: root.launcherIcon && !root.rawIcon ? "" : root.resolvedThemeIcon
            asynchronous: true
            mipmap: true
            visible: status === Image.Ready && (!root.launcherIcon || root.rawIcon !== "")
        }

        Grid {
            anchors.centerIn: parent
            columns: 3
            rows: 3
            spacing: Math.max(2, root.baseItemSize * 0.055)
            visible: root.launcherIcon && !iconImage.visible

            Repeater {
                model: 9
                Rectangle {
                    width: Math.max(5, root.baseItemSize * 0.14)
                    height: width
                    radius: width * 0.32
                    color: root.theme.textColor || "white"
                }
            }
        }

        Image {
            id: fileIconImage
            anchors.fill: parent
            anchors.margins: 5
            source: ""
            mipmap: true
            smooth: true
            visible: false
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 5
            radius: 8
            color: Qt.hsla((root.app.appId.length * 0.137) % 1, 0.6, 0.7, 1)
            visible: !root.launcherIcon && !iconImage.visible && !fileIconImage.visible

            Text {
                anchors.centerIn: parent
                text: root.app.fallback
                color: "#ffffff"
                font.pixelSize: root.baseItemSize * 0.4
                font.weight: Font.Bold
            }
        }

    }

    Rectangle {
        id: pendingRing
        anchors.fill: iconShell
        radius: 9
        color: "transparent"
        border.width: 2
        border.color: "#e8b45d"
        visible: !root.launcherIcon && root.app.pending === true && root.app.running !== true
        SequentialAnimation on opacity {
            running: pendingRing.visible
            loops: Animation.Infinite
            NumberAnimation { from: 0.3; to: 1; duration: 450 }
            NumberAnimation { from: 1; to: 0.3; duration: 450 }
        }
    }

    Indicator {
        active: !root.launcherIcon && root.app.running === true
        focused: root.app.active === true
        itemZoom: root.zoom
        settings: root.settings
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
    }

    Timer {
        id: hoverMenuTimer
        interval: root.settings ? root.settings.dockValues.hoverMenuDelayMs : 400
        repeat: false
        onTriggered: {
            if (root.hasMultipleWindows && root.hovered && !root.menuOpen && !root.dragging && !hitMouse.pressed) root.openMenu(root.app)
        }
    }

    // Invalidate old hover state when a popup takes or releases pointer input.
    onMenuOpenChanged: {
        root.hovered = false
        hoverMenuTimer.stop()
    }

    DockTooltip {
        text: root.app.name
        // The shared dock pointer gives at most one item ownership of the label.
        shown: root.hovered && hitMouse.containsMouse && !root.menuOpen
            && root.dockMouseX >= root.staticCenter - root.baseStep / 2
            && root.dockMouseX < root.staticCenter + root.baseStep / 2
        settings: root.settings
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 8
    }

    Rectangle {
        width: 14
        height: 14
        radius: 7
        color: root.theme.pinnedBadgeColor
        anchors.right: iconShell.right
        anchors.top: iconShell.top
        visible: root.app.pinned === true
    }

    MouseArea {
        id: hitMouse
        anchors.fill: parent
        anchors.leftMargin: -root.hitHorizontalMargin
        anchors.rightMargin: -root.hitHorizontalMargin
        anchors.topMargin: -root.hitTopMargin
        anchors.bottomMargin: -2
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onEntered: {
            root.hovered = true
            root.reportPointer(mouseX)
            if (root.hasMultipleWindows && !root.menuOpen && !root.dragging) {
                hoverMenuTimer.restart()
            } else if (root.menuOpen && !root.hasMultipleWindows) {
                root.closeMenuRequested()
            }
        }
        property real pressX: 0
        property real pressY: 0
        property bool moved: false
        onPositionChanged: function(mouse) {
            if (pressed && root.dragEnabled && (pressedButtons & Qt.LeftButton) && !moved && Math.hypot(mouse.x - pressX, mouse.y - pressY) > 8) {
                moved = true
                hoverMenuTimer.stop()
                root.dragStarted(root.app, root.x + x + mouse.x)
            }
            if (moved) root.dragMoved(root.x + x + mouse.x)
            if (!root.menuOpen) root.hovered = true
            root.reportPointer(mouse.x)
        }
        onExited: {
            root.hovered = false
            hoverMenuTimer.stop()
            root.pointerExited()
        }
        onPressed: function(mouse) {
            pressX = mouse.x
            pressY = mouse.y
            moved = false
            hoverMenuTimer.stop()
            mouse.accepted = true
        }
        onReleased: function(mouse) {
            if (moved) root.dragFinished(root.x + x + mouse.x, Math.abs(mouse.y - pressY) < root.baseItemSize * 1.5)
            else if (containsMouse) root.trigger(mouse.button)
            moved = false
        }
        onCanceled: {
            if (moved) root.dragFinished(0, false)
            moved = false
        }
    }

    SequentialAnimation {
        id: launchBounce
        running: false
        NumberAnimation {
            target: root
            property: "bounceLift"
            to: Math.min(root.baseItemSize * 0.3, root.baseItemSize * (root.settings ? root.settings.dockValues.launchBounceHeight : DockSettings.dock.launchBounceHeight))
            duration: Math.max(45, (root.settings ? root.settings.dockValues.launchBounceTime : DockSettings.dock.launchBounceTime) * 0.32)
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "bounceLift"
            to: 0
            duration: Math.max(60, (root.settings ? root.settings.dockValues.launchBounceTime : DockSettings.dock.launchBounceTime) * 0.42)
            easing.type: Easing.OutBack
        }
    }
}
