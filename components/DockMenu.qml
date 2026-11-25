import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import "../settings.js" as DockSettings
import "../i18n.js" as I18n

Rectangle {
    id: root

    property bool opened: false
    property var app: null
    property var settings: null
    readonly property var theme: settings ? settings.theme : DockSettings.theme
    readonly property string configuredLanguage: settings ? settings.uiLanguage : (DockSettings.uiLanguage || "zh-CN")
    readonly property string language: configuredLanguage === "auto" ? Qt.locale().name : configuredLanguage
    readonly property color panelColor: theme.menuColor || "#ee242428"
    readonly property color panelBorderColor: theme.menuBorderColor || "#55ffffff"
    readonly property color textColor: theme.textColor || "white"
    readonly property color iconColor: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.7)

    signal pinRequested(var app)
    signal unpinRequested(var app)
    signal settingsRequested()
    signal closeRequested()
    signal focusWindowRequested(var window)
    signal newWindowRequested(var app)

    function t(key) {
        return I18n.text(key, language)
    }

    Timer {
        id: autoCloseTimer
        interval: 5000
        repeat: false
        onTriggered: root.closeRequested()
    }
    onOpenedChanged: {
        if (opened && !menuHover.hovered) autoCloseTimer.restart()
        else autoCloseTimer.stop()
    }
    onAppChanged: if (opened && !menuHover.hovered) autoCloseTimer.restart()

    HoverHandler {
        id: menuHover
        enabled: root.opened
        blocking: false
        onHoveredChanged: {
            if (hovered) autoCloseTimer.stop()
            else if (root.opened) autoCloseTimer.restart()
        }
    }

    readonly property int tooltipHeadroom: 36

    implicitWidth: 280
    implicitHeight: content.implicitHeight + 16
    radius: 14
    color: panelColor
    border.color: panelBorderColor
    border.width: 1

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: root.app ? root.app.name : ""
                color: root.iconColor
                font.pixelSize: 10
                font.bold: true
                opacity: 0.6
                Layout.fillWidth: true
                visible: root.app && root.app.toplevels && root.app.toplevels.length > 1
            }

            Item { Layout.fillWidth: true; visible: !(root.app && root.app.toplevels && root.app.toplevels.length > 1) }

            Text {
                text: "+"
                color: root.iconColor
                font.pixelSize: 16
                font.bold: true
                Layout.preferredWidth: 20
                horizontalAlignment: Text.AlignHCenter

                MouseArea {
                    id: newWindowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.app) root.newWindowRequested(root.app)
                        root.closeRequested()
                    }
                }
            }

            Text {
                text: root.app && root.app.pinned ? "▣" : "⊟"
                color: root.iconColor
                font.pixelSize: 11
                Layout.preferredWidth: 20
                horizontalAlignment: Text.AlignHCenter

                MouseArea {
                    id: pinArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.app) {
                            if (root.app.pinned) root.unpinRequested(root.app)
                            else root.pinRequested(root.app)
                        }
                        root.closeRequested()
                    }
                }
            }

            Text {
                text: "⊙"
                color: root.iconColor
                font.pixelSize: 13
                Layout.preferredWidth: 20
                horizontalAlignment: Text.AlignHCenter

                MouseArea {
                    id: settingsArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.settingsRequested()
                }
            }

            Text {
                text: "×"
                color: root.iconColor
                font.pixelSize: 15
                Layout.preferredWidth: 20
                horizontalAlignment: Text.AlignHCenter

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.panelBorderColor
            opacity: 0.3
            Layout.topMargin: 2
            visible: root.app && root.app.toplevels && root.app.toplevels.length > 1
        }

        Repeater {
            model: root.app && root.app.toplevels ? root.app.toplevels : []
            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 6
                color: windowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 8
                    spacing: 8

                    IconImage {
                        width: 16
                        height: 16
                        source: {
                            var icons = root.app.iconAliases ? root.app.iconAliases.slice() : []
                            if (root.app.icon && icons.indexOf(root.app.icon) < 0) icons.push(root.app.icon)
                            for (var i = 0; i < icons.length; i++) {
                                var path = Quickshell.iconPath(icons[i], true)
                                if (path) return path
                            }
                            return icons.length > 0 ? "image://icon/" + icons[0] : ""
                        }
                        asynchronous: true
                    }

                    Text {
                        text: modelData.title || "Janela"
                        color: root.textColor
                        font.pixelSize: 12
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: windowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusWindowRequested(modelData)
                }
            }
        }
    }
    // Center one tooltip within the popup's width so edge buttons cannot clip it.
    DockTooltip {
        text: newWindowArea.containsMouse ? "New window"
            : pinArea.containsMouse ? (root.app && root.app.pinned ? root.t("unpinFromDock") : root.t("pinToDock"))
            : settingsArea.containsMouse ? root.t("settings")
            : closeArea.containsMouse ? root.t("close") : ""
        shown: root.opened && text.length > 0
        settings: root.settings
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 5
    }
}
