import QtQuick
import "../settings.js" as DockSettings

Item {
    id: root

    property var apps: []
    property var settings: null
    readonly property var theme: settings ? settings.theme : DockSettings.theme
    readonly property color barGradientStart: theme.barGradientStart || theme.backgroundColor || "#44ffffff"
    readonly property color barGradientEnd: theme.barGradientEnd || theme.backgroundColor || "#44ffffff"
    property real dockMouseX: -10000
    property bool dockHovered: false
    property real zoomProgress: 0
    property bool autoHide: settings ? settings.autoHide : (root.settings ? root.settings.dockValues.autoHide : DockSettings.dock.autoHide)
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

    readonly property real baseItemSize: settings ? settings.iconSize : (root.settings ? root.settings.dockValues.iconSize : DockSettings.dock.iconSize)
    readonly property bool zoomEnabled: settings ? settings.zoomEnabled : (root.settings ? root.settings.dockValues.zoomEnabled : DockSettings.dock.zoomEnabled)
    readonly property real zoomPercent: zoomEnabled ? (settings ? settings.zoomPercent : (root.settings ? root.settings.dockValues.zoomPercent : DockSettings.dock.zoomPercent)) / 100 : 1
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
    readonly property real trackerBottom: layerHeight - bottomPadding + 4
    readonly property real trackerTop: layerHeight - bottomPadding - (dockHovered ? maxItemSize : baseItemSize) - 8
    readonly property real trackerHeight: Math.max(1, trackerBottom - trackerTop)

    signal activate(var app)
    signal openMenu(var app)
    signal closeMenuRequested()
    signal launch()

    function appKey(app) {
        return String((app && (app.canonicalId || app.desktopId || app.appId)) || "").toLowerCase().replace(/\.desktop$/, "")
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

    function updatePointer(mouseX) {
        hoverLeaveTimer.stop()
        if (Math.abs(dockMouseX - mouseX) > 0.5) dockMouseX = mouseX
        if (!dockHovered) dockHovered = true
    }

    function schedulePointerLeave() {
        hoverLeaveTimer.restart()
    }

    implicitWidth: dockMaxWidth
    implicitHeight: baseItemSize + topPadding + bottomPadding
    y: parent.height - height - bottomGap
        + (hidden ? Math.max((root.settings ? root.settings.dockValues.hideOffset : DockSettings.dock.hideOffset), barHeight + bottomGap + 2) : 0)

    // The transparent layer stays larger so magnified icons have room above the bar.

    onAppsChanged: if (dragging && !apps.some(app => appKey(app) === draggingKey && app.pinned)) draggingKey = ""

    onDockHoveredChanged: zoomProgress = dockHovered ? 1 : 0

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

    Timer {
        id: hoverLeaveTimer
        interval: 70
        repeat: false
        onTriggered: {
            root.dockHovered = false
            root.dockMouseX = -10000
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

        MouseArea {
            anchors.left: parent.left
            anchors.right: parent.right
            y: root.trackerTop
            height: root.trackerHeight
            z: -1
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onPositionChanged: function(mouse) { root.updatePointer(mouse.x) }
            onEntered: root.updatePointer(mouseX)
            onExited: root.schedulePointerLeave()
        }


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
            model: [null].concat(root.apps)

            Loader {
                required property var modelData
                required property int index

                sourceComponent: index === 0 ? launcherComp : itemComp

                property var app: modelData
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
                onPointerMoved: dockX => root.updatePointer(dockX)
                onPointerExited: root.schedulePointerLeave()
                onLaunchRequested: root.launch()
            }
        }

        Component {
            id: itemComp
            DockItem {
                app: modelData
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
                onPointerMoved: dockX => root.updatePointer(dockX)
                onPointerExited: root.schedulePointerLeave()
            }
        }
    }
}
