pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Nilastia.Components
import Nilastia.Config
import qs.components
import qs.components.controls
import qs.components.images
import qs.components.filedialog
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Wallpaper & style")

    readonly property bool supportsLightMode: [
        "dynamic", "nilastia", "gruvbox", "everforest", "catppuccin", "rosepine",
        "angel", "fieldsoftheshire", "vitesse", "sakura", "zengarden"
    ].includes(Colours.scheme)

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
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
            last: !Config.background.backdropEnabled
            text: qsTr("Display wallpaper")
            checked: Config.background.wallpaperEnabled
            onToggled: GlobalConfig.background.wallpaperEnabled = checked
        }

        SectionHeader {
            visible: Config.background.wallpaperEnabled
            text: qsTr("Overview Backdrop")
        }

        ToggleRow {
            visible: Config.background.wallpaperEnabled
            first: true
            last: !Config.background.backdropEnabled
            text: qsTr("Enable overview backdrop")
            subtext: qsTr("Show a backdrop wallpaper when entering overview mode")
            checked: Config.background.backdropEnabled
            onToggled: GlobalConfig.background.backdropEnabled = checked
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: Config.background.wallpaperEnabled && Config.background.backdropEnabled
            spacing: Tokens.spacing.extraSmall / 2

            ToggleRow {
                text: qsTr("Use main wallpaper")
                subtext: qsTr("Use the same image as the desktop wallpaper")
                checked: Config.background.backdropUseMainWallpaper
                onToggled: GlobalConfig.background.backdropUseMainWallpaper = checked
            }

            ToggleRow {
                text: qsTr("Hide main wallpaper")
                subtext: qsTr("Permanently show the blurred backdrop on the desktop")
                checked: Config.background.backdropHideWallpaper
                onToggled: GlobalConfig.background.backdropHideWallpaper = checked
            }

            RowButton {
                visible: !Config.background.backdropUseMainWallpaper
                text: qsTr("Select backdrop wallpaper")
                subtext: Config.background.backdropWallpaperPath ? Config.background.backdropWallpaperPath.split("/").pop() : qsTr("No custom backdrop selected")
                icon: "wallpaper"

                FileDialog {
                    id: backdropDialog
                    title: qsTr("Select backdrop image")
                    filterLabel: qsTr("Image files")
                    filters: Images.validImageExtensions
                    onAccepted: path => GlobalConfig.background.backdropWallpaperPath = path
                }
                onClicked: backdropDialog.open()
            }

            StepperRow {
                label: qsTr("Backdrop blur strength")
                subtext: qsTr("Apply blur effect to the backdrop (px)")
                value: Math.round(Config.background.backdropBlurRadius)
                from: 0
                to: 64
                stepSize: 4
                onMoved: (value) => GlobalConfig.background.backdropBlurRadius = Math.round(value)
            }

            StepperRow {
                label: qsTr("Backdrop dim strength")
                subtext: qsTr("Fade the backdrop towards dark (%)")
                value: Math.round(Config.background.backdropDim)
                from: 0
                to: 100
                stepSize: 5
                onMoved: (value) => GlobalConfig.background.backdropDim = Math.round(value)
            }

            ToggleRow {
                text: qsTr("Enable vignette effect")
                subtext: qsTr("Apply a dark border vignette overlay")
                checked: Config.background.backdropVignetteEnabled
                onToggled: GlobalConfig.background.backdropVignetteEnabled = checked
            }

            StepperRow {
                visible: Config.background.backdropVignetteEnabled
                label: qsTr("Vignette intensity")
                subtext: qsTr("Darkness of the vignette border (%)")
                value: Math.round(Config.background.backdropVignetteIntensity * 100)
                from: 10
                to: 100
                stepSize: 5
                onMoved: (value) => GlobalConfig.background.backdropVignetteIntensity = value / 100.0
            }

            StepperRow {
                visible: Config.background.backdropVignetteEnabled
                last: true
                label: qsTr("Vignette radius")
                subtext: qsTr("Size of the clear center region (%)")
                value: Math.round(Config.background.backdropVignetteRadius * 100)
                from: 10
                to: 90
                stepSize: 5
                onMoved: (value) => GlobalConfig.background.backdropVignetteRadius = value / 100.0
            }
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
