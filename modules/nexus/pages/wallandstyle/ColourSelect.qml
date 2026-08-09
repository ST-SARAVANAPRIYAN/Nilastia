import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Colours")
    isSubPage: true

    readonly property bool isDynamic: Colours.scheme === "dynamic"
    readonly property bool hasModeSelect: Colours.scheme === "dynamic" || 
                                          Colours.scheme === "caelestia" ||
                                          Colours.scheme === "gruvbox" ||
                                          (Colours.scheme === "everforest" && Colours.flavour === "medium")

    readonly property list<MenuItem> schemeItems: [
        MenuItem { text: qsTr("Dynamic (Wallpaper)"); icon: "wallpaper" },
        MenuItem { text: qsTr("Caelestia"); icon: "palette" },
        MenuItem { text: qsTr("Catppuccin"); icon: "palette" },
        MenuItem { text: qsTr("Tokyo Night"); icon: "palette" },
        MenuItem { text: qsTr("Everforest"); icon: "palette" },
        MenuItem { text: qsTr("Gruvbox"); icon: "palette" },
        MenuItem { text: qsTr("Rose Pine"); icon: "palette" },
        MenuItem { text: qsTr("Dracula"); icon: "palette" },
        MenuItem { text: qsTr("One Dark"); icon: "palette" },
        MenuItem { text: qsTr("Nord"); icon: "palette" },
        MenuItem { text: qsTr("Solarized"); icon: "palette" },
        MenuItem { text: qsTr("Everblush"); icon: "palette" },
        MenuItem { text: qsTr("Shado Theme"); icon: "palette" },
        MenuItem { text: qsTr("Dark Green"); icon: "palette" },
        MenuItem { text: qsTr("Old World"); icon: "palette" }
    ]


    readonly property list<MenuItem> catppuccinFlavours: [
        MenuItem { text: qsTr("Latte (Light)"); icon: "contrast" },
        MenuItem { text: qsTr("Frappe (Dark)"); icon: "contrast" },
        MenuItem { text: qsTr("Macchiato (Dark)"); icon: "contrast" },
        MenuItem { text: qsTr("Mocha (Dark)"); icon: "contrast" }
    ]

    readonly property list<MenuItem> rosepineFlavours: [
        MenuItem { text: qsTr("Dawn (Light)"); icon: "contrast" },
        MenuItem { text: qsTr("Main (Dark)"); icon: "contrast" },
        MenuItem { text: qsTr("Moon (Dark)"); icon: "contrast" }
    ]

    readonly property list<MenuItem> everforestFlavours: [
        MenuItem { text: qsTr("Soft"); icon: "contrast" },
        MenuItem { text: qsTr("Medium"); icon: "contrast" },
        MenuItem { text: qsTr("Hard"); icon: "contrast" }
    ]

    readonly property list<MenuItem> gruvboxFlavours: [
        MenuItem { text: qsTr("Soft"); icon: "contrast" },
        MenuItem { text: qsTr("Medium"); icon: "contrast" },
        MenuItem { text: qsTr("Hard"); icon: "contrast" }
    ]

    readonly property list<MenuItem> darkgreenFlavours: [
        MenuItem { text: qsTr("Medium"); icon: "contrast" },
        MenuItem { text: qsTr("Hard"); icon: "contrast" }
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
            case "caelestia": return qsTr("Caelestia");
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
                Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-m", mode]);
            }
        }

        SectionHeader {
            text: qsTr("Palette Preset")
        }

        SelectRow {
            first: true
            last: !root.isDynamic && Colours.scheme !== "catppuccin" && Colours.scheme !== "rosepine" && Colours.scheme !== "everforest" && Colours.scheme !== "gruvbox" && Colours.scheme !== "darkgreen"
            label: qsTr("Color Palette")
            subtext: qsTr("Active color scheme source")
            fallbackText: root.getSchemeLabel(Colours.scheme)
            fallbackIcon: "palette"
            menuItems: root.schemeItems

            active: {
                for (let i = 0; i < root.schemeItems.length; i++) {
                    const item = root.schemeItems[i];
                    let name = "dynamic";
                    if (item.text === qsTr("Caelestia")) name = "caelestia";
                    else if (item.text === qsTr("Catppuccin")) name = "catppuccin";
                    else if (item.text === qsTr("Tokyo Night")) name = "tokyonight";
                    else if (item.text === qsTr("Everforest")) name = "everforest";
                    else if (item.text === qsTr("Gruvbox")) name = "gruvbox";
                    else if (item.text === qsTr("Rose Pine")) name = "rosepine";
                    else if (item.text === qsTr("Dracula")) name = "dracula";
                    else if (item.text === qsTr("One Dark")) name = "onedark";
                    else if (item.text === qsTr("Nord")) name = "nord";
                    else if (item.text === qsTr("Solarized")) name = "solarized";
                    else if (item.text === qsTr("Everblush")) name = "everblush";
                    else if (item.text === qsTr("Shado Theme")) name = "shadotheme";
                    else if (item.text === qsTr("Dark Green")) name = "darkgreen";
                    else if (item.text === qsTr("Old World")) name = "oldworld";

                    if (name === Colours.scheme)
                        return item;
                }
                return null;
            }

            onSelected: item => {
                let name = "dynamic";
                if (item.text === qsTr("Caelestia")) name = "caelestia";
                else if (item.text === qsTr("Catppuccin")) name = "catppuccin";
                else if (item.text === qsTr("Tokyo Night")) name = "tokyonight";
                else if (item.text === qsTr("Everforest")) name = "everforest";
                else if (item.text === qsTr("Gruvbox")) name = "gruvbox";
                else if (item.text === qsTr("Rose Pine")) name = "rosepine";
                else if (item.text === qsTr("Dracula")) name = "dracula";
                else if (item.text === qsTr("One Dark")) name = "onedark";
                else if (item.text === qsTr("Nord")) name = "nord";
                else if (item.text === qsTr("Solarized")) name = "solarized";
                else if (item.text === qsTr("Everblush")) name = "everblush";
                else if (item.text === qsTr("Shado Theme")) name = "shadotheme";
                else if (item.text === qsTr("Dark Green")) name = "darkgreen";
                else if (item.text === qsTr("Old World")) name = "oldworld";

                Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-n", name]);
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
                    let f = "mocha";
                    if (item.text.startsWith(qsTr("Latte"))) f = "latte";
                    else if (item.text.startsWith(qsTr("Frappe"))) f = "frappe";
                    else if (item.text.startsWith(qsTr("Macchiato"))) f = "macchiato";
                    else if (item.text.startsWith(qsTr("Mocha"))) f = "mocha";

                    if (f === Colours.flavour)
                        return item;
                }
                return null;
            }

            onSelected: item => {
                let f = "mocha";
                if (item.text.startsWith(qsTr("Latte"))) f = "latte";
                else if (item.text.startsWith(qsTr("Frappe"))) f = "frappe";
                else if (item.text.startsWith(qsTr("Macchiato"))) f = "macchiato";
                else if (item.text.startsWith(qsTr("Mocha"))) f = "mocha";

                Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-f", f]);
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
                    let f = "main";
                    if (item.text.startsWith(qsTr("Dawn"))) f = "dawn";
                    else if (item.text.startsWith(qsTr("Main"))) f = "main";
                    else if (item.text.startsWith(qsTr("Moon"))) f = "moon";

                    if (f === Colours.flavour)
                        return item;
                }
                return null;
            }

            onSelected: item => {
                let f = "main";
                if (item.text.startsWith(qsTr("Dawn"))) f = "dawn";
                else if (item.text.startsWith(qsTr("Main"))) f = "main";
                else if (item.text.startsWith(qsTr("Moon"))) f = "moon";

                Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-f", f]);
            }
        }

        // Everforest Flavour Selector
        SelectRow {
            visible: Colours.scheme === "everforest"
            last: !root.hasModeSelect
            label: qsTr("Everforest Flavour")
            subtext: qsTr("Select Everforest variant (Soft/Hard are Dark, Medium has both)")
            fallbackText: Colours.flavour.charAt(0).toUpperCase() + Colours.flavour.slice(1)
            fallbackIcon: "contrast"
            menuItems: root.everforestFlavours

            active: {
                for (let i = 0; i < root.everforestFlavours.length; i++) {
                    const item = root.everforestFlavours[i];
                    let f = "medium";
                    if (item.text === qsTr("Soft")) f = "soft";
                    else if (item.text === qsTr("Medium")) f = "medium";
                    else if (item.text === qsTr("Hard")) f = "hard";

                    if (f === Colours.flavour)
                        return item;
                }
                return null;
            }

            onSelected: item => {
                let f = "medium";
                if (item.text === qsTr("Soft")) f = "soft";
                else if (item.text === qsTr("Medium")) f = "medium";
                else if (item.text === qsTr("Hard")) f = "hard";

                Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-f", f]);
            }
        }

        // Gruvbox Flavour Selector
        SelectRow {
            visible: Colours.scheme === "gruvbox"
            last: !root.hasModeSelect
            label: qsTr("Gruvbox Flavour")
            subtext: qsTr("Select Gruvbox variant (Soft, Medium, Hard)")
            fallbackText: Colours.flavour.charAt(0).toUpperCase() + Colours.flavour.slice(1)
            fallbackIcon: "contrast"
            menuItems: root.gruvboxFlavours

            active: {
                for (let i = 0; i < root.gruvboxFlavours.length; i++) {
                    const item = root.gruvboxFlavours[i];
                    let f = "medium";
                    if (item.text === qsTr("Soft")) f = "soft";
                    else if (item.text === qsTr("Medium")) f = "medium";
                    else if (item.text === qsTr("Hard")) f = "hard";

                    if (f === Colours.flavour)
                        return item;
                }
                return null;
            }

            onSelected: item => {
                let f = "medium";
                if (item.text === qsTr("Soft")) f = "soft";
                else if (item.text === qsTr("Medium")) f = "medium";
                else if (item.text === qsTr("Hard")) f = "hard";

                Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-f", f]);
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
                    let f = "medium";
                    if (item.text === qsTr("Medium")) f = "medium";
                    else if (item.text === qsTr("Hard")) f = "hard";

                    if (f === Colours.flavour)
                        return item;
                }
                return null;
            }

            onSelected: item => {
                let f = "medium";
                if (item.text === qsTr("Medium")) f = "medium";
                else if (item.text === qsTr("Hard")) f = "hard";

                Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-f", f]);
            }
        }

        ConnectedRect {
            visible: root.isDynamic
            last: true
            Layout.fillWidth: true
            implicitHeight: layout.implicitHeight + layout.anchors.margins * 2

            ColumnLayout {
                id: layout
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
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
                        onClicked: Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-v", "tonalspot"])
                    }
                    TextButton {
                        Layout.fillWidth: true
                        text: qsTr("Vibrant")
                        type: ButtonBase.Tonal
                        isToggle: true
                        checked: Colours.variant === "vibrant"
                        onClicked: Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-v", "vibrant"])
                    }
                    TextButton {
                        Layout.fillWidth: true
                        text: qsTr("Expressive")
                        type: ButtonBase.Tonal
                        isToggle: true
                        checked: Colours.variant === "expressive"
                        onClicked: Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-v", "expressive"])
                    }
                    TextButton {
                        Layout.fillWidth: true
                        text: qsTr("Fidelity")
                        type: ButtonBase.Tonal
                        isToggle: true
                        checked: Colours.variant === "fidelity"
                        onClicked: Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-v", "fidelity"])
                    }
                    TextButton {
                        Layout.fillWidth: true
                        text: qsTr("Fruit Salad")
                        type: ButtonBase.Tonal
                        isToggle: true
                        checked: Colours.variant === "fruitsalad"
                        onClicked: Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-v", "fruitsalad"])
                    }
                    TextButton {
                        Layout.fillWidth: true
                        text: qsTr("Rainbow")
                        type: ButtonBase.Tonal
                        isToggle: true
                        checked: Colours.variant === "rainbow"
                        onClicked: Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-v", "rainbow"])
                    }
                    TextButton {
                        Layout.fillWidth: true
                        text: qsTr("Neutral")
                        type: ButtonBase.Tonal
                        isToggle: true
                        checked: Colours.variant === "neutral"
                        onClicked: Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-v", "neutral"])
                    }
                    TextButton {
                        Layout.fillWidth: true
                        text: qsTr("Monochrome")
                        type: ButtonBase.Tonal
                        isToggle: true
                        checked: Colours.variant === "monochrome"
                        onClicked: Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-v", "monochrome"])
                    }
                }
            }
        }
    }
}
