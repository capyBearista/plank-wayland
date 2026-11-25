import Quickshell.Io
import Quickshell
import QtQuick
import "../settings.js" as DockSettings
import "Config.js" as Config

Item {
    id: root

    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/plank-wayland"
    property var dockValues: Object.assign({}, DockSettings.dock)
    property var styleOverrides: ({})
    property string errorMessage: ""
    property string saveMessage: ""
    property bool saving: false
    property bool externalConflict: false
    property bool discardRequested: false
    property string savedText: ""
    property string pendingSave: ""
    property string styleName: DockSettings.styleName
    property string uiLanguage: DockSettings.uiLanguage || "zh-CN"
    readonly property int iconSize: dockValues.iconSize
    readonly property int zoomPercent: dockValues.zoomPercent
    readonly property bool zoomEnabled: dockValues.zoomEnabled
    readonly property bool followSystemIconTheme: dockValues.followSystemIconTheme
    property int iconThemeRevision: 0
    property string systemIconTheme: ""
    property bool iconThemeLoaded: false
    property var iconCache: ({})
    property var pendingIconRequests: ({})
    readonly property bool autoHide: dockValues.autoHide
    readonly property bool smartHide: dockValues.smartHide
    property string indicatorStyle: DockSettings.theme.indicatorStyle
    property int radiusAdjust: 0
    property int opacityAdjust: 0
    property var launcherDefaults: DockSettings.launcher || ({})
    property string launcherLayoutMode: launcherDefaults.layoutMode || "auto"
    property string launcherBackgroundStyle: launcherDefaults.backgroundStyle || "glass"
    property bool launcherShowLabels: launcherDefaults.showLabels !== false
    property bool launcherHoverMagnification: launcherDefaults.hoverMagnification === true
    property bool launcherPressFeedback: launcherDefaults.pressFeedback === true
    property real launcherIconScale: launcherDefaults.iconScale || 1
    property bool dirty: false
    ThemeManager { id: appearance }
    readonly property string activeMode: dockValues.themeMode === "system" ? appearance.mode : dockValues.themeMode
    readonly property string effectiveStyle: activeMode === "light" ? dockValues.lightStyle : (activeMode === "dark" ? dockValues.darkStyle : styleName)
    readonly property var theme: buildTheme(effectiveStyle, indicatorStyle)

    signal changed()

    Component.onCompleted: refreshSystemIconTheme(false)

    function styleDefaults(name) {
        const style = Object.assign({}, DockSettings.styles[name] || DockSettings.styles.macos, styleOverrides[name] || {})
        return style
    }

    function alphaHex(value) {
        const bounded = Math.max(0, Math.min(255, value))
        const text = bounded.toString(16)
        return text.length === 1 ? "0" + text : text
    }

    function adjustAlpha(color, delta) {
        if (typeof color !== "string" || color === "transparent" || color[0] !== "#") return color
        if (color.length === 7) color = "#ff" + color.slice(1)
        if (color.length !== 9) return color
        const alpha = parseInt(color.slice(1, 3), 16)
        return "#" + alphaHex(alpha + delta) + color.slice(3)
    }

    function iniValue(text, key) {
        const lines = String(text || "").split(/\r?\n/)
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            const parts = line.split("=")
            if (parts.length >= 2 && parts[0].trim() === key) return parts.slice(1).join("=").trim()
        }
        return ""
    }

    function kdeIconTheme(text) {
        const lines = String(text || "").split(/\r?\n/)
        let inIcons = false
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (line === "[Icons]") {
                inIcons = true
                continue
            }
            if (line[0] === "[") inIcons = false
            const parts = line.split("=")
            if (inIcons && parts.length >= 2 && parts[0].trim() === "Theme") return parts.slice(1).join("=").trim()
        }
        return ""
    }

    function detectSystemIconTheme() {
        return iniValue(gtk3Settings.text(), "gtk-icon-theme-name")
            || iniValue(gtk4Settings.text(), "gtk-icon-theme-name")
            || kdeIconTheme(kdeGlobals.text())
            || Quickshell.env("QS_ICON_THEME")
            || ""
    }

    function refreshSystemIconTheme(restartOnChange) {
        const next = detectSystemIconTheme()
        const changed = next !== systemIconTheme
        if (changed) {
            systemIconTheme = next
            iconCache = ({})
            pendingIconRequests = ({})
        }
        if (changed || !iconThemeLoaded) iconThemeRevision += 1
        iconThemeLoaded = true
    }

    function fallbackIconSource(icon, fallbackPath) {
        if (fallbackPath && String(fallbackPath).startsWith("/")) return "file://" + fallbackPath
        if (!icon) return ""
        const path = Quickshell.iconPath(icon, true)
        return path || "image://icon/" + icon
    }

    function iconNames(icon) {
        const result = []
        if (Array.isArray(icon)) {
            for (let i = 0; i < icon.length; i++) {
                const name = String(icon[i] || "")
                if (name && result.indexOf(name) < 0) result.push(name)
            }
        } else {
            const name = String(icon || "")
            if (name) result.push(name)
        }
        return result
    }

    function iconCacheKey(icon) {
        return systemIconTheme + "|" + icon
    }

    function requestIcon(icon) {
        const key = iconCacheKey(icon)
        if (pendingIconRequests[key]) return

        const next = ({})
        for (const existing in pendingIconRequests) next[existing] = pendingIconRequests[existing]
        next[key] = icon
        pendingIconRequests = next
        iconResolveTimer.restart()
    }

    function iconSource(icon, revision, fallbackPath) {
        const names = iconNames(icon)
        const fallbackName = names.length > 0 ? names[0] : ""
        if (fallbackName && fallbackName[0] === "/") return "file://" + fallbackName
        if (!followSystemIconTheme) return fallbackIconSource(fallbackName, fallbackPath)
        if (!systemIconTheme) return Array.isArray(icon) ? "" : fallbackIconSource(fallbackName, fallbackPath)

        let waitingForAlias = false
        for (let i = 0; i < names.length; i++) {
            const key = iconCacheKey(names[i])
            if (iconCache[key] === undefined) {
                waitingForAlias = waitingForAlias || names.length > 1
                Qt.callLater(requestIcon, names[i])
                continue
            }
            if (iconCache[key]) return "file://" + iconCache[key]
        }

        if (waitingForAlias) return ""
        return fallbackIconSource(fallbackName, fallbackPath)
    }

    function resolvePendingIcons() {
        if (iconResolver.running) {
            iconResolveTimer.restart()
            return
        }

        const requests = pendingIconRequests
        pendingIconRequests = ({})

        const icons = []
        for (const key in requests) icons.push(requests[key])
        if (icons.length === 0) return

        iconResolver.exec(["python3", Quickshell.shellPath("services/resolve-icons.py"), systemIconTheme].concat(icons))
    }

    function applyResolvedIcons(text) {
        const next = ({})
        for (const key in iconCache) next[key] = iconCache[key]

        const lines = String(text || "").split(/\r?\n/)
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            if (!line) continue
            const splitAt = line.indexOf("\t")
            if (splitAt < 0) continue
            const icon = line.slice(0, splitAt)
            next[iconCacheKey(icon)] = line.slice(splitAt + 1)
        }

        iconCache = next
        iconThemeRevision += 1
    }

    function buildTheme(name, indicator) {
        const base = JSON.parse(JSON.stringify(styleDefaults(name)))
        base.indicatorStyle = indicator
        base.radius = Math.max(0, base.radius + radiusAdjust)
        const alphaFields = ["backgroundColor", "innerBackgroundColor", "shadowColor", "runningItemColor", "barGradientStart", "barGradientEnd", "barHighlightColor", "barBottomShadeColor", "barShadowColor"]
        for (let i = 0; i < alphaFields.length; i++) {
            const field = alphaFields[i]
            base[field] = adjustAlpha(base[field], opacityAdjust)
        }
        return base
    }

    function markDirty() {
        saveMessage = ""
        dirty = true
        changed()
    }

    function loadSettings(force) {
        const text = file.text()
        if (!text) { errorMessage = "Settings file is empty or unavailable; using last valid settings."; return }
        if (text === savedText && !force) return
        if ((dirty || saving) && !force) {
            if (text !== pendingSave) {
                externalConflict = true
                errorMessage = "Configuration changed on disk. Reload to discard unsaved edits."
            }
            return
        }
        try {
            const value = JSON.parse(text)
            if (!value || value.schemaVersion !== 1 || !value.dock || typeof value.dock !== "object" || Array.isArray(value.dock)) throw Error("Invalid settings schema")
            const d = Config.validateDock(DockSettings.dock, value.dock)
            if (!DockSettings.styles[d.lightStyle]) d.lightStyle = DockSettings.dock.lightStyle
            if (!DockSettings.styles[d.darkStyle]) d.darkStyle = DockSettings.dock.darkStyle
            dockValues = d
            styleOverrides = Config.validateStyles(DockSettings.styles, value.styleOverrides)
            styleName = DockSettings.styles[value.styleName] ? value.styleName : DockSettings.styleName
            uiLanguage = typeof value.uiLanguage === "string" ? value.uiLanguage : (DockSettings.uiLanguage || "en")
            indicatorStyle = ["line","dot","legacy"].includes(value.indicatorStyle) ? value.indicatorStyle : (styleDefaults(styleName).indicatorStyle || "line")
            radiusAdjust = 0
            opacityAdjust = 0
            savedText = text
            saveMessage = force ? "Saved settings restored." : ""
            dirty = false
            externalConflict = false
            errorMessage = ""
            refreshSystemIconTheme(false)
            changed()
        } catch (e) { errorMessage = "Settings not applied: " + e }
    }

    function reloadSettings() {
        if (saving) return
        discardRequested = true
        file.reload()
    }

    function setOption(key, value) {
        if (saving || !(key in DockSettings.dock)) return
        const next = Config.withOption(DockSettings.dock, dockValues, key, value)
        if (JSON.stringify(next) === JSON.stringify(dockValues)) return
        dockValues = next
        if (key === "followSystemIconTheme") refreshSystemIconTheme(false)
        markDirty()
    }

    function save() {
        if (saving || externalConflict) return
        const dock = Object.assign({}, dockValues)
        const overrides = Object.assign({}, styleOverrides)
        if (radiusAdjust || opacityAdjust) overrides[effectiveStyle] = buildTheme(effectiveStyle, indicatorStyle)
        pendingSave = JSON.stringify({schemaVersion: 1, dock: dock, styleName: styleName, uiLanguage: uiLanguage, indicatorStyle: indicatorStyle, styleOverrides: overrides}, null, 4) + "\n"
        saving = true
        file.setText(pendingSave)
    }

    readonly property var availableStyles: Object.keys(DockSettings.styles)
    readonly property color glassColor: theme.backgroundColor || "#22ffffff"
    readonly property int glassOpacityPercent: Math.round(glassColor.a * 100)

    function setStyle(name) {
        if (saving || !DockSettings.styles[name]) return
        styleName = name
        setOption("themeMode", "manual")
        markDirty()
    }

    function setIndicator(value) {
        if (saving || !["line","dot","legacy"].includes(value) || value === indicatorStyle) return
        indicatorStyle = value
        markDirty()
    }

    function setStyleOverride(key, value) {
        if (saving) return
        const next = Object.assign({}, styleOverrides)
        next[effectiveStyle] = Object.assign({}, styleDefaults(effectiveStyle))
        next[effectiveStyle][key] = value
        styleOverrides = Config.validateStyles(DockSettings.styles, next)
        markDirty()
    }

    function setGlassOpacity(percent) {
        if (saving) return
        const next = Object.assign({}, styleOverrides)
        const base = Object.assign({}, styleDefaults(effectiveStyle))
        const delta = Math.round(Math.max(0, Math.min(100, percent)) * 255 / 100) - Math.round(glassColor.a * 255)
        for (const key of ["backgroundColor", "barGradientStart", "barGradientEnd"]) {
            if (typeof base[key] === "string") base[key] = adjustAlpha(base[key], delta)
        }
        next[effectiveStyle] = base
        styleOverrides = Config.validateStyles(DockSettings.styles, next)
        markDirty()
    }

    function resetAllSettings() {
        if (saving) return
        dockValues = Config.validateDock(DockSettings.dock, {})
        styleName = DockSettings.styleName
        uiLanguage = DockSettings.uiLanguage || "en"
        indicatorStyle = DockSettings.theme.indicatorStyle
        styleOverrides = ({})
        radiusAdjust = 0
        opacityAdjust = 0
        refreshSystemIconTheme(false)
        markDirty()
    }

    function resetAppearance() {
        if (saving) return
        const next = Object.assign({}, styleOverrides)
        delete next[effectiveStyle]
        styleOverrides = next
        radiusAdjust = 0
        opacityAdjust = 0
        markDirty()
    }

    function setIconSize(value) { setOption("iconSize", value) }

    function setZoomPercent(value) { setOption("zoomPercent", value) }

    function toggleZoom() { setOption("zoomEnabled", !zoomEnabled) }

    function toggleFollowSystemIconTheme() { setOption("followSystemIconTheme", !followSystemIconTheme) }

    function toggleAutoHide() { setOption("autoHide", !autoHide) }

    function toggleSmartHide() { setOption("smartHide", !smartHide) }

    function cycleIndicator() {
        const styles = ["dot", "line", "legacy"]
        const index = styles.indexOf(indicatorStyle)
        setIndicator(styles[(index + 1) % styles.length])
    }

    function adjustRadius(delta) {
        radiusAdjust = Math.max(-16, Math.min(24, radiusAdjust + delta))
        markDirty()
    }

    function adjustOpacity(delta) {
        opacityAdjust = Math.max(-96, Math.min(96, opacityAdjust + delta))
        markDirty()
    }

    function setLauncherLayoutMode(value) {
        launcherLayoutMode = ["auto", "compact", "fullscreen"].indexOf(value) >= 0 ? value : "auto"
        markDirty()
    }

    function setLauncherBackgroundStyle(value) {
        launcherBackgroundStyle = ["glass", "blue", "dark"].indexOf(value) >= 0 ? value : "glass"
        markDirty()
    }

    function setLauncherIconScale(value) {
        launcherIconScale = Math.max(0.75, Math.min(1.35, value))
        markDirty()
    }

    function toggleLauncherShowLabels() {
        launcherShowLabels = !launcherShowLabels
        markDirty()
    }

    function toggleLauncherHoverMagnification() {
        launcherHoverMagnification = !launcherHoverMagnification
        markDirty()
    }

    function toggleLauncherPressFeedback() {
        launcherPressFeedback = !launcherPressFeedback
        markDirty()
    }

    FileView {
        id: file
        path: root.configDir + "/settings.json"
        preload: true
        watchChanges: true
        blockWrites: false
        atomicWrites: true
        printErrors: true
        onLoaded: {
            root.loadSettings(root.discardRequested)
            root.discardRequested = false
        }
        onLoadFailed: {
            root.discardRequested = false
            root.errorMessage = "Settings file could not be read; using last valid settings."
        }
        onFileChanged: if (!root.saving) reload()
        onSaved: {
            root.savedText = root.pendingSave
            try {
                const written = JSON.parse(root.pendingSave)
                root.styleOverrides = written.styleOverrides
                root.dockValues = Config.validateDock(DockSettings.dock, written.dock)
            } catch (e) {}
            root.saving = false
            root.dirty = false
            root.radiusAdjust = 0
            root.opacityAdjust = 0
            root.errorMessage = ""
            root.saveMessage = "Settings saved."
            reload()
        }
        onSaveFailed: {
            root.saving = false
            root.errorMessage = "Could not save settings."
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.followSystemIconTheme
        onTriggered: {
            gtk3Settings.reload()
            gtk4Settings.reload()
            kdeGlobals.reload()
        }
    }

    Timer {
        id: iconResolveTimer
        interval: 35
        repeat: false
        onTriggered: root.resolvePendingIcons()
    }

    Process {
        id: iconResolver
        stdout: StdioCollector { id: iconResolverStdout }
        onExited: root.applyResolvedIcons(iconResolverStdout.text)
    }

    FileView {
        id: gtk3Settings
        path: (Quickshell.env("HOME") || "") + "/.config/gtk-3.0/settings.ini"
        preload: true
        watchChanges: root.followSystemIconTheme
        printErrors: false
        onLoaded: root.refreshSystemIconTheme(false)
        onTextChanged: root.refreshSystemIconTheme(true)
        onFileChanged: reload()
    }

    FileView {
        id: gtk4Settings
        path: (Quickshell.env("HOME") || "") + "/.config/gtk-4.0/settings.ini"
        preload: true
        watchChanges: root.followSystemIconTheme
        printErrors: false
        onLoaded: root.refreshSystemIconTheme(false)
        onTextChanged: root.refreshSystemIconTheme(true)
        onFileChanged: reload()
    }

    FileView {
        id: kdeGlobals
        path: (Quickshell.env("HOME") || "") + "/.config/kdeglobals"
        preload: true
        watchChanges: root.followSystemIconTheme
        printErrors: false
        onLoaded: root.refreshSystemIconTheme(false)
        onTextChanged: root.refreshSystemIconTheme(true)
        onFileChanged: reload()
    }
}
