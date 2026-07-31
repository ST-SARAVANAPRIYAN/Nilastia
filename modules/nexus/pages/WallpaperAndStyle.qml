pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.images
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Wallpaper & style")

    readonly property bool supportsLightMode: [
        "dynamic", "caelestia", "gruvbox", "everforest", "catppuccin", "rosepine",
        "angel", "fieldsoftheshire", "vitesse", "sakura", "zengarden"
    ].includes(Colours.scheme)

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StyledClippingRect {
            id: wallWrapper

            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Tokens.spacing.large
            implicitWidth: {
                const screen = root.nState.screen;
                return implicitHeight / screen.height * screen.width;
            }
            implicitHeight: {
                const screen = root.nState.screen;
                const cWidth = root.cappedWidth;
                return Math.min(Math.round(cWidth * 0.4), cWidth / screen.width * screen.height);
            }

            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.large

            Loader {
                anchors.centerIn: parent
                opacity: Config.background.wallpaperEnabled ? 0 : 1
                active: opacity > 0

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hide_image"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Wallpaper disabled")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.large
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }

            Item {
                anchors.fill: parent
                opacity: Config.background.wallpaperEnabled ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }

                Loader {
                    id: wallIndicatorLoader

                    anchors.centerIn: parent

                    opacity: 0
                    active: opacity > 0

                    sourceComponent: StyledRect {
                        implicitWidth: wallLoadingIndicator.implicitSize + Tokens.padding.largeIncreased * 2
                        implicitHeight: wallLoadingIndicator.implicitSize + Tokens.padding.largeIncreased * 2

                        color: Colours.palette.m3primaryContainer
                        radius: Tokens.rounding.full

                        LoadingIndicator {
                            id: wallLoadingIndicator

                            anchors.centerIn: parent
                            containsIcon: true
                            implicitSize: Math.min(wallWrapper.implicitWidth, wallWrapper.implicitHeight) * 0.4
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                Timer {
                    id: wallLoadDebounceTimer

                    interval: 100
                    onTriggered: {
                        if (wallImg.status !== Image.Ready)
                            wallIndicatorLoader.opacity = 1;
                    }
                }

                FadeImage {
                    id: wallImg

                    anchors.fill: parent
                    source: Wallpapers.current
                    preventInit: wallIndicatorLoader.opacity > 0
                    fadeOutAnim: Anim.DefaultEffects
                    fadeInAnim: Anim.SlowEffects

                    onSourceChanged: wallLoadDebounceTimer.restart()

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            wallLoadDebounceTimer.stop();
                            wallIndicatorLoader.opacity = 0;
                        }
                    }
                }
            }
        }

        ButtonRow {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Tokens.spacing.large
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "wallpaper"
                text: qsTr("Wallpapers")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                disabled: !Config.background.wallpaperEnabled
                onClicked: root.nState.openSubPage(1) // Wallpaper page
            }

            IconTextButton {
                icon: "palette"
                text: qsTr("Colours")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                onClicked: root.nState.openSubPage(3) // Colours page
            }
        }

        SectionHeader {
            text: qsTr("Wallpaper")
        }

        ToggleRow {
            first: true
            last: true
            text: qsTr("Display wallpaper")
            checked: Config.background.wallpaperEnabled
            onToggled: GlobalConfig.background.wallpaperEnabled = checked
        }

        SectionHeader {
            text: qsTr("Theme Mode & Transparency")
        }

        ToggleRow {
            first: true
            text: qsTr("Dark theme")
            checked: !Colours.light
            disabled: !root.supportsLightMode
            subtext: root.supportsLightMode ? "" : qsTr("Active scheme only supports dark mode")
            onToggled: Colours.setMode(checked ? "dark" : "light")
        }

        ToggleRow {
            last: true
            text: qsTr("Transparency")
            subtext: qsTr("Enable blur/transparency on shell components")
            checked: Colours.transparency.enabled
            onToggled: GlobalConfig.appearance.transparency.enabled = checked
        }

        SectionHeader {
            visible: Colours.transparency.enabled
            text: qsTr("Transparency Levels")
        }

        SliderRow {
            visible: Colours.transparency.enabled
            first: true
            icon: "opacity"
            label: qsTr("Base opacity")
            valueLabel: Math.round(value * 100) + "%"
            value: Colours.transparency.base
            onMoved: v => GlobalConfig.appearance.transparency.base = v
        }

        SliderRow {
            visible: Colours.transparency.enabled
            last: true
            icon: "layers"
            label: qsTr("Layers opacity")
            valueLabel: Math.round(value * 100) + "%"
            value: Colours.transparency.layers
            onMoved: v => GlobalConfig.appearance.transparency.layers = v
        }

        SectionHeader {
            text: qsTr("Background Components")
        }

        ToggleRow {
            first: true
            last: !Config.background.desktopClock.enabled
            text: qsTr("Desktop clock")
            subtext: qsTr("Show a clock on the desktop background")
            checked: Config.background.desktopClock.enabled
            onToggled: GlobalConfig.background.desktopClock.enabled = checked
        }

        ToggleRow {
            visible: Config.background.desktopClock.enabled
            text: qsTr("Lock clock position")
            subtext: checked ? qsTr("Clock position is locked") : qsTr("Drag clock on desktop to reposition")
            checked: Time.clockLockPosition
            onToggled: Time.clockLockPosition = checked
        }

        ToggleRow {
            visible: Config.background.desktopClock.enabled
            text: qsTr("Use 24-hour format")
            subtext: checked ? qsTr("Display time in 24h format") : qsTr("Display time in 12h format")
            checked: Time.clockTimeFormat === "24h"
            onToggled: Time.clockTimeFormat = checked ? "24h" : "12h"
        }

        ToggleRow {
            visible: Config.background.desktopClock.enabled && Time.clockTimeFormat === "12h"
            text: qsTr("Show AM/PM indicator")
            checked: Time.clockShowAmPm
            onToggled: Time.clockShowAmPm = checked
        }

        RowButton {
            visible: Config.background.desktopClock.enabled
            text: qsTr("Reset Desktop Clock")
            subtext: qsTr("Restore default position, scale, and time formats")
            icon: "restart_alt"
            onClicked: {
                Time.clockOffsetX = 0;
                Time.clockOffsetY = 0;
                Time.clockHasCustomPosition = false;
                Time.clockCustomScale = 1.0;
                Time.clockTimeFormat = "12h";
                Time.clockShowAmPm = true;
                Time.clockLockPosition = true;
            }
        }

        ToggleRow {
            last: true
            text: qsTr("Audio visualiser")
            subtext: qsTr("Show an interactive audio visualiser on the desktop background")
            checked: Config.background.visualiser.enabled
            onToggled: GlobalConfig.background.visualiser.enabled = checked
        }
    }
}
