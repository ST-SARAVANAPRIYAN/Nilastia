pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property list<var> pages: [
        // Appearance
        {
            label: qsTr("Wallpaper & style"),
            icon: "palette",
            description: qsTr("Wallpaper, fonts, colours"),
            category: "appearance",
            keywords: ["wallpaper", "style", "font", "colour", "color", "theme", "dark theme", "transparency", "opacity"]
        },

        // Connectivity
        {
            label: qsTr("Display"),
            icon: "monitor",
            description: qsTr("Output configuration"),
            category: "connectivity",
            keywords: ["display", "resolution", "refresh rate", "monitor", "scale", "fps", "hz"]
        },
        {
            label: qsTr("Network"),
            icon: "wifi",
            description: qsTr("Wi-Fi, ethernet, VPN"),
            category: "connectivity",
            keywords: ["network", "wifi", "ethernet", "vpn", "internet", "ssid", "connection"]
        },
        {
            label: qsTr("Connected devices"),
            icon: "devices_other",
            description: qsTr("Bluetooth, pairing"),
            category: "connectivity",
            noFill: true,
            keywords: ["connected devices", "bluetooth", "pairing", "pair", "device"]
        },
        {
            label: qsTr("Audio"),
            icon: "volume_up",
            description: qsTr("App volumes, sound devices"),
            category: "connectivity",
            keywords: ["audio", "volume", "sound", "microphone", "mic", "headphone", "speaker"]
        },

        // System
        {
            label: qsTr("Updates"),
            icon: "update",
            description: qsTr("System updates"),
            category: "system",
            keywords: ["updates", "system", "upgrade", "git", "update", "check"]
        },
        {
            label: qsTr("Plugins"),
            icon: "extension",
            description: qsTr("Manage plugins"),
            category: "system",
            keywords: ["plugins", "extension", "manage", "addon"]
        },
        {
            label: qsTr("Compositor"),
            icon: "grid_view",
            description: qsTr("Niri layout, animations, input settings"),
            category: "system",
            keywords: ["compositor", "niri", "tiling", "gaps", "border", "focus ring", "keyboard", "mouse", "touchpad", "gestures", "springs", "animations"]
        },

        // Shell
        {
            label: qsTr("Panels"),
            icon: "dock_to_bottom",
            description: qsTr("Dashboard, taskbar, launcher, sidebar"),
            category: "shell",
            keywords: ["panels", "dashboard", "taskbar", "launcher", "sidebar", "dock"]
        },
        {
            label: qsTr("Apps"),
            icon: "apps",
            description: qsTr("Default apps, favourites, hidden apps"),
            category: "shell",
            keywords: ["apps", "default", "favourites", "hidden", "favorites", "preferred"]
        },
        {
            label: qsTr("Services"),
            icon: "build",
            description: qsTr("Poll intervals, lyrics backend"),
            category: "shell",
            keywords: ["services", "poll", "interval", "lyrics", "backend", "decrement", "increment"]
        },
        {
            label: qsTr("Language & region"),
            icon: "globe",
            description: qsTr("UI language, weather location, display units"),
            category: "shell",
            keywords: ["language", "region", "weather", "unit", "celsius", "fahrenheit", "twelve hour", "time", "clock", "date"]
        },

        // About
        {
            label: qsTr("About"),
            icon: "info",
            description: qsTr("System information, credits"),
            category: "about",
            keywords: ["about", "info", "system", "credits", "version", "quickshell", "caelestia"]
        },
    ]
}
