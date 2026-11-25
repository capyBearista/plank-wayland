import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root
    required property var settings
    property var apps: []
    property bool popupOpen: false
    property var menuApp: null
    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null
    readonly property var visibleWindows: (Hyprland.toplevels.values || []).filter(w =>
        w.monitor === monitor && monitor && w.workspace === monitor.activeWorkspace && !(w.wayland && w.wayland.minimized))
    readonly property bool hasFullscreen: visibleWindows.some(w => w.wayland && w.wayland.fullscreen)
    readonly property bool overlaps: {
        if (!settings.smartHide || !screen) return false
        const left = screen.x + (screen.width - dock.barWidth) / 2
        const right = left + dock.barWidth
        const top = screen.y + screen.height - dock.bottomGap - dock.barHeight
        const bottom = screen.y + screen.height - dock.bottomGap
        return visibleWindows.some(w => {
            if (w.wayland && w.wayland.fullscreen) return true
            const ipc = w.lastIpcObject
            return ipc && ipc.at && ipc.size &&
                ipc.at[0] < right && ipc.at[0] + ipc.size[0] > left &&
                ipc.at[1] < bottom && ipc.at[1] + ipc.size[1] > top
        })
    }
    property var previousUrgent: []
    property bool attentionHold: false
    readonly property var urgentKeys: apps.filter(app => app.urgent && app.toplevels.some(w => w.urgent && !w.activated && w.monitor === monitor)).map(app => app.canonicalId || app.appId)

    signal activateApp(var app)
    signal menuRequested(var app, real x, real bottom)
    signal menuCloseRequested()
    signal settingsRequested()
    signal reorderRequested(string fromKey, string beforeKey)
    signal launcherRequested()

    function requestMenu(app) {
        if (app) menuRequested(app, dock.x + dock.menuX, dock.menuBottomMargin)
    }

    onUrgentKeysChanged: {
        const added = urgentKeys.some(key => !previousUrgent.includes(key))
        previousUrgent = urgentKeys.slice()
        if (!urgentKeys.length) { attentionHold = false; attentionTimer.stop() }
        if (added && settings.dockValues.attentionReveal && (!hasFullscreen || settings.dockValues.attentionInFullscreen) && !attentionHold) {
            attentionHold = true
            attentionTimer.restart()
        }
    }

    onHasFullscreenChanged: if (hasFullscreen && !settings.dockValues.attentionInFullscreen) {
        attentionHold = false
        attentionTimer.stop()
    }

    Timer {
        id: attentionTimer
        interval: root.settings.dockValues.attentionRevealMs
        repeat: false
        onTriggered: root.attentionHold = false
    }

    Timer {
        interval: 750
        repeat: true
        running: root.settings.smartHide
        onTriggered: Hyprland.refreshToplevels()
    }

    anchors { left: true; right: true; bottom: true }
    color: "transparent"
    implicitHeight: dock.layerHeight + dock.bottomGap
    exclusiveZone: dock.autoHide || dock.smartHideEnabled ? 0 : Math.ceil(dock.barHeight + dock.bottomGap)
    WlrLayershell.namespace: "plank-wayland-dock"
    mask: Region {
        item: edge
        Region { item: dockInput }
    }

    Item {
        id: edge
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: (dock.autoHide || dock.smartHideEnabled) ? dock.edgeTriggerHeight : 0
        z: 2
        HoverHandler { id: edgeHover; enabled: edge.height > 0; blocking: false }
    }

    Item {
        id: dockInput
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: Math.min(parent.width, dock.barWidth)
        height: dock.hidden ? 0 : dock.barHeight + dock.bottomGap
        z: 1
        HoverHandler { id: dockHover; blocking: false }
    }

    Dock {
        id: dock
        anchors.horizontalCenter: parent.horizontalCenter
        surfaceHovered: edgeHover.hovered || dockHover.hovered
        apps: root.apps
        settings: root.settings
        smartHideEnabled: root.settings.smartHide
        isOverlapped: root.overlaps
        menuOpen: root.popupOpen
        attentionHold: root.attentionHold
        menuApp: root.menuApp
        onActivate: app => root.activateApp(app)
        onOpenMenu: app => root.requestMenu(app)
        onCloseMenuRequested: root.menuCloseRequested()
        onReorderRequested: (fromKey, beforeKey) => root.reorderRequested(fromKey, beforeKey)
        onLaunch: root.launcherRequested()
        onSettingsRequested: root.settingsRequested()
    }
}
