import Quickshell.Io
import Quickshell
import QtQuick
import "../apps.js" as DockApps
import "Config.js" as Config

Item {
    id: root

    property var apps: DockApps.items
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/plank-wayland"
    property bool saving: false
    property string errorMessage: ""
    property string pendingText: ""

    signal changed()

    function normalizeId(id) {
        return String(id || "").toLowerCase().replace(/\.desktop$/, "")
    }

    function identityKeys(app) {
        if (!app) return []
        const keys = []
        const fields = [app.appId, app.desktopId, app.icon, app.name]
        const aliases = app.iconAliases || []
        for (let i = 0; i < fields.length; i++) {
            const key = normalizeId(fields[i])
            if (key && keys.indexOf(key) < 0) keys.push(key)
        }
        for (let i = 0; i < aliases.length; i++) {
            const key = normalizeId(aliases[i])
            if (key && keys.indexOf(key) < 0) keys.push(key)
        }
        return keys
    }

    function contains(app) {
        const keys = identityKeys(app)
        for (let i = 0; i < apps.length; i++) {
            const pinnedKeys = identityKeys(apps[i])
            for (let j = 0; j < keys.length; j++) {
                if (pinnedKeys.indexOf(keys[j]) >= 0) return true
            }
        }
        return false
    }

    function save() {
        pendingText = JSON.stringify(apps, null, 4) + "\n"
        if (!saving) { saving = true; file.setText(pendingText) }
    }

    function pin(app) {
        if (!app || contains(app)) return
        const next = apps.slice()
        next.push({
            appId: app.appId,
            desktopId: app.desktopId,
            name: app.name,
            icon: app.icon,
            iconAliases: app.iconAliases,
            fallback: app.fallback,
            command: app.command
        })
        apps = next
        save()
        changed()
    }

    function unpin(appId) {
        const normalized = normalizeId(appId)
        apps = apps.filter(app => normalizeId(app.appId || app.icon || app.name) !== normalized)
        save()
        changed()
    }

    FileView {
        id: file
        path: root.configDir + "/pinned-apps.json"
        preload: true
        watchChanges: true
        blockWrites: false
        atomicWrites: true
        printErrors: true
        onLoaded: {
            if (root.saving) return
            try {
                const value = JSON.parse(text())
                if (!Config.validPins(value)) throw Error("Invalid pinned applications")
                root.apps = value
                root.errorMessage = ""
                root.changed()
            } catch (e) { root.errorMessage = String(e) }
        }
        onFileChanged: if (!root.saving) reload()
        onSaved: {
            const latest = JSON.stringify(root.apps, null, 4) + "\n"
            root.saving = false
            if (latest !== text()) root.save()
        }
        onSaveFailed: {
            root.saving = false
            root.errorMessage = "Could not save pins."
        }
    }
}
