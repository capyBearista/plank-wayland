import QtQuick
import "."

DockItem {
    id: root

    // Custom app structure for the launcher
    app: {
        "name": "Applications",
        "appId": "launchpad",
        "icon": root.settings ? root.settings.dockValues.launcherIcon : "",
        "launcherIcon": true,
        "running": false,
        "pending": false,
        "active": false,
        "urgent": false,
        "toplevels": [],
        "pinned": false,
        "fallback": ""
    }

    signal launchRequested()

    function trigger(button) {
        if (button === Qt.RightButton) return

        root.hovered = false
        root.pointerExited()
        root.launchRequested()
    }
}
