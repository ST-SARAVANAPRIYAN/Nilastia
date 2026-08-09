import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services

Variants {
    model: Screens.screens.filter(s => GlobalConfig.forScreen(s.name).background.enabled)

    StyledWindow {
        id: win

        required property ShellScreen modelData

        screen: modelData
        name: "background"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: contentItem.Config.background.wallpaperEnabled ? WlrLayer.Background : WlrLayer.Bottom
        color: contentItem.Config.background.wallpaperEnabled ? "black" : "transparent"
        surfaceFormat.opaque: false

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        ShellState.ComponentRef {
            screen: win.screen
            slot: "background"
            component: win
        }

        Item {
            id: behindClock

            anchors.fill: parent

            Loader {
                id: wallpaper

                asynchronous: true

                anchors.fill: parent
                active: Config.background.wallpaperEnabled

                sourceComponent: Wallpaper {}
            }

            Loader {
                id: backdropLoader

                asynchronous: true
                anchors.fill: parent
                active: Config.background.wallpaperEnabled && Config.background.backdropEnabled

                sourceComponent: Item {
                    id: backdropItem
                    anchors.fill: parent

                    readonly property real vignetteRadius: Config.background.backdropVignetteRadius
                    readonly property real vignetteIntensity: Config.background.backdropVignetteIntensity
                    readonly property bool vignetteEnabled: Config.background.backdropVignetteEnabled

                    opacity: (Config.background.backdropHideWallpaper || Hypr.inOverview) ? 1.0 : 0.0

                    Behavior on opacity {
                        Anim {
                            type: Anim.SlowEffects
                        }
                    }

                    Wallpaper {
                        id: backdropWallpaper
                        anchors.fill: parent
                        source: (Config.background.backdropUseMainWallpaper || !Config.background.backdropWallpaperPath)
                            ? Wallpapers.current
                            : Config.background.backdropWallpaperPath
                    }

                    layer.enabled: Config.background.backdropBlurRadius > 0
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blurMax: 64
                        blur: Math.min(1.0, Config.background.backdropBlurRadius / 64.0)
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        opacity: Config.background.backdropDim / 100.0
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: backdropItem.vignetteEnabled
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: backdropItem.vignetteRadius; color: "transparent" }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, backdropItem.vignetteIntensity) }
                        }
                    }
                }
            }

            Visualiser {
                anchors.fill: parent
                screen: win.modelData
                wallpaper: wallpaper
            }
        }

        Loader {
            id: clockLoader

            asynchronous: true
            active: Config.background.desktopClock.enabled

            readonly property real defaultMargin: Tokens.padding.extraLargeIncreased
            readonly property real leftMargin: defaultMargin + Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, Config.border.thickness)

            width: item ? item.implicitWidth : 0
            height: item ? item.implicitHeight : 0

            x: {
                if (Time.clockHasCustomPosition) {
                    return Time.clockOffsetX;
                }

                let pos = Config.background.desktopClock.position;
                if (pos.endsWith("left")) {
                    return leftMargin;
                } else if (pos.endsWith("center")) {
                    return (parent.width - width) / 2;
                } else if (pos.endsWith("right")) {
                    return parent.width - width - defaultMargin;
                }
                return defaultMargin;
            }

            y: {
                if (Time.clockHasCustomPosition) {
                    return Time.clockOffsetY;
                }

                let pos = Config.background.desktopClock.position;
                if (pos.startsWith("top")) {
                    return defaultMargin;
                } else if (pos.startsWith("middle")) {
                    return (parent.height - height) / 2;
                } else if (pos.startsWith("bottom")) {
                    return parent.height - height - defaultMargin;
                }
                return defaultMargin;
            }

            sourceComponent: DesktopClock {
                wallpaper: behindClock
                absX: clockLoader.x
                absY: clockLoader.y
            }
        }
    }
}
