import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Nilastia.Config
import qs.components
import qs.components.containers
import qs.components.images
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
                        layer.textureSize: Qt.size(width / 4, height / 4)
                        layer.smooth: true
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
                            const rawTx = Math.max(-1.0, Math.min(1.0, (mouse.x - cx) / cx));
                            const rawTy = Math.max(-1.0, Math.min(1.0, (mouse.y - cy) / cy));
                            // High-response curve: preserves sign while boosting center sensitivity
                            const tx = Math.sign(rawTx) * Math.pow(Math.abs(rawTx), 0.7);
                            const ty = Math.sign(rawTy) * Math.pow(Math.abs(rawTy), 0.7);
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

                // Debug FPS tracker removed for performance optimization
            }

            Loader {
                id: clockLoader

                asynchronous: true
                active: {
                    const comp = ShellState.componentsFor(win.screen);
                    const wp = comp ? comp.wallpaperItem : null;
                    return Config.background.desktopClock.enabled || (wp && wp.item && wp.item.hasClockLayer);
                }

                readonly property var clockLayerData: {
                    const comp = ShellState.componentsFor(win.screen);
                    const wp = comp ? comp.wallpaperItem : null;
                    if (wp && wp.item && wp.item.parallaxConfig && wp.item.parallaxConfig.parallax && wp.item.parallaxConfig.parallax.layers) {
                        return wp.item.parallaxConfig.parallax.layers.find(l => l.source === "virtual://clock");
                    }
                    return null;
                }
                readonly property real clockDepth: clockLayerData && clockLayerData.depth !== undefined ? clockLayerData.depth : 0.25
                readonly property real clockSensitivity: clockLayerData && clockLayerData.sensitivity !== undefined ? clockLayerData.sensitivity : 1.0

                transform: Translate {
                    x: {
                        const comp = ShellState.componentsFor(win.screen);
                        const wp = comp ? comp.wallpaperItem : null;
                        if (wp && wp.item && wp.item.wallpaperType === "parallax") {
                            return wp.item.globalParallaxX * clockLoader.clockDepth * clockLoader.clockSensitivity;
                        }
                        return 0;
                    }
                    y: {
                        const comp = ShellState.componentsFor(win.screen);
                        const wp = comp ? comp.wallpaperItem : null;
                        if (wp && wp.item && wp.item.wallpaperType === "parallax") {
                            return wp.item.globalParallaxY * clockLoader.clockDepth * clockLoader.clockSensitivity;
                        }
                        return 0;
                    }
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

                x: Time.clockHasCustomPosition ? Time.clockOffsetX : 0
                y: Time.clockHasCustomPosition ? Time.clockOffsetY : 0

                sourceComponent: DesktopClock {
                    wallpaper: behindClock
                    absX: clockLoader.x
                    absY: clockLoader.y
                }
            }

            // Foreground Parallax Layers (rendered strictly on top of DesktopClock on WlrLayer.Bottom)
            Item {
                id: foregroundLayersContainer
                anchors.fill: parent
                z: 1
                enabled: false // Mouse clicks & drags pass directly through to DesktopClock below

                readonly property var wpItem: {
                    const comp = ShellState.componentsFor(win.screen);
                    return comp && comp.wallpaperItem ? comp.wallpaperItem.item : null;
                }

                visible: wpItem && wpItem.wallpaperType === "parallax" && !wpItem.wallpaperCovered && (wpItem.foregroundLayers?.length > 0) && (opacity > 0)
                opacity: (Config.background.backdropHideWallpaper || (Config.background.backdropEnabled && Hypr.inOverview)) ? 0.0 : 1.0
                Behavior on opacity { Anim { type: Anim.SlowEffects } }

                Repeater {
                    model: foregroundLayersContainer.wpItem ? foregroundLayersContainer.wpItem.foregroundLayers : []
                    delegate: CachingImage {
                        id: fgLayerImg
                        required property var modelData
                        required property int index

                        width: foregroundLayersContainer.width
                        height: foregroundLayersContainer.height
                        path: {
                            if (!modelData || !modelData.source) return "";
                            if (modelData.source.startsWith("data:")) return modelData.source;
                            const wp = foregroundLayersContainer.wpItem;
                            return (wp ? wp.basePath : "") + modelData.source;
                        }

                        // Parallax displacement math matching Wallpaper.qml
                        readonly property real depth: modelData && modelData.depth !== undefined ? modelData.depth : 0.5
                        readonly property real sensitivity: modelData && modelData.sensitivity !== undefined ? modelData.sensitivity : 1.0

                        transform: Translate {
                            x: {
                                const wp = foregroundLayersContainer.wpItem;
                                return (wp ? wp.globalParallaxX : 0) * fgLayerImg.depth * fgLayerImg.sensitivity;
                            }
                            y: {
                                const wp = foregroundLayersContainer.wpItem;
                                return (wp ? wp.globalParallaxY : 0) * fgLayerImg.depth * fgLayerImg.sensitivity;
                            }
                        }

                        scale: 1.12
                    }
                }
            }
        }
    }
}
