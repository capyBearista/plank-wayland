import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "components"
import "services"
import "settings.js" as DockSettings

ShellRoot {
    id: root

    property var menuApp: null
    property bool menuOpen: false
    property bool launcherOpen: false
    property bool settingsOpen: false
    property bool closeLayerOpen: false
    property real menuX: 0
    property real menuBottomMargin: DockSettings.dock.menuBottomMargin

    WindowActions { id: windowActions }

    function normalizeId(id) {
        return String(id || "").toLowerCase().replace(/\.desktop$/, "")
    }

    function desktopEntryForApp(app) {
        return app ? windowModel.desktopEntry(app.desktopId || app.appId) : null
    }

    function commandArray(command) {
        if (!command) return []
        if (Array.isArray(command)) return command
        if (typeof command === "string") return []
        if (command.length !== undefined) return Array.from(command)
        return []
    }

    function cleanedCommandArray(command) {
        const values = commandArray(command)
        const result = []
        for (let i = 0; i < values.length; i++) {
            const part = String(values[i] || "").trim()
            if (!part || /^%[fFuUdDnNickvm]$/.test(part)) continue
            result.push(part.replace(/%%/g, "%"))
        }
        while (result.length > 1 && result[result.length - 1] === "--") result.pop()
        return result
    }

    function cleanedExec(text) {
        let exec = String(text || "")
        if (!exec) return ""
        exec = exec.replace(/%%/g, "\u0000")
        exec = exec.replace(/%[fFuUdDnNickvm]/g, "")
        exec = exec.replace(/\u0000/g, "%")
        exec = exec.replace(/\s+--\s*$/g, "")
        exec = exec.replace(/\s+/g, " ")
        return exec.trim()
    }

    function looksLikeDesktopId(command, app) {
        const text = String(command || "").trim()
        if (!text || text.indexOf(" ") >= 0 || text.indexOf("/") >= 0) return false
        if (text.indexOf(".") >= 0) return true
        const key = normalizeId(text)
        return key === normalizeId(app && app.appId) || key === normalizeId(app && app.icon)
    }

    function launchApp(app) {
        if (!app || windowModel.isExcluded(app)) return
        if (settingsStore.dockValues.launchFeedback) windowModel.rememberPendingApp(app.desktopId || app.appId)
        const entry = desktopEntryForApp(app)
        const arrayCommand = cleanedCommandArray(app && app.command)
        if (arrayCommand.length > 0) {
            Quickshell.execDetached(arrayCommand)
            return
        }

        const rawCommand = String((app && app.command) || "")
        const command = cleanedExec(rawCommand)
        if (command) {
            if (entry && entry.execute && looksLikeDesktopId(command, app)) {
                entry.execute()
                return
            }
            Quickshell.execDetached(["sh", "-c", command])
            return
        }

        if (entry && entry.execute) {
            entry.execute()
            return
        }

        const fallback = cleanedExec(app && app.appId)
        if (fallback) Quickshell.execDetached(["sh", "-c", fallback])
    }

    function activateApp(app) {
        if (!app) return
        if (app.running && app.toplevels && app.toplevels.length > 0) {
            windowActions.activate(app.toplevels[0], settingsStore.dockValues.minimizeMode)
            return
        }
        if (!app.pending) launchApp(app)
    }

    property bool screensReady: Quickshell.screens && Quickshell.screens.length > 0

    function focusWindowByAddress(win) {
        return windowActions.focusToplevel(win)
    }

    function screenForMonitor(name) {
        try {
            const screens = Quickshell.screens
            if (!screens) return null
            for (let i = 0; i < screens.length; i++) {
                if (screens[i].name === name) return screens[i]
            }
        } catch (e) {}
        return null
    }

    Connections {
        target: Quickshell
        function onScreensChanged() {
            root.screensReady = Quickshell.screens && Quickshell.screens.length > 0
        }
    }

    SettingsStore {
        id: settingsStore
    }

    PinnedApps {
        id: pinnedApps
        overrides: settingsStore.dockValues.identityOverrides
        onChanged: windowModel.update()
    }

    WindowModel {
        id: windowModel
        settings: settingsStore
        pinnedApps: pinnedApps.apps
    }

    property bool isOverlapped: {
        if (!settingsStore.smartHide) return false
        const active = Hyprland.activeToplevel
        if (!active) return false

        // Always hide if fullscreen
        if (active.fullscreen) return true

        try {
            const ipc = active.lastIpcObject
            if (ipc && Array.isArray(ipc.at) && Array.isArray(ipc.size) && ipc.at.length >= 2 && ipc.size.length >= 2) {
                const winBottom = ipc.at[1] + ipc.size[1]
                const screenHeight = dockWindow.screen.height
                // If window is within the bottom 120 pixels of the screen
                return winBottom > (screenHeight - 120)
            }
        } catch (e) {
            console.log("SmartHide: Overlap check failed", e)
        }

        // Fallback for tiled windows if IPC is incomplete
        return !active.floating
    }

    Loader {
        active: root.screensReady && Quickshell.screens && screenForMonitor("HDMI-A-1") !== null
        sourceComponent: Component {
            PanelWindow {
                id: dockWindow
                visible: windowModel.ready

                anchors {
                    left: true
                    right: true
                    bottom: true
                }

                margins {
                    bottom: 0
                }

                color: "transparent"
                implicitHeight: dock.layerHeight + dock.bottomGap
                // Auto-hide must not resize tiled windows when the dock appears.
                exclusiveZone: dock.autoHide || dock.smartHideEnabled
                    ? 0 : Math.ceil(dock.barHeight + dock.bottomGap)
                screen: screenForMonitor("HDMI-A-1")
                WlrLayershell.namespace: "plank-wayland-dock"
                mask: Region {
                    item: dockInputAreaEdge
                    Region { item: dockInputArea }
                }

                // Only the bottom strip and visible dock accept pointer input.
                Item {
                    id: dockInputAreaEdge
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: (dock.autoHide || dock.smartHideEnabled) ? dock.edgeTriggerHeight : 0
                    z: 2

                    HoverHandler {
                        id: dockInputAreaEdgeHover
                        enabled: dockInputAreaEdge.height > 0
                        blocking: false
                    }
                }

                Item {
                    id: dockInputArea
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: dock.barWidth
                    height: dock.hidden ? 0 : dock.barHeight + dock.bottomGap
                    z: 1

                    HoverHandler {
                        id: dockInputAreaHover
                        blocking: false
                    }
                }

                Dock {
                    id: dock
                    anchors.horizontalCenter: parent.horizontalCenter
                    surfaceHovered: dockInputAreaEdgeHover.hovered || dockInputAreaHover.hovered
                    apps: windowModel.dockApps.length > 0 ? windowModel.dockApps : windowModel.pinnedDockApps
                    settings: settingsStore
                    smartHideEnabled: settingsStore.smartHide
                    isOverlapped: root.isOverlapped
                    menuOpen: root.menuOpen || root.settingsOpen
                    menuApp: root.menuApp
                    onActivate: app => {
                        if (app && app.running && app.toplevels && app.toplevels.length > 1) {
                            root.menuApp = app
                            root.menuX = dockWindow.x + dock.x + dock.menuX
                            root.menuBottomMargin = dock.menuBottomMargin
                            root.menuOpen = true
                        } else {
                            root.activateApp(app)
                        }
                    }
                    onOpenMenu: app => {
                        root.menuApp = app
                        root.menuX = dockWindow.x + dock.x + dock.menuX
                        root.menuBottomMargin = dock.menuBottomMargin
                        root.menuOpen = true
                    }
                    onCloseMenuRequested: root.menuOpen = false
                    onReorderRequested: (fromKey, beforeKey) => pinnedApps.reorder(fromKey, beforeKey)
                    onLaunch: Quickshell.execDetached([
    Quickshell.env("HOME") + "/.local/bin/walker-themed"
])
                }
            }
        }
    }

    Loader {
        active: root.screensReady && Quickshell.screens && screenForMonitor("eDP-1") !== null
        sourceComponent: Component {
            PanelWindow {
                id: dockWindowEdp
                visible: windowModel.ready

                anchors {
                    left: true
                    right: true
                    bottom: true
                }

                margins {
                    bottom: 0
                }

                color: "transparent"
                implicitHeight: dockEdp.layerHeight + dockEdp.bottomGap
                // Auto-hide must not resize tiled windows when the dock appears.
                exclusiveZone: dockEdp.autoHide || dockEdp.smartHideEnabled
                    ? 0 : Math.ceil(dockEdp.barHeight + dockEdp.bottomGap)
                screen: screenForMonitor("eDP-1")
                WlrLayershell.namespace: "plank-wayland-dock-edp"
                mask: Region {
                    item: dockEdpInputAreaEdge
                    Region { item: dockEdpInputArea }
                }

                // Only the bottom strip and visible dock accept pointer input.
                Item {
                    id: dockEdpInputAreaEdge
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: (dockEdp.autoHide || dockEdp.smartHideEnabled) ? dockEdp.edgeTriggerHeight : 0
                    z: 2

                    HoverHandler {
                        id: dockEdpInputAreaEdgeHover
                        enabled: dockEdpInputAreaEdge.height > 0
                        blocking: false
                    }
                }

                Item {
                    id: dockEdpInputArea
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: dockEdp.barWidth
                    height: dockEdp.hidden ? 0 : dockEdp.barHeight + dockEdp.bottomGap
                    z: 1

                    HoverHandler {
                        id: dockEdpInputAreaHover
                        blocking: false
                    }
                }

                Dock {
                    id: dockEdp
                    anchors.horizontalCenter: parent.horizontalCenter
                    surfaceHovered: dockEdpInputAreaEdgeHover.hovered || dockEdpInputAreaHover.hovered
                    apps: windowModel.dockApps.length > 0 ? windowModel.dockApps : windowModel.pinnedDockApps
                    settings: settingsStore
                    smartHideEnabled: settingsStore.smartHide
                    isOverlapped: root.isOverlapped
                    menuOpen: root.menuOpen || root.settingsOpen
                    menuApp: root.menuApp
                    onActivate: app => {
                        if (app && app.running && app.toplevels && app.toplevels.length > 1) {
                            root.menuApp = app
                            root.menuX = dockWindowEdp.x + dockEdp.x + dockEdp.menuX
                            root.menuBottomMargin = dockEdp.menuBottomMargin
                            root.menuOpen = true
                        } else {
                            root.activateApp(app)
                        }
                    }
                    onOpenMenu: app => {
                        root.menuApp = app
                        root.menuX = dockEdp.x + dockEdp.menuX
                        root.menuBottomMargin = dockEdp.menuBottomMargin
                        root.menuOpen = true
                    }
                    onCloseMenuRequested: root.menuOpen = false
                    onReorderRequested: (fromKey, beforeKey) => pinnedApps.reorder(fromKey, beforeKey)
                    onLaunch: Quickshell.execDetached([
    Quickshell.env("HOME") + "/.local/bin/walker-themed"
])
                }
            }
        }
    }

    Loader {
        active: root.screensReady && Quickshell.screens && screenForMonitor("HDMI-A-1") !== null
        sourceComponent: Component {
            PanelWindow {
                id: launcherWindow
                visible: true

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                color: "transparent"
                exclusiveZone: 0
                mask: Region { item: root.launcherOpen ? launcher : null }
                WlrLayershell.namespace: "plank-wayland-launcher"
                WlrLayershell.keyboardFocus: root.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                screen: screenForMonitor("HDMI-A-1")

                AppLauncher {
                    id: launcher
                    anchors.fill: parent
                    shown: root.launcherOpen
                    settings: settingsStore
                    onCloseRequested: root.launcherOpen = false
                }
            }
        }
    }

    PanelWindow {
        visible: root.menuOpen

        anchors {
            bottom: true
        }

        margins {
            bottom: Math.round(root.menuBottomMargin)
            left: Math.round(root.menuX)
        }

        color: "transparent"
        implicitWidth: dockMenu.implicitWidth
        // Allow tooltips to render above the menu without moving it upward.
        implicitHeight: Math.ceil(dockMenu.implicitHeight + dockMenu.tooltipHeadroom)
        mask: Region { item: dockMenu }
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        DockMenu {
            id: dockMenu
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: implicitHeight
            opened: root.menuOpen
            app: root.menuApp
            settings: settingsStore
            onPinRequested: app => pinnedApps.pin(app)
            onUnpinRequested: app => pinnedApps.unpin(app.canonicalId || app.appId)
            onSettingsRequested: {
                root.settingsOpen = true
                root.menuOpen = false
            }
            onCloseRequested: root.menuOpen = false
            onFocusWindowRequested: win => {
                root.focusWindowByAddress(win)
                root.menuOpen = false
            }
            onNewWindowRequested: app => {
                root.launchApp(app)
                root.menuOpen = false
            }
        }
    }

    // ESC keybind via Hyprland (configured in hyprland.conf)

    PanelWindow {
        visible: root.settingsOpen

        anchors {
            bottom: true
            right: true
        }

        margins {
            bottom: 24
            right: 24
        }

        color: "transparent"
        implicitWidth: 420
        implicitHeight: 640
        exclusiveZone: 0

        SettingsPanel {
            anchors.fill: parent
            store: settingsStore
            onCloseRequested: root.settingsOpen = false
        }
    }
}
