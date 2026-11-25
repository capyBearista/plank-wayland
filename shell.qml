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
    property bool settingsOpen: false
    property var popupScreen: null
    readonly property var eligibleScreens: Array.from(Quickshell.screens).filter(screen => !settingsStore.dockValues.excludedMonitors.includes(screen.name))
    property real menuX: 0
    property real menuBottomMargin: DockSettings.dock.menuBottomMargin
    property string menuKey: ""

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

    function launchApp(app) {
        if (!app || windowModel.isExcluded(app)) return
        if (settingsStore.dockValues.launchFeedback) windowModel.rememberPendingApp(app.desktopId || app.appId)
        const entry = desktopEntryForApp(app)
        const arrayCommand = cleanedCommandArray(app && app.command)
        if (arrayCommand.length > 0) {
            Quickshell.execDetached(arrayCommand)
            return
        }

        if (entry && entry.execute) { entry.execute(); return }
        const rawCommand = String((app && app.command) || "")
        const command = cleanedExec(rawCommand)
        if (command) {
            // Legacy explicit command strings are trusted user configuration only.
            if (app.pinned) Quickshell.execDetached(["sh", "-c", command])
            else if (/^[a-zA-Z0-9_./+-]+$/.test(command)) Quickshell.execDetached([command])
            return
        }

        const fallback = cleanedExec(app && app.appId)
        if (/^[a-zA-Z0-9_./+-]+$/.test(fallback)) Quickshell.execDetached([fallback])
    }

    function activateApp(app) {
        if (!app) return
        if (app.running && app.toplevels && app.toplevels.length > 0) {
            windowActions.activate(app.toplevels[0], settingsStore.dockValues.minimizeMode)
            return
        }
        if (!app.pending) launchApp(app)
    }

    function focusWindowByAddress(win) {
        return windowActions.activate(win, "off")
    }

    function closeMenu() {
        menuOpen = false
        menuApp = null
        menuKey = ""
    }

    function openMenu(screen, app, x, bottom) {
        if (!app || !screen) return
        settingsOpen = false
        popupScreen = screen
        menuApp = app
        menuKey = app.canonicalId || app.appId
        menuX = x
        menuBottomMargin = bottom
        menuOpen = true
    }

    onEligibleScreensChanged: {
        if ((menuOpen || settingsOpen) && (!popupScreen || !eligibleScreens.includes(popupScreen))) {
            closeMenu()
            settingsOpen = false
            popupScreen = null
        }
    }

    function openSettings(screen) {
        closeMenu()
        popupScreen = screen
        settingsOpen = true
    }

    function launchWalker() {
        const command = settingsStore.dockValues.launcherCommand
        Quickshell.execDetached(command.length ? command : [Quickshell.env("HOME") + "/.local/bin/walker-themed"])
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
        onAppsChanged: {
            if (!root.menuOpen) return
            const next = dockApps.find(app => (app.canonicalId || app.appId) === root.menuKey)
            if (next) root.menuApp = next
            else root.closeMenu()
        }
    }

    Timer {
        interval: 750
        repeat: true
        running: settingsStore.smartHide
        onTriggered: Hyprland.refreshToplevels()
    }

    Variants {
        model: root.eligibleScreens
        delegate: DockWindow {
            id: panel
            required property var modelData
            screen: modelData
            settings: settingsStore
            apps: windowModel.dockApps
            visible: windowModel.ready
            popupOpen: root.popupScreen === screen && (root.menuOpen || root.settingsOpen)
            menuApp: root.popupScreen === screen ? root.menuApp : null
            onActivateApp: app => {
                if (app && app.running && app.toplevels.length > 1) panel.requestMenu(app)
                else root.activateApp(app)
            }
            onMenuRequested: (app, x, bottom) => root.openMenu(screen, app, x, bottom)
            onMenuCloseRequested: if (root.popupScreen === screen) root.closeMenu()
            onSettingsRequested: root.openSettings(screen)
            onReorderRequested: (fromKey, beforeKey) => pinnedApps.reorder(fromKey, beforeKey)
            onLauncherRequested: root.launchWalker()
        }
    }

    PanelWindow {
        visible: root.menuOpen && root.popupScreen !== null
        screen: root.popupScreen

        anchors {
            left: true
            bottom: true
        }

        margins {
            bottom: Math.round(root.menuBottomMargin)
            left: Math.max(0, Math.min(Math.round(root.menuX), root.popupScreen ? root.popupScreen.width - Math.ceil(dockMenu.implicitWidth) : 0))
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
                root.openSettings(root.popupScreen)
            }
            onCloseRequested: root.closeMenu()
            onFocusWindowRequested: win => {
                root.focusWindowByAddress(win)
                root.closeMenu()
            }
            onNewWindowRequested: app => {
                root.launchApp(app)
                root.closeMenu()
            }
        }
    }

    // ESC keybind via Hyprland (configured in hyprland.conf)

    PanelWindow {
        visible: root.settingsOpen && root.popupScreen !== null
        screen: root.popupScreen
        WlrLayershell.keyboardFocus: root.settingsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            bottom: true
            right: true
        }

        margins {
            bottom: 24
            right: 24
        }

        color: "transparent"
        implicitWidth: root.popupScreen ? Math.min(690, root.popupScreen.width - 48) : 690
        implicitHeight: root.popupScreen ? Math.min(690, root.popupScreen.height - 100) : 690
        exclusiveZone: 0

        SettingsPanel {
            anchors.fill: parent
            store: settingsStore
            pinsStore: pinnedApps
            onCloseRequested: root.settingsOpen = false
        }
    }
}
