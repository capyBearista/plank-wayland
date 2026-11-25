import Quickshell.Io
import Quickshell
import QtQuick
import "../apps.js" as DockApps
import "Config.js" as Config
import "AppIdentity.js" as Identity

Item {
    id: root

    property var apps: DockApps.items
    property var overrides: ({})
    property string writingText: ""
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/plank-wayland"
    property bool saving: false
    property string errorMessage: ""
    property string pendingText: ""

    signal changed()

    function contains(app) {
        const key = Identity.key(app, overrides)
        return key && apps.some(p => Identity.key(p, overrides) === key)
    }

    function reorder(fromKey, beforeKey) {
        const next = Identity.reorder(apps, fromKey, beforeKey, overrides)
        if (next.every((p, i) => p === apps[i])) return
        apps = next
        save()
        changed()
    }

    function save() {
        pendingText = JSON.stringify(apps, null, 4) + "\n"
        if (!saving) { saving = true; writingText = pendingText; file.setText(writingText) }
    }

    function pin(app) {
        if (!app || contains(app)) return
        const next = apps.slice()
        next.push({
            appId: app.appId,
            canonicalId: app.canonicalId,
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
        const normalized = Identity.normalize(appId)
        apps = apps.filter(app => Identity.key(app, overrides) !== normalized && Identity.normalize(app.appId) !== normalized)
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
        onLoadFailed: root.errorMessage = "Could not read pinned applications; using current pins."
        onFileChanged: if (!root.saving) reload()
        onSaved: {
            const latest = JSON.stringify(root.apps, null, 4) + "\n"
            root.saving = false
            if (latest !== root.writingText) root.save()
        }
        onSaveFailed: {
            root.saving = false
            root.errorMessage = "Could not save pins."
        }
    }
}
