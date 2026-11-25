import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as C
import "../services/AppIdentity.js" as Identity

C.Pane {
    id: root
    required property var store
    required property var pinsStore
    signal closeRequested()
    property string section: "Appearance"
    property string fieldError: ""
    property bool cancelPending: false
    readonly property var options: store.dockValues
    readonly property var theme: store.theme
    readonly property color foreground: theme.textColor || "white"
    readonly property bool light: foreground.r + foreground.g + foreground.b < 1.5
    readonly property color panel: light ? "#f5f6f9" : "#20242c"
    readonly property color surface: light ? "#e7eaf0" : "#2d333e"
    readonly property color muted: light ? "#596372" : "#aab4c4"
    readonly property color accent: light ? "#2165ce" : "#79b6ff"
    readonly property var tabs: ["Appearance", "Behavior", "Visibility", "Applications", "Displays", "Advanced"]
    padding: 16
    palette.window: panel
    palette.windowText: foreground
    palette.base: surface
    palette.text: foreground
    palette.button: surface
    palette.buttonText: foreground
    palette.highlight: accent
    palette.highlightedText: light ? "#ffffff" : "#121821"
    background: Rectangle {
        color: root.panel
        radius: 18
        border.color: root.theme.menuBorderColor || "#8899aabb"
        border.width: 1
    }
    function selectSection(name) {
        forceActiveFocus()
        section = name
        scroll.contentY = 0
    }
    function cancelAndClose() {
        forceActiveFocus()
        fieldError = ""
        if (!store.dirty && !store.externalConflict) {
            closeRequested()
            return
        }
        cancelPending = true
        store.reloadSettings()
    }
    function save() {
        forceActiveFocus()
        if (!fieldError && !store.externalConflict) store.save()
    }
    function pinKey(pin) { return Identity.key(pin, options.identityOverrides) }
    Connections {
        target: root.store
        function onDirtyChanged() {
            if (root.cancelPending && !root.store.dirty) {
                root.cancelPending = false
                root.closeRequested()
            }
        }
        function onErrorMessageChanged() {
            if (root.cancelPending && root.store.errorMessage) root.cancelPending = false
        }
    }
    Keys.onEscapePressed: if (!store.saving) cancelAndClose()

    component Heading: Text {
        color: root.foreground
        font.pixelSize: 17
        font.weight: Font.DemiBold
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
    component Hint: Text {
        color: root.muted
        font.pixelSize: 12
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
    component NumberSetting: ColumnLayout {
        id: n
        required property string labelText
        required property real currentValue
        required property real minimum
        required property real maximum
        property real increment: 1
        property string units: ""
        signal edited(real value)
        Layout.fillWidth: true
        spacing: 4
        RowLayout {
            Layout.fillWidth: true
            Text { text: n.labelText; color: root.foreground; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Text { text: Math.round(n.currentValue) + n.units; color: root.muted; font.pixelSize: 12 }
        }
        RowLayout {
            Layout.fillWidth: true
            C.Slider {
                Layout.fillWidth: true
                from: n.minimum
                to: n.maximum
                stepSize: n.increment
                snapMode: C.Slider.SnapAlways
                value: n.currentValue
                onMoved: n.edited(Math.round(value))
            }
            C.SpinBox {
                Layout.preferredWidth: 106
                from: Math.round(n.minimum)
                to: Math.round(n.maximum)
                stepSize: Math.max(1, Math.round(n.increment))
                value: Math.round(n.currentValue)
                editable: true
                onValueModified: n.edited(value)
            }
        }
    }
    component ToggleSetting: C.Switch { Layout.fillWidth: true }
    component ChoiceSetting: ColumnLayout {
        id: choice
        required property string labelText
        required property var values
        required property string currentValue
        signal edited(string value)
        Layout.fillWidth: true
        spacing: 4
        Text { text: choice.labelText; color: root.foreground; Layout.fillWidth: true }
        C.ComboBox {
            Layout.fillWidth: true
            model: choice.values
            currentIndex: choice.values.indexOf(choice.currentValue)
            onActivated: choice.edited(currentText)
        }
    }
    component TextSetting: ColumnLayout {
        id: field
        required property string labelText
        required property string currentValue
        property string placeholder: ""
        signal edited(string value)
        Layout.fillWidth: true
        spacing: 4
        Text { text: field.labelText; color: root.foreground; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        C.TextField {
            id: editor
            Layout.fillWidth: true
            placeholderText: field.placeholder
            selectByMouse: true
            text: field.currentValue
            onEditingFinished: if (text !== field.currentValue) field.edited(text)
            Connections {
                target: field
                function onCurrentValueChanged() {
                    if (!editor.activeFocus) editor.text = field.currentValue
                }
            }
        }
    }
    contentItem: ColumnLayout {
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Taskbar settings"; color: root.foreground; font.pixelSize: 21; font.weight: Font.DemiBold; Layout.fillWidth: true }
            C.Button { text: "Close"; enabled: !root.store.saving; onClicked: root.cancelAndClose() }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.surface }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16
            ColumnLayout {
                Layout.preferredWidth: 124
                Layout.alignment: Qt.AlignTop
                spacing: 5
                Repeater {
                    model: root.tabs
                    delegate: C.Button {
                        required property string modelData
                        Layout.fillWidth: true
                        text: modelData
                        checkable: true
                        checked: root.section === modelData
                        onClicked: root.selectSection(modelData)
                    }
                }
            }
            Flickable {
                id: scroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: settingsContent.implicitHeight + 8
                boundsBehavior: Flickable.StopAtBounds
                C.ScrollBar.vertical: C.ScrollBar { policy: C.ScrollBar.AsNeeded }
                ColumnLayout {
                    id: settingsContent
                    width: Math.max(0, scroll.width - 14)
                    spacing: 12
                    enabled: !root.store.saving
                    ColumnLayout {
                        visible: root.section === "Appearance"
                        Layout.fillWidth: true
                        spacing: 12
                        Heading { text: "Appearance" }
                        Hint { text: "Changes preview on the actual dock. Save to keep them." }
                        ChoiceSetting { labelText: "Theme mode"; values: ["system","light","dark","manual"]; currentValue: root.options.themeMode; onEdited: value => root.store.setOption("themeMode", value) }
                        ChoiceSetting { visible: root.options.themeMode !== "manual"; labelText: "Light preset"; values: root.store.availableStyles; currentValue: root.options.lightStyle; onEdited: value => root.store.setOption("lightStyle", value) }
                        ChoiceSetting { visible: root.options.themeMode !== "manual"; labelText: "Dark preset"; values: root.store.availableStyles; currentValue: root.options.darkStyle; onEdited: value => root.store.setOption("darkStyle", value) }
                        ChoiceSetting { visible: root.options.themeMode === "manual"; labelText: "Manual preset"; values: root.store.availableStyles; currentValue: root.store.styleName; onEdited: value => root.store.setStyle(value) }
                        Hint { text: "Editing appearance for: " + root.store.effectiveStyle }
                        NumberSetting { labelText: "Icon size"; currentValue: root.options.iconSize; minimum: 32; maximum: 96; increment: 4; units: " px"; onEdited: value => root.store.setOption("iconSize", value) }
                        NumberSetting { labelText: "Icon spacing"; currentValue: root.options.itemPadding * root.options.iconSize / 10; minimum: 0; maximum: root.options.iconSize * 2; units: " px"; onEdited: value => root.store.setOption("itemPadding", value * 10 / root.options.iconSize) }
                        NumberSetting { labelText: "Glass opacity"; currentValue: root.store.glassOpacityPercent; minimum: 0; maximum: 100; units: "%"; onEdited: value => root.store.setGlassOpacity(value) }
                        NumberSetting { labelText: "Corner radius"; currentValue: root.theme.radius || 0; minimum: 0; maximum: 64; units: " px"; onEdited: value => root.store.setStyleOverride("radius", value) }
                        C.Button { text: "Reset current preset appearance"; Layout.fillWidth: true; onClicked: root.store.resetAppearance() }
                        ToggleSetting { text: "Follow system icon theme"; checked: root.options.followSystemIconTheme; onToggled: root.store.setOption("followSystemIconTheme", checked) }
                        Hint { text: "Detected icon theme: " + (root.store.systemIconTheme || "default") }
                        ToggleSetting { text: "Hover magnification"; checked: root.options.zoomEnabled; onToggled: root.store.setOption("zoomEnabled", checked) }
                        NumberSetting { labelText: "Magnification"; currentValue: root.options.zoomPercent; minimum: 100; maximum: 300; increment: 10; units: "%"; enabled: root.options.zoomEnabled; onEdited: value => root.store.setOption("zoomPercent", value) }
                        ChoiceSetting { labelText: "Running indicator"; values: ["line","dot","legacy"]; currentValue: root.store.indicatorStyle; onEdited: value => root.store.setIndicator(value) }
                        NumberSetting { labelText: "Indicator size"; currentValue: root.options.indicatorSize; minimum: 1; maximum: 16; units: " px"; onEdited: value => root.store.setOption("indicatorSize", value) }
                    }
                    ColumnLayout {
                        visible: root.section === "Behavior"
                        Layout.fillWidth: true
                        spacing: 12
                        Heading { text: "Window behavior" }
                        ChoiceSetting { labelText: "Click to minimize"; values: ["off","native","workspace"]; currentValue: root.options.minimizeMode; onEdited: value => root.store.setOption("minimizeMode", value) }
                        Hint { text: "Workspace mode minimizes a single window in the currently focused numeric workspace, focuses windows elsewhere, and restores hidden windows. Native support depends on the compositor." }
                        ToggleSetting { text: "Drag pinned icons to reorder"; checked: root.options.dragReorder; onToggled: root.store.setOption("dragReorder", checked) }
                        ToggleSetting { text: "Launch feedback"; checked: root.options.launchFeedback; onToggled: root.store.setOption("launchFeedback", checked) }
                        NumberSetting { labelText: "Launch timeout"; currentValue: root.options.launchTimeoutMs; minimum: 500; maximum: 30000; increment: 500; units: " ms"; enabled: root.options.launchFeedback; onEdited: value => root.store.setOption("launchTimeoutMs", value) }
                        NumberSetting { labelText: "Grouped window hover delay"; currentValue: root.options.hoverMenuDelayMs; minimum: 0; maximum: 3000; increment: 50; units: " ms"; onEdited: value => root.store.setOption("hoverMenuDelayMs", value) }
                        ToggleSetting { text: "Reveal dock for attention requests"; checked: root.options.attentionReveal; onToggled: root.store.setOption("attentionReveal", checked) }
                        NumberSetting { labelText: "Attention reveal duration"; currentValue: root.options.attentionRevealMs; minimum: 0; maximum: 30000; increment: 500; units: " ms"; enabled: root.options.attentionReveal; onEdited: value => root.store.setOption("attentionRevealMs", value) }
                        ToggleSetting { text: "Reveal over fullscreen"; checked: root.options.attentionInFullscreen; enabled: root.options.attentionReveal; onToggled: root.store.setOption("attentionInFullscreen", checked) }
                    }
                    ColumnLayout {
                        visible: root.section === "Visibility"
                        Layout.fillWidth: true
                        spacing: 12
                        Heading { text: "Visibility" }
                        ToggleSetting { text: "Automatically hide"; checked: root.options.autoHide; onToggled: root.store.setOption("autoHide", checked) }
                        ToggleSetting { text: "Smart hide when windows overlap"; checked: root.options.smartHide; onToggled: root.store.setOption("smartHide", checked) }
                        NumberSetting { labelText: "Hide delay"; currentValue: root.options.hideDelayMs; minimum: 0; maximum: 5000; increment: 50; units: " ms"; onEdited: value => root.store.setOption("hideDelayMs", value) }
                        NumberSetting { labelText: "Bottom gap"; currentValue: root.options.bottomGap; minimum: 0; maximum: 80; units: " px"; onEdited: value => root.store.setOption("bottomGap", value) }
                        NumberSetting { labelText: "Edge trigger height"; currentValue: root.options.edgeTriggerHeight; minimum: 1; maximum: 20; units: " px"; onEdited: value => root.store.setOption("edgeTriggerHeight", value) }
                        NumberSetting { labelText: "Slide animation"; currentValue: root.options.slideTime; minimum: 0; maximum: 2000; increment: 20; units: " ms"; onEdited: value => root.store.setOption("slideTime", value) }
                    }
                    ColumnLayout {
                        visible: root.section === "Applications"
                        Layout.fillWidth: true
                        spacing: 12
                        Heading { text: "Applications" }
                        TextSetting { labelText: "Launcher icon"; currentValue: root.options.launcherIcon; placeholder: "Icon name or absolute image path"; onEdited: value => root.store.setOption("launcherIcon", value.trim()) }
                        TextSetting {
                            labelText: "Excluded application IDs"
                            currentValue: root.options.excludedApps.join(", ")
                            placeholder: "Comma-separated IDs"
                            onEdited: value => root.store.setOption("excludedApps", value.split(",").map(v => v.trim()).filter(v => v))
                        }
                        TextSetting {
                            labelText: "Identity overrides (JSON object)"
                            currentValue: JSON.stringify(root.options.identityOverrides)
                            onEdited: value => {
                                try {
                                    const parsed = JSON.parse(value)
                                    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed) || Object.keys(parsed).some(k => typeof parsed[k] !== "string" || !parsed[k].trim()))
                                        throw Error("Expected an object mapping IDs to nonempty strings.")
                                    root.fieldError = ""
                                    root.store.setOption("identityOverrides", parsed)
                                } catch (e) { root.fieldError = "Identity overrides: " + e }
                            }
                        }
                        Hint { text: "Pins are stored separately. Reordering or removing a pin below saves immediately; Cancel does not undo pin changes." }
                        Repeater {
                            model: root.pinsStore.apps
                            delegate: RowLayout {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                Text { text: modelData.name || modelData.appId; color: root.foreground; Layout.fillWidth: true; elide: Text.ElideRight }
                                C.Button { text: "↑"; enabled: index > 0; Layout.preferredWidth: 40; onClicked: root.pinsStore.reorder(root.pinKey(modelData), root.pinKey(root.pinsStore.apps[index - 1])) }
                                C.Button { text: "↓"; enabled: index < root.pinsStore.apps.length - 1; Layout.preferredWidth: 40; onClicked: root.pinsStore.reorder(root.pinKey(modelData), index + 2 < root.pinsStore.apps.length ? root.pinKey(root.pinsStore.apps[index + 2]) : "") }
                                C.Button { text: "Remove"; onClicked: root.pinsStore.unpin(root.pinKey(modelData)) }
                            }
                        }
                        Hint { visible: root.pinsStore.errorMessage !== ""; text: root.pinsStore.errorMessage }
                    }
                    ColumnLayout {
                        visible: root.section === "Displays"
                        Layout.fillWidth: true
                        spacing: 12
                        Heading { text: "Displays" }
                        Hint { text: "One dock per enabled monitor. Applications are shared across workspaces and monitors." }
                        Repeater {
                            model: Quickshell.screens
                            delegate: ToggleSetting {
                                required property var modelData
                                text: modelData.name + " (" + modelData.width + " × " + modelData.height + ")"
                                checked: !root.options.excludedMonitors.includes(modelData.name)
                                enabled: !checked || Array.from(Quickshell.screens).filter(s => !root.options.excludedMonitors.includes(s.name)).length > 1
                                onToggled: {
                                    const name = modelData.name
                                    const next = root.options.excludedMonitors.filter(s => s !== name)
                                    if (!checked) next.push(name)
                                    root.store.setOption("excludedMonitors", next)
                                }
                            }
                        }
                        Hint { text: "Excluded monitors: " + (root.options.excludedMonitors.join(", ") || "none") + ". The last visible monitor cannot be disabled here." }
                    }
                    ColumnLayout {
                        visible: root.section === "Advanced"
                        Layout.fillWidth: true
                        spacing: 12
                        Heading { text: "Configuration and diagnostics" }
                        Hint { text: root.store.configDir }
                        C.Button { text: "Open configuration folder"; Layout.fillWidth: true; onClicked: Quickshell.execDetached(["xdg-open", root.store.configDir]) }
                        C.Button { text: "Reload saved configuration"; Layout.fillWidth: true; onClicked: { root.forceActiveFocus(); root.fieldError = ""; root.store.reloadSettings() } }
                        C.Button { text: "Reset settings to defaults (preview)"; Layout.fillWidth: true; onClicked: { root.forceActiveFocus(); root.fieldError = ""; root.store.resetAllSettings() } }
                        Hint { text: "Reset affects settings, not pins. Save explicitly to retain defaults, or Cancel to undo." }
                        Hint { text: "Check runtime: quickshell --version\nService logs: journalctl --user -u plank-wayland.service -b" }
                    }
                }
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.surface }
        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.fieldError || root.store.errorMessage || root.store.saveMessage
            color: root.fieldError || root.store.errorMessage ? (root.light ? "#a43d25" : "#ffb59d") : root.muted
            wrapMode: Text.WordWrap
            font.pixelSize: 12
        }
        RowLayout {
            Layout.fillWidth: true
            Text { text: root.store.saving ? "Saving…" : (root.store.dirty ? "Unsaved changes" : "All changes saved"); color: root.muted; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            C.Button { text: "Cancel"; enabled: !root.store.saving; onClicked: root.cancelAndClose() }
            C.Button { text: "Save"; highlighted: true; enabled: !root.store.saving && !root.store.externalConflict; onClicked: root.save() }
        }
    }
}
