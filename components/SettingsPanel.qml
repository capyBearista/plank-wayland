import QtQuick
import QtQuick.Layouts
import "../settings.js" as DockSettings
import "../i18n.js" as I18n

Rectangle {
    id: root

    property var store: null
    readonly property var theme: store ? store.theme : DockSettings.theme
    readonly property string configuredLanguage: store ? store.uiLanguage : (DockSettings.uiLanguage || "zh-CN")
    readonly property string language: configuredLanguage === "auto" ? Qt.locale().name : configuredLanguage
    readonly property color panelColor: theme.menuColor || "#ee242428"
    readonly property color panelBorderColor: theme.menuBorderColor || "#55ffffff"
    readonly property color textColor: theme.textColor || "white"
    readonly property color subtleTextColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.72)
    readonly property color closeButtonColor: theme.innerBackgroundColor || "#333338"
    readonly property color closeButtonHoverColor: Qt.rgba(closeButtonColor.r, closeButtonColor.g, closeButtonColor.b, 0.85)

    signal closeRequested()

    width: 420
    height: 640
    radius: 18
    color: panelColor
    border.color: panelBorderColor
    border.width: 1

    function t(key) {
        return I18n.text(key, language)
    }

    function state(key, enabled) {
        return I18n.state(key, enabled, language)
    }

    readonly property var options: store ? store.dockValues : ({})

    function cycleOption(key, values) {
        store.setOption(key, values[(values.indexOf(options[key]) + 1) % values.length])
    }

    function styleButton(name) {
        return I18n.selected(I18n.styleLabel(name, language), store && store.effectiveStyle === name)
    }

    Flickable {
        anchors.fill: parent
        enabled: !root.store.saving
        anchors.margins: 14
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 10

            RowLayout {
            Layout.fillWidth: true

            Text {
                text: root.t("dockSettings")
                color: root.textColor
                font.pixelSize: 16
                font.bold: true
                Layout.fillWidth: true
            }

            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: closeMouse.containsMouse ? root.closeButtonHoverColor : root.closeButtonColor

                Text { anchors.centerIn: parent; text: "×"; color: root.textColor; font.pixelSize: 18 }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        Text { text: "Appearance"; color: root.textColor; font.bold: true }
        SettingsButton {
            settings: root.store
            text: "Theme mode: " + root.options.themeMode
            onClicked: root.cycleOption("themeMode", ["system", "light", "dark", "manual"])
        }
        Text { text: root.t("style"); color: root.textColor; opacity: 0.75; font.pixelSize: 12 }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 8
            rowSpacing: 8

            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("obsidian"); onClicked: root.store.setStyle("obsidian") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("deep-sea"); onClicked: root.store.setStyle("deep-sea") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("nebula"); onClicked: root.store.setStyle("nebula") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("frost"); onClicked: root.store.setStyle("frost") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("liquid-titanium"); onClicked: root.store.setStyle("liquid-titanium") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("onyx-gold"); onClicked: root.store.setStyle("onyx-gold") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("aurora-noir"); onClicked: root.store.setStyle("aurora-noir") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("champagne-glass"); onClicked: root.store.setStyle("champagne-glass") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("rose-quartz"); onClicked: root.store.setStyle("rose-quartz") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("cobalt-pro"); onClicked: root.store.setStyle("cobalt-pro") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("macos"); onClicked: root.store.setStyle("macos") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("macos-dark"); onClicked: root.store.setStyle("macos-dark") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("macos-light"); onClicked: root.store.setStyle("macos-light") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("plank"); onClicked: root.store.setStyle("plank") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("plank-transparent"); onClicked: root.store.setStyle("plank-transparent") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("glass"); onClicked: root.store.setStyle("glass") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("clear-glass"); onClicked: root.store.setStyle("clear-glass") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("clear-glass-light"); onClicked: root.store.setStyle("clear-glass-light") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("black-glass"); onClicked: root.store.setStyle("black-glass") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("neon"); onClicked: root.store.setStyle("neon") }
            SettingsButton { settings: root.store; neutral: true; text: root.styleButton("minimal"); onClicked: root.store.setStyle("minimal") }
        }

        Text { text: root.t("iconSize"); color: root.textColor; opacity: 0.75; font.pixelSize: 12 }

        RowLayout {
            Layout.fillWidth: true
            SettingsButton { settings: root.store; neutral: true; text: "−"; onClicked: root.store.setIconSize(root.store.iconSize - 4) }
            Text { text: root.store ? root.store.iconSize + " " + root.t("px") : ""; color: root.textColor; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
            SettingsButton { settings: root.store; neutral: true; text: "+"; onClicked: root.store.setIconSize(root.store.iconSize + 4) }
        }

        SettingsButton {
            Layout.fillWidth: true
            settings: root.store
            neutral: true
            text: root.state("systemIconTheme", root.store && root.store.followSystemIconTheme)
            onClicked: root.store.toggleFollowSystemIconTheme()
        }

        Text {
            Layout.fillWidth: true
            text: root.store ? I18n.labelValue("currentIconTheme", root.store.systemIconTheme || root.t("unknown"), root.language) : ""
            color: root.textColor
            opacity: 0.55
            elide: Text.ElideRight
            font.pixelSize: 11
        }

        Text { text: root.t("magnification"); color: root.textColor; opacity: 0.75; font.pixelSize: 12 }

        RowLayout {
            Layout.fillWidth: true
            SettingsButton { settings: root.store; neutral: true; text: "−"; onClicked: root.store.setZoomPercent(root.store.zoomPercent - 10) }
            Text { text: root.store ? root.store.zoomPercent + "%" : ""; color: root.textColor; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
            SettingsButton { settings: root.store; neutral: true; text: "+"; onClicked: root.store.setZoomPercent(root.store.zoomPercent + 10) }
        }

        SettingsButton {
            Layout.fillWidth: true
            settings: root.store
            neutral: true
            text: root.state("magnification", root.store && root.store.zoomEnabled)
            onClicked: root.store.toggleZoom()
        }

        SettingsButton {
            Layout.fillWidth: true
            settings: root.store
            neutral: true
            text: root.state("autoHide", root.store && root.store.autoHide)
            onClicked: root.store.toggleAutoHide()
        }

        SettingsButton {
            Layout.fillWidth: true
            settings: root.store
            neutral: true
            text: root.state("smartHide", root.store && root.store.smartHide)
            onClicked: root.store.toggleSmartHide()
        }

        SettingsButton {
            Layout.fillWidth: true
            settings: root.store
            neutral: true
            text: root.store ? I18n.labelValue("indicator", I18n.indicatorStyle(root.store.indicatorStyle, root.language), root.language) : root.t("indicator")
            onClicked: root.store.cycleIndicator()
        }

        Text { text: root.t("fineTune"); color: root.textColor; opacity: 0.75; font.pixelSize: 12 }

        RowLayout {
            Layout.fillWidth: true
            SettingsButton { settings: root.store; neutral: true; text: root.t("radiusMinus"); onClicked: root.store.adjustRadius(-2) }
            Text { text: root.store ? root.t("radiusShort") + " " + (root.theme.radius || 0) : ""; color: root.textColor; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
            SettingsButton { settings: root.store; neutral: true; text: root.t("radiusPlus"); onClicked: root.store.adjustRadius(2) }
        }

        RowLayout {
            Layout.fillWidth: true
            SettingsButton { settings: root.store; neutral: true; text: root.t("fainter"); onClicked: root.store.adjustOpacity(-16) }
            Text { text: root.store ? root.t("opacity") + " " + root.store.opacityAdjust : ""; color: root.textColor; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
            SettingsButton { settings: root.store; neutral: true; text: root.t("stronger"); onClicked: root.store.adjustOpacity(16) }
        }

        Text { text: "Visibility"; color: root.textColor; font.bold: true }
        Repeater {
            model: [
                {key:"bottomGap", label:"Bottom gap (px)", step:1},
                {key:"edgeTriggerHeight", label:"Edge trigger (px)", step:1},
                {key:"hideDelayMs", label:"Hide delay (ms)", step:50},
                {key:"hoverMenuDelayMs", label:"Hover menu delay (ms)", step:50},
                {key:"attentionRevealMs", label:"Attention reveal (ms)", step:500}
            ]
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                Text { text: modelData.label; color: root.textColor; Layout.fillWidth: true }
                SettingsButton { Layout.preferredWidth: 38; Layout.fillWidth: false; settings: root.store; text: "−"; onClicked: root.store.setOption(modelData.key, root.options[modelData.key] - modelData.step) }
                Text { text: String(root.options[modelData.key]); color: root.textColor }
                SettingsButton { Layout.preferredWidth: 38; Layout.fillWidth: false; settings: root.store; text: "+"; onClicked: root.store.setOption(modelData.key, root.options[modelData.key] + modelData.step) }
            }
        }
        Text { text: "Window behavior"; color: root.textColor; font.bold: true }
        SettingsButton {
            settings: root.store
            text: "Click to minimize: " + root.options.minimizeMode
            onClicked: root.cycleOption("minimizeMode", ["off", "native", "workspace"])
        }
        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: root.textColor
            opacity: 0.65
            text: "Minimize modes are experimental. Workspace mode moves ordinary windows to a reserved special workspace. See README for recovery."
            font.pixelSize: 11
        }
        Repeater {
            model: [{key:"dragReorder", label:"Drag pins to reorder"}, {key:"launchFeedback", label:"Launch feedback"}, {key:"attentionReveal", label:"Attention reveal"}, {key:"attentionInFullscreen", label:"Attention over fullscreen"}]
            delegate: SettingsButton {
                required property var modelData
                settings: root.store
                text: modelData.label + ": " + (root.options[modelData.key] ? "On" : "Off")
                onClicked: root.store.setOption(modelData.key, !root.options[modelData.key])
            }
        }
        Text { text: "Launcher, applications and displays"; color: root.textColor; font.bold: true }
        Repeater {
            model: [{key:"launcherIcon", label:"Launcher icon name or absolute path", list:false}, {key:"excludedApps", label:"Excluded application IDs (comma separated)", list:true}, {key:"excludedMonitors", label:"Excluded monitor names (comma separated)", list:true}]
            delegate: ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                Text { text: modelData.label; color: root.textColor; font.pixelSize: 11 }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    color: root.theme.menuItemColor || "#333333"
                    radius: 6
                    TextInput {
                        anchors.fill: parent
                        anchors.margins: 8
                        color: root.textColor
                        selectByMouse: true
                        clip: true
                        text: modelData.list ? (root.options[modelData.key] || []).join(", ") : String(root.options[modelData.key] || "")
                        onEditingFinished: {
                            const value = modelData.list ? text.split(",").map(s => s.trim()).filter(s => s) : text.trim()
                            if (JSON.stringify(value) !== JSON.stringify(root.options[modelData.key])) root.store.setOption(modelData.key, value)
                        }
                    }
                }
            }
        }
        Text {
            Layout.fillWidth: true
            text: root.store.errorMessage
            visible: text !== ""
            color: root.textColor
            wrapMode: Text.WordWrap
        }
        SettingsButton {
            settings: root.store
            text: "Reload / discard unsaved edits"
            enabled: !root.store.saving
            onClicked: root.store.reloadSettings()
        }
        Text {
            Layout.fillWidth: true
            text: root.t("savedHint")
            color: root.textColor
            opacity: 0.55
            wrapMode: Text.WordWrap
            font.pixelSize: 11
        }

        SettingsButton {
            Layout.fillWidth: true
            settings: root.store
            neutral: false
            enabled: root.store && !root.store.saving && !root.store.externalConflict
            text: root.store && root.store.saving ? "Saving…" : (root.store && root.store.dirty ? root.t("saveChanges") : root.t("saved"))
            onClicked: if (root.store) root.store.save()
        }
        }
    }
}
