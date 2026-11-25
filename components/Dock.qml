import QtQuick
import "../settings.js" as DockSettings

Item {
    id: root

    property var apps: []
    property var itemKeys: [""]
    property var settings: null
    readonly property var theme: settings ? settings.theme : DockSettings.theme
    readonly property color barGradientStart: theme.barGradientStart || theme.backgroundColor || "#44ffffff"
    readonly property color barGradientEnd: theme.barGradientEnd || theme.backgroundColor || "#44ffffff"
    // The stationary PanelWindow input region owns hover, not animated icons.
    property real pointerX: -10000
    property bool pointerInside: false
    readonly property bool dockHovered: pointerInside && !hidden && !menuOpen && !dragging
    readonly property real dockMouseX: dockHovered ? pointerX : -10000
    property real zoomProgress: dockHovered && zoomEnabled ? 1 : 0
    property bool autoHide: settings ? settings.dockValues.autoHide : DockSettings.dock.autoHide
    property bool smartHideEnabled: false
    property bool isOverlapped: false
    property bool menuOpen: false
    property bool attentionHold: false
    signal settingsRequested()
    property string draggingKey: ""
    property real dragX: 0
    readonly property bool dragging: draggingKey !== ""
    signal reorderRequested(string fromKey, string beforeKey)
    // Keep the screen-edge trigger stationary while the visible dock slides.
    readonly property int bottomGap: settings ? settings.dockValues.bottomGap : DockSettings.dock.bottomGap
    readonly property int edgeTriggerHeight: settings ? settings.dockValues.edgeTriggerHeight : DockSettings.dock.edgeTriggerHeight
    property bool surfaceHovered: false
    property bool revealed: false
    property bool hidden: (autoHide || (smartHideEnabled && isOverlapped)) && !revealed && !menuOpen && !dragging && !attentionHold

    onSurfaceHoveredChanged: {
        if (surfaceHovered) {
            hideDelay.stop()
            revealed = true
        } else {
            hideDelay.restart()
        }
    }

    Timer {
        id: hideDelay
        interval: root.settings ? root.settings.dockValues.hideDelayMs : DockSettings.dock.hideDelayMs
        repeat: false
        onTriggered: if (!root.surfaceHovered) root.revealed = false
    }
    property var menuApp: null
    readonly property real menuX: menuApp ? Math.max(0, Math.min(dockMaxWidth - 260, itemCenterForApp(menuApp) - 130)) : 0
    readonly property real menuBottomMargin: barHeight + bottomGap + 16

    readonly property real baseItemSize: settings ? settings.dockValues.iconSize : DockSettings.dock.iconSize
    readonly property bool zoomEnabled: settings ? settings.dockValues.zoomEnabled : DockSettings.dock.zoomEnabled
    readonly property real zoomPercent: zoomEnabled ? (settings ? settings.dockValues.zoomPercent : DockSettings.dock.zoomPercent) / 100 : 1
    readonly property real maxItemSize: baseItemSize * zoomPercent
    readonly property real dockSpacing: (root.settings ? root.settings.dockValues.itemPadding : DockSettings.dock.itemPadding) * baseItemSize / 10
    readonly property real dockPadding: Math.max(0, (root.settings ? root.settings.dockValues.horizPadding : DockSettings.dock.horizPadding) * baseItemSize / 10) + 28
    readonly property real topPadding: (root.settings ? root.settings.dockValues.topPadding : DockSettings.dock.topPadding) * baseItemSize / 10
    readonly property real bottomPadding: (root.settings ? root.settings.dockValues.bottomPadding : DockSettings.dock.bottomPadding) * baseItemSize / 10
    readonly property int totalItemCount: apps.length + 1
    readonly property real dockItemsWidth: Math.max(0, totalItemCount * baseItemSize + (totalItemCount - 1) * dockSpacing)
    readonly property real dockMaxWidth: Math.ceil(dockItemsWidth + dockPadding * 2 + (maxItemSize - baseItemSize) * 2)
    readonly property real layerHeight: Math.ceil(baseItemSize + Math.max(0, -topPadding) + bottomPadding + (maxItemSize - baseItemSize) + 40)
    readonly property real barHorizontalPadding: Math.max(6, (root.settings ? root.settings.dockValues.horizPadding : DockSettings.dock.horizPadding) * baseItemSize / 10 + 6)
    readonly property real barTopPadding: Math.max(5, topPadding > 0 ? topPadding : 5)
    readonly property real barBottomPadding: Math.max(5, bottomPadding)
    readonly property real barWidth: Math.ceil(dockItemsWidth + barHorizontalPadding * 2)
    readonly property real barHeight: Math.ceil(baseItemSize + barTopPadding + barBottomPadding)
    readonly property real barRadius: Math.min(theme.radius || 16, barHeight / 2)

    signal activate(var app)
    signal openMenu(var app)
    signal closeMenuRequested()
    signal launch()

    function appKey(app) {
        return String((app && (app.canonicalId || app.desktopId || app.appId)) || "").toLowerCase().replace(/\.desktop$/, "")
    }

    function appForKey(key) {
        return apps.find(app => appKey(app) === key) || {appId: key, name: key, icon: "", fallback: "?", running: false, pending: false, active: false, urgent: false, pinned: false, toplevels: []}
    }

    function syncItemKeys() {
        const next = [""].concat(apps.map(appKey))
        if (JSON.stringify(next) !== JSON.stringify(itemKeys)) {
            if (dragging) draggingKey = ""
            itemKeys = next
        }
    }

    function itemCenterForApp(app) {
        const key = appKey(app)
        const baseStep = baseItemSize + dockSpacing
        const baseStart = (dockMaxWidth - dockItemsWidth) / 2
        for (let i = 0; i < apps.length; i++) {
            if (appKey(apps[i]) === key) return baseStart + (i + 1) * baseStep + baseItemSize / 2
        }
        return dockMaxWidth / 2
    }

    function beginDrag(app, x) {
        if (!app.pinned || !appKey(app)) return
        draggingKey = appKey(app)
        dragX = x
        closeMenuRequested()
    }

    function finishDrag(x, accepted) {
        if (!dragging) return
        const from = draggingKey
        draggingKey = ""
        if (!accepted || x < 0 || x > width) return
        const pins = apps.filter(app => app.pinned && appKey(app) !== from)
        const start = (width - dockItemsWidth) / 2
        const step = baseItemSize + dockSpacing
        let before = ""
        for (const pin of pins) {
            const index = apps.findIndex(app => appKey(app) === appKey(pin))
            if (x < start + (index + 1) * step + baseItemSize / 2) { before = appKey(pin); break }
        }
        reorderRequested(from, before)
    }

    implicitWidth: dockMaxWidth
    implicitHeight: baseItemSize + topPadding + bottomPadding
    y: parent.height - height - bottomGap
        + (hidden ? Math.max((root.settings ? root.settings.dockValues.hideOffset : DockSettings.dock.hideOffset), barHeight + bottomGap + 2) : 0)

    // The transparent layer stays larger so magnified icons have room above the bar.

    onAppsChanged: syncItemKeys()
    Component.onCompleted: syncItemKeys()

    Behavior on zoomProgress {
        NumberAnimation {
            duration: Math.max(0, (root.settings ? root.settings.dockValues.zoomDuration : DockSettings.dock.zoomDuration))
            easing.type: Easing.OutCubic
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: Math.max(0, (root.settings ? root.settings.dockValues.slideTime : DockSettings.dock.slideTime))
            easing.type: Easing.OutCubic
        }
    }

    // Keep the visible dock frame tight; layerHeight is only the transparent zoom hit area.
    Item {
        anchors.horizontalCenter: itemsLayer.horizontalCenter
        anchors.bottom: itemsLayer.bottom
        width: root.barWidth
        height: root.barHeight
        visible: root.totalItemCount > 0

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: root.settingsRequested()
        }
        Rectangle {
            anchors.fill: parent
            radius: root.barRadius
            border.color: root.theme.borderColor || "#22ffffff"
            border.width: root.theme.borderWidth !== undefined ? root.theme.borderWidth : 0.5
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0; color: root.barGradientStart }
                GradientStop { position: 1; color: root.barGradientEnd }
            }
        }
    }

    Item {
        id: itemsLayer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.layerHeight

        Rectangle {
            visible: root.dragging
            x: Math.max(0, Math.min(root.width - 2, root.dragX))
            y: root.layerHeight - root.baseItemSize - root.bottomPadding
            width: 2
            height: root.baseItemSize
            radius: 1
            color: root.theme.indicatorColor || "white"
            z: 20
        }

        Repeater {
            model: root.itemKeys

            Loader {
                required property string modelData
                required property int index

                sourceComponent: index === 0 ? launcherComp : itemComp

                property var entry: root.appForKey(modelData)
                property int itemIndex: index
            }
        }

        Component {
            id: launcherComp
            LauncherItem {
                settings: root.settings
                menuOpen: root.menuOpen
                dockMouseX: root.dockMouseX
                zoomProgress: root.zoomProgress
                dockWidth: root.width
                itemCount: root.apps.length + 1
                baseItemSize: root.baseItemSize
                zoomPercent: root.zoomPercent
                zoomIconSize: root.zoomEnabled ? root.maxItemSize : root.baseItemSize
                dockSpacing: root.dockSpacing
                dockItemsWidth: root.dockItemsWidth
                bottomPadding: root.bottomPadding
                layerHeight: root.layerHeight
                onLaunchRequested: root.launch()
            }
        }

        Component {
            id: itemComp
            DockItem {
                app: entry
                settings: root.settings
                itemIndex: index
                dockMouseX: root.dockMouseX
                zoomProgress: root.zoomProgress
                dockWidth: root.width
                itemCount: root.apps.length + 1
                baseItemSize: root.baseItemSize
                zoomPercent: root.zoomPercent
                zoomIconSize: root.zoomEnabled ? root.maxItemSize : root.baseItemSize
                dockSpacing: root.dockSpacing
                dockItemsWidth: root.dockItemsWidth
                bottomPadding: root.bottomPadding
                layerHeight: root.layerHeight
                menuOpen: root.menuOpen || root.dragging
                dragEnabled: root.settings && root.settings.dockValues.dragReorder && app.pinned
                dragging: root.draggingKey === root.appKey(app)
                onDragStarted: (app, x) => root.beginDrag(app, x)
                onDragMoved: x => root.dragX = x
                onDragFinished: (x, accepted) => root.finishDrag(x, accepted)
                onActivate: app => root.activate(app)
                onOpenMenu: app => root.openMenu(app)
                onCloseMenuRequested: root.closeMenuRequested()
            }
        }
    }
}
