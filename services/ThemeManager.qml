import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    property string mode: "dark"
    readonly property string modePath: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/desktop-theme/mode"

    function readMode() {
        const next = String(modeFile.text() || "").trim().toLowerCase()
        if (next === "light" || next === "dark") mode = next
    }

    FileView {
        id: modeFile
        path: root.modePath
        preload: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.readMode()
    }

    // Recover if the hook atomically replaces or initially creates the file.
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: modeFile.reload()
    }
}
