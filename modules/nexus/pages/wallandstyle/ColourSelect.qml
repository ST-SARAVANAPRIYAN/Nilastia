import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Nilastia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import qs.utils

PageBase {
    id: root

    title: qsTr("Colours")
    isSubPage: true

    readonly property bool isDynamic: Colours.scheme === "dynamic"
    readonly property bool hasModeSelect: Colours.scheme === "dynamic" || 
                                          Colours.scheme === "nilastia" ||
                                          Colours.scheme === "caelestia" ||
                                          Colours.scheme === "gruvbox" ||
                                          Colours.scheme === "angel" ||
                                          Colours.scheme === "fieldsoftheshire" ||
                                          Colours.scheme === "vitesse" ||
                                          (Colours.scheme === "everforest" && Colours.flavour === "medium")

    property bool enableTerm: true
    property bool enableGtk: true
    property bool enableQt: true
    property bool enableChromium: true
    property bool enableZed: true
    property bool enableDiscord: true

    resources: [
        FileView {
            id: cliConfigView
            path: `${Paths.config}/cli.json`
            watchChanges: true

            function updateFlags() {
                try {
                    const data = JSON.parse(text());
                    if (data && data.theme) {
                        root.enableTerm = data.theme.enableTerm !== undefined ? data.theme.enableTerm : true;
                        root.enableGtk = data.theme.enableGtk !== undefined ? data.theme.enableGtk : true;
                        root.enableQt = data.theme.enableQt !== undefined ? data.theme.enableQt : true;
                        root.enableChromium = data.theme.enableChromium !== undefined ? data.theme.enableChromium : true;
                        root.enableZed = data.theme.enableZed !== undefined ? data.theme.enableZed : true;
                        root.enableDiscord = data.theme.enableDiscord !== undefined ? data.theme.enableDiscord : true;
                    }
                } catch (e) {
                    console.log("[Nilastia ColourSelect] Failed to parse cli.json:", e);
                }
            }

            onLoaded: updateFlags()
            onFileChanged: updateFlags()
        }
    ]

    function toggleThemeFlag(key, enabled) {
        if (key === "enableTerm") root.enableTerm = enabled;
        else if (key === "enableGtk") root.enableGtk = enabled;
        else if (key === "enableQt") root.enableQt = enabled;
        else if (key === "enableChromium") root.enableChromium = enabled;
        else if (key === "enableZed") root.enableZed = enabled;
        else if (key === "enableDiscord") root.enableDiscord = enabled;

        const cmd = [
            "python3",
            "-c",
            `import json, os; p = os.path.expanduser('~/.config/nilastia/cli.json'); d = json.load(open(p)) if os.path.exists(p) else {}; d.setdefault('theme', {})['${key}'] = ${enabled ? "True" : "False"}; json.dump(d, open(p, 'w'), indent=4)`
        ];
        Quickshell.execDetached(cmd);
        Quickshell.execDetached(["nilastia", "scheme", "set", "--notify"]);
    }

    readonly property list<MenuItem> schemeItems: [
        MenuItem { text: qsTr("Dynamic (Wallpaper)"); icon: "wallpaper"; value: "dynamic" },
        MenuItem { text: qsTr("Nilastia"); icon: "palette"; value: "nilastia" },
        MenuItem { text: qsTr("Catppuccin"); icon: "palette"; value: "catppuccin" },
        MenuItem { text: qsTr("Tokyo Night"); icon: "palette"; value: "tokyonight" },
        MenuItem { text: qsTr("Everforest"); icon: "palette"; value: "everforest" },
        MenuItem { text: qsTr("Gruvbox"); icon: "palette"; value: "gruvbox" },
        MenuItem { text: qsTr("Rose Pine"); icon: "palette"; value: "rosepine" },
        MenuItem { text: qsTr("Dracula"); icon: "palette"; value: "dracula" },
        MenuItem { text: qsTr("One Dark"); icon: "palette"; value: "onedark" },
        MenuItem { text: qsTr("Nord"); icon: "palette"; value: "nord" },
        MenuItem { text: qsTr("Solarized"); icon: "palette"; value: "solarized" },
        MenuItem { text: qsTr("Everblush"); icon: "palette"; value: "everblush" },
        MenuItem { text: qsTr("Shado Theme"); icon: "palette"; value: "shadotheme" },
        MenuItem { text: qsTr("Dark Green"); icon: "palette"; value: "darkgreen" },
        MenuItem { text: qsTr("Old World"); icon: "palette"; value: "oldworld" }
    ]

    readonly property list<MenuItem> catppuccinFlavours: [
        MenuItem { text: qsTr("Latte (Light)"); icon: "contrast"; value: "latte" },
        MenuItem { text: qsTr("Frappe (Dark)"); icon: "contrast"; value: "frappe" },
        MenuItem { text: qsTr("Macchiato (Dark)"); icon: "contrast"; value: "macchiato" },
        MenuItem { text: qsTr("Mocha (Dark)"); icon: "contrast"; value: "mocha" }
    ]

    readonly property list<MenuItem> rosepineFlavours: [
        MenuItem { text: qsTr("Dawn (Light)"); icon: "contrast"; value: "dawn" },
        MenuItem { text: qsTr("Main (Dark)"); icon: "contrast"; value: "main" },
        MenuItem { text: qsTr("Moon (Dark)"); icon: "contrast"; value: "moon" }
    ]

    readonly property list<MenuItem> everforestFlavours: [
        MenuItem { text: qsTr("Soft"); icon: "contrast"; value: "soft" },
        MenuItem { text: qsTr("Medium"); icon: "contrast"; value: "medium" },
        MenuItem { text: qsTr("Hard"); icon: "contrast"; value: "hard" }
    ]

    readonly property list<MenuItem> gruvboxFlavours: [
        MenuItem { text: qsTr("Soft"); icon: "contrast"; value: "soft" },
        MenuItem { text: qsTr("Medium"); icon: "contrast"; value: "medium" },
        MenuItem { text: qsTr("Hard"); icon: "contrast"; value: "hard" }
    ]

    readonly property list<MenuItem> darkgreenFlavours: [
        MenuItem { text: qsTr("Medium"); icon: "contrast"; value: "medium" },
        MenuItem { text: qsTr("Hard"); icon: "contrast"; value: "hard" }
    ]

    function getVariantLabel(v): string {
        switch (v) {
            case "tonalspot": return qsTr("Tonal Spot");
            case "vibrant": return qsTr("Vibrant");
            case "expressive": return qsTr("Expressive");
            case "fidelity": return qsTr("Fidelity");
            case "fruitsalad": return qsTr("Fruit Salad");
            case "rainbow": return qsTr("Rainbow");
            case "neutral": return qsTr("Neutral");
            case "monochrome": return qsTr("Monochrome");
            case "content": return qsTr("Content");
            default: return qsTr("Tonal Spot");
        }
    }

    function getSchemeLabel(s): string {
        switch (s) {
            case "dynamic": return qsTr("Dynamic (Wallpaper)");
            case "nilastia": return qsTr("Nilastia");
            case "catppuccin": return qsTr("Catppuccin");
            case "tokyonight": return qsTr("Tokyo Night");
            case "everforest": return qsTr("Everforest");
            case "gruvbox": return qsTr("Gruvbox");
            case "rosepine": return qsTr("Rose Pine");
            case "dracula": return qsTr("Dracula");
            case "onedark": return qsTr("One Dark");
            case "nord": return qsTr("Nord");
            case "solarized": return qsTr("Solarized");
            case "everblush": return qsTr("Everblush");
            case "shadotheme": return qsTr("Shado Theme");
            case "darkgreen": return qsTr("Dark Green");
            case "oldworld": return qsTr("Old World");
            default: return s || qsTr("Dynamic (Wallpaper)");
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            visible: root.hasModeSelect
            text: qsTr("Theme Mode")
        }

        ToggleRow {
            visible: root.hasModeSelect
            first: true
            last: true
            text: qsTr("Dark Mode")
            subtext: checked ? qsTr("Dark theme is active") : qsTr("Light theme is active")
            
            Binding on checked {
                value: !Colours.light
            }

            onToggled: {
                const mode = checked ? "dark" : "light";
                Quickshell.execDetached(["nilastia", "scheme", "set", "--notify", "-m", mode]);
            }
        }

        SectionHeader {
            text: qsTr("Palette Preset")
        }

        SelectRow {
            first: true
            last: Colours.scheme !== "catppuccin" && Colours.scheme !== "rosepine" && Colours.scheme !== "everforest" && Colours.scheme !== "gruvbox" && Colours.scheme !== "darkgreen" && Colours.scheme !== "dynamic"
            label: qsTr("Color Palette")
            subtext: qsTr("Active color scheme source")
            fallbackText: root.getSchemeLabel(Colours.scheme)
            fallbackIcon: "palette"
            menuItems: root.schemeItems

            active: {
                for (let i = 0; i < root.schemeItems.length; i++) {
                    const item = root.schemeItems[i];
                    if (item.value === Colours.scheme)
                        return item;
                }
                return null;
            }

            onSelected: item => {
                Quickshell.execDetached(["nilastia", "scheme", "set", "--notify", "-n", item.value]);
            }
        }


        // Catppuccin Flavour Selector
        SelectRow {
            visible: Colours.scheme === "catppuccin"
            last: true
            label: qsTr("Catppuccin Flavour")
            subtext: qsTr("Select Catppuccin flavor (Latte is Light, Mocha is Dark)")
            fallbackText: Colours.flavour.charAt(0).toUpperCase() + Colours.flavour.slice(1)
            fallbackIcon: "contrast"
            menuItems: root.catppuccinFlavours

            active: {
                for (let i = 0; i < root.catppuccinFlavours.length; i++) {
                    const item = root.catppuccinFlavours[i];
                    if (item.value === Colours.flavour)
                        return item;
                }
                return null;
            }

            onSelected: item => {
                Quickshell.execDetached(["nilastia", "scheme", "set", "--notify", "-f", item.value]);
            }
        }

        // Rose Pine Flavour Selector
        SelectRow {
            visible: Colours.scheme === "rosepine"
            last: true
            label: qsTr("Rose Pine Flavour")
            subtext: qsTr("Select Rose Pine flavor (Dawn is Light, Main/Moon are Dark)")
            fallbackText: Colours.flavour.charAt(0).toUpperCase() + Colours.flavour.slice(1)
            fallbackIcon: "contrast"
            menuItems: root.rosepineFlavours

            active: {
                for (let i = 0; i < root.rosepineFlavours.length; i++) {
                    const item = root.rosepineFlavours[i];
                    if (item.value === Colours.flavour)
                        return item;
                }
                return null;
            }

            onSelected: item => {
                Quickshell.execDetached(["nilastia", "scheme", "set", "--notify", "-f", item.value]);
            }
        }

        // Everforest Flavour Selector
        SelectRow {
            visible: Colours.scheme === "everforest"
            last: true
            label: qsTr("Everforest Flavour")
            subtext: qsTr("Select Everforest variant (Soft/Hard are Dark, Medium has both)")
            fallbackText: Colours.flavour.charAt(0).toUpperCase() + Colours.flavour.slice(1)
            fallbackIcon: "contrast"
            menuItems: root.everforestFlavours

            active: {
                for (let i = 0; i < root.everforestFlavours.length; i++) {
                    const item = root.everforestFlavours[i];
                    if (item.value === Colours.flavour)
                        return item;
                }
                return null;
            }

            onSelected: item => {
                Quickshell.execDetached(["nilastia", "scheme", "set", "--notify", "-f", item.value]);
            }
        }

        // Gruvbox Flavour Selector
        SelectRow {
            visible: Colours.scheme === "gruvbox"
            last: true
            label: qsTr("Gruvbox Flavour")
            subtext: qsTr("Select Gruvbox variant (Soft, Medium, Hard)")
            fallbackText: Colours.flavour.charAt(0).toUpperCase() + Colours.flavour.slice(1)
            fallbackIcon: "contrast"
            menuItems: root.gruvboxFlavours

            active: {
                for (let i = 0; i < root.gruvboxFlavours.length; i++) {
                    const item = root.gruvboxFlavours[i];
                    if (item.value === Colours.flavour)
                        return item;
                }
                return null;
            }

            onSelected: item => {
                Quickshell.execDetached(["nilastia", "scheme", "set", "--notify", "-f", item.value]);
            }
        }

        // Dark Green Flavour Selector
        SelectRow {
            visible: Colours.scheme === "darkgreen"
            last: true
            label: qsTr("Dark Green Flavour")
            subtext: qsTr("Select Dark Green variant")
            fallbackText: Colours.flavour.charAt(0).toUpperCase() + Colours.flavour.slice(1)
            fallbackIcon: "contrast"
            menuItems: root.darkgreenFlavours

            active: {
                for (let i = 0; i < root.darkgreenFlavours.length; i++) {
                    const item = root.darkgreenFlavours[i];
                    if (item.value === Colours.flavour)
                        return item;
                }
                return null;
            }

            onSelected: item => {
                Quickshell.execDetached(["nilastia", "scheme", "set", "--notify", "-f", item.value]);
            }
        }

        // Dynamic Flavour Selector
        SelectRow {
            visible: Colours.scheme === "dynamic"
            last: false
            label: qsTr("Dynamic Flavour")
            subtext: qsTr("Select Wallpaper theme contrast flavour")
            fallbackText: Colours.flavour.charAt(0).toUpperCase() + Colours.flavour.slice(1)
            fallbackIcon: "contrast"
            menuItems: [
                MenuItem { text: qsTr("Default"); icon: "contrast"; value: "default" },
                MenuItem { text: qsTr("Hard"); icon: "contrast"; value: "hard" }
            ]

            active: {
                for (let i = 0; i < menuItems.length; i++) {
                    const item = menuItems[i];
                    if (item.value === Colours.flavour)
                        return item;
                }
                return null;
            }

            onSelected: item => {
                Quickshell.execDetached(["nilastia", "scheme", "set", "--notify", "-f", item.value]);
            }
        }

        ConnectedRect {
            visible: root.isDynamic
            last: true
            Layout.fillWidth: true
            implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2

            ColumnLayout {
                id: layout
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: Tokens.padding.medium
                anchors.bottomMargin: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Material You Variant")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Mathematical algorithm to extract accent colors")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Tokens.spacing.small
                    rowSpacing: Tokens.spacing.small

                    TextButton {
                        Layout.fillWidth: true
                        text: qsTr("Tonal Spot")
                        type: ButtonBase.Tonal
                        isToggle: true
                        checked: Colours.variant === "tonalspot"
                        onClicked: Quickshell.execDetached(["nilastia", "scheme", "set", "--notify", "-v", "tonalspot"])
                    }
                    TextButton {
                        Layout.fillWidth: true
                        text: qsTr("Vibrant")
                        type: ButtonBase.Tonal
                        isToggle: true
                        checked: Colours.variant === "vibrant"
                        onClicked: Quickshell.execDetached(["nilastia", "scheme", "set", "--notify", "-v", "vibrant"])
                    }
                    TextButton {
                        Layout.fillWidth: true
                        text: qsTr("Expressive")
                        type: ButtonBase.Tonal
                        isToggle: true
                        checked: Colours.variant === "expressive"
                        onClicked: Quickshell.execDetached(["nilastia", "scheme", "set", "--notify", "-v", "expressive"])
                    }
                    TextButton {
                        Layout.fillWidth: true
                        text: qsTr("Fidelity")
                        type: ButtonBase.Tonal
                        isToggle: true
                        checked: Colours.variant === "fidelity"
                        onClicked: Quickshell.execDetached(["nilastia", "scheme", "set", "--notify", "-v", "fidelity"])
                    }
                    TextButton {
                        Layout.fillWidth: true
                        text: qsTr("Fruit Salad")
                        type: ButtonBase.Tonal
                        isToggle: true
                        checked: Colours.variant === "fruitsalad"
                        onClicked: Quickshell.execDetached(["nilastia", "scheme", "set", "--notify", "-v", "fruitsalad"])
                    }
                    TextButton {
                        Layout.fillWidth: true
                        text: qsTr("Rainbow")
                        type: ButtonBase.Tonal
                        isToggle: true
                        checked: Colours.variant === "rainbow"
                        onClicked: Quickshell.execDetached(["nilastia", "scheme", "set", "--notify", "-v", "rainbow"])
                    }
                    TextButton {
                        Layout.fillWidth: true
                        text: qsTr("Neutral")
                        type: ButtonBase.Tonal
                        isToggle: true
                        checked: Colours.variant === "neutral"
                        onClicked: Quickshell.execDetached(["nilastia", "scheme", "set", "--notify", "-v", "neutral"])
                    }
                    TextButton {
                        Layout.fillWidth: true
                        text: qsTr("Monochrome")
                        type: ButtonBase.Tonal
                        isToggle: true
                        checked: Colours.variant === "monochrome"
                        onClicked: Quickshell.execDetached(["nilastia", "scheme", "set", "--notify", "-v", "monochrome"])
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("App Integrations")
        }

        ToggleRow {
            first: true
            text: qsTr("Terminal Integration")
            subtext: qsTr("Theme active shell sessions via OSC sequences")
            checked: root.enableTerm
            onToggled: root.toggleThemeFlag("enableTerm", checked)
        }

        ToggleRow {
            text: qsTr("GTK & Qt Applications")
            subtext: qsTr("Align theme of core system application interfaces")
            checked: root.enableGtk && root.enableQt
            onToggled: {
                root.toggleThemeFlag("enableGtk", checked);
                root.toggleThemeFlag("enableQt", checked);
            }
        }

        ToggleRow {
            text: qsTr("Web Browsers")
            subtext: qsTr("Apply color scheme frame policy to Brave, Chrome, etc.")
            checked: root.enableChromium
            onToggled: root.toggleThemeFlag("enableChromium", checked)
        }

        ToggleRow {
            text: qsTr("Developer Editors")
            subtext: qsTr("Automatically theme the Zed editor workspace")
            checked: root.enableZed
            onToggled: root.toggleThemeFlag("enableZed", checked)
        }

        ToggleRow {
            last: true
            text: qsTr("Discord Integration")
            subtext: qsTr("Theme Discord desktop client UI custom stylesheets")
            checked: root.enableDiscord
            onToggled: root.toggleThemeFlag("enableDiscord", checked)
        }
    }
}
