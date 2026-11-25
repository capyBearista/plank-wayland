.pragma library

var items = [
    {
        "appId": "org.mozilla.firefox",
        "desktopId": "org.mozilla.firefox",
        "name": "Firefox",
        "icon": "firefox",
        "iconAliases": [],
        "fallback": "O",
        "command": [
            "firefox"
        ]
    },
    {
        "appId": "org.kde.kwrite",
        "desktopId": "org.kde.kwrite",
        "name": "KWrite",
        "icon": "kwrite",
        "iconAliases": [],
        "fallback": "O",
        "command": [
            "kwrite"
        ]
    },
    {
        "appId": "dev.zed.Zed-Preview",
        "desktopId": "dev.zed.Zed-Preview",
        "name": "Zed Preview",
        "icon": "/home/arjun/.local/zed-preview.app/share/icons/hicolor/512x512/apps/zed.png",
        "iconAliases": [],
        "fallback": "D",
        "command": [
            "/home/arjun/.local/zed-preview.app/bin/zed"
        ]
    },
    {
        "appId": "com.mitchellh.ghostty",
        "desktopId": "com.mitchellh.ghostty",
        "name": "Ghostty",
        "icon": "com.mitchellh.ghostty",
        "iconAliases": [],
        "fallback": "C",
        "command": [
            "ghostty",
            "--gtk-single-instance=true"
        ]
    },
    {
        "appId": "whatrust",
        "desktopId": "io.github.karem505.whatRust",
        "name": "whatRust",
        "icon": "io.github.karem505.whatRust",
        "iconAliases": [],
        "fallback": "W",
        "command": [
            "/usr/bin/flatpak",
            "run",
            "--branch=stable",
            "--arch=x86_64",
            "--command=whatrust",
            "--file-forwarding",
            "io.github.karem505.whatRust",
            "@@u",
            "@@"
        ]
    }
]
