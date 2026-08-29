import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Nilastia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.utils

Item {
    id: root

    // Variants 1: Wallpaper Backdrop (drawn behind workspaces in Niri overview, ignores input)
    Variants {
        id: wallpaperVariants
        model: Screens.screens.filter(s => GlobalConfig.forScreen(s.name).background.enabled)

        StyledWindow {
            id: wallpaperWin

            required property ShellScreen modelData

            screen: modelData
            name: "background-wallpaper"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            color: contentItem.Config.background.wallpaperEnabled ? "black" : "transparent"
            surfaceFormat.opaque: false

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            ShellState.ComponentRef {
                screen: wallpaperWin.screen
                slot: "wallpaperItem"
                component: desktopWallpaper
            }

            Item {
                anchors.fill: parent

                Loader {
                    id: desktopWallpaper

                    asynchronous: true
                    anchors.fill: parent
                    active: Config.background.wallpaperEnabled

                    sourceComponent: Wallpaper {}
                }

                Loader {
                    id: backdropLoader

                    asynchronous: true
                    anchors.fill: parent
                    active: Config.background.wallpaperEnabled

                    opacity: (Config.background.backdropHideWallpaper || (Config.background.backdropEnabled && Hypr.inOverview)) ? 1.0 : 0.0
                    visible: opacity > 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.SlowEffects
                        }
                    }

                    sourceComponent: Item {
                        id: backdropItem
                        anchors.fill: parent

                        onOpacityChanged: console.log("DEBUG: backdrop opacity changed to:", opacity, "hideWallpaper:", Config.background.backdropHideWallpaper, "backdropEnabled:", Config.background.backdropEnabled, "inOverview:", Hypr.inOverview)

                        readonly property real vignetteRadius: Config.background.backdropVignetteRadius
                        readonly property real vignetteIntensity: Config.background.backdropVignetteIntensity
                        readonly property bool vignetteEnabled: Config.background.backdropVignetteEnabled

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
            }
        }
    }

    // Variants 2: Desktop Widgets & Clock (fully interactive Bottom layer, hidden in overview)
    Variants {
        id: widgetsVariants
        model: Screens.screens.filter(s => GlobalConfig.forScreen(s.name).background.enabled)

        StyledWindow {
            id: win

            required property ShellScreen modelData

            screen: modelData
            name: "background"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom
            color: "transparent"
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

                MouseArea {
                    id: desktopMouseTracker
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    propagateComposedEvents: true

                    onPositionChanged: mouse => {
                        const cx = width / 2;
                        const cy = height / 2;
                        const comp = ShellState.componentsFor(win.screen);
                        const wp = comp ? comp.wallpaperItem : null;
                        if (wp && wp.item) {
                            const tx = (mouse.x - cx) / cx;
                            const ty = (mouse.y - cy) / cy;
                            wp.item.targetX = tx;
                            wp.item.targetY = ty;
                        }
                    }

                    onExited: {
                        const comp = ShellState.componentsFor(win.screen);
                        const wp = comp ? comp.wallpaperItem : null;
                        if (wp && wp.item) {
                            wp.item.targetX = 0;
                            wp.item.targetY = 0;
                        }
                    }
                }

                Visualiser {
                    anchors.fill: parent
                    screen: win.modelData
                    wallpaper: {
                        const comp = ShellState.componentsFor(win.screen);
                        return comp ? comp.wallpaperItem : null;
                    }
                }

                Item {
                    id: fpsTracker

                    FrameAnimation {
                        id: fpsAnimation
                        running: true
                        property int frameCount: 0
                        property int fps: 0

                        onTriggered: {
                            frameCount++;
                        }
                    }

                    Timer {
                        interval: 1000
                        repeat: true
                        running: true
                        onTriggered: {
                            fpsAnimation.fps = fpsAnimation.frameCount;
                            fpsAnimation.frameCount = 0;
                            console.log("SHELL_FPS:", fpsAnimation.fps);
                        }
                    }
                }
            }

            Loader {
                id: clockLoader

                asynchronous: true
                active: {
                    const comp = ShellState.componentsFor(win.screen);
                    const wp = comp ? comp.wallpaperItem : null;
                    return Config.background.desktopClock.enabled && !(wp && wp.item && wp.item.hasClockLayer);
                }

                readonly property real defaultMargin: Tokens.padding.extraLargeIncreased
                readonly property real leftMargin: defaultMargin + Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, Config.border.thickness)

                width: item ? item.implicitWidth : 0
                height: item ? item.implicitHeight : 0

                anchors.left: !Time.clockHasCustomPosition && Config.background.desktopClock.position.endsWith("left") ? parent.left : undefined
                anchors.right: !Time.clockHasCustomPosition && Config.background.desktopClock.position.endsWith("right") ? parent.right : undefined
                anchors.horizontalCenter: !Time.clockHasCustomPosition && Config.background.desktopClock.position.endsWith("center") ? parent.horizontalCenter : undefined

                anchors.top: !Time.clockHasCustomPosition && Config.background.desktopClock.position.startsWith("top") ? parent.top : undefined
                anchors.bottom: !Time.clockHasCustomPosition && Config.background.desktopClock.position.startsWith("bottom") ? parent.bottom : undefined
                anchors.verticalCenter: !Time.clockHasCustomPosition && Config.background.desktopClock.position.startsWith("middle") ? parent.verticalCenter : undefined

                anchors.leftMargin: leftMargin
                anchors.rightMargin: defaultMargin
                anchors.topMargin: defaultMargin
                anchors.bottomMargin: defaultMargin

                x: Time.clockHasCustomPosition ? Time.clockOffsetX : undefined
                y: Time.clockHasCustomPosition ? Time.clockOffsetY : undefined

                sourceComponent: DesktopClock {
                    wallpaper: behindClock
                    absX: clockLoader.x
                    absY: clockLoader.y
                }
            }
        }
    }
}
