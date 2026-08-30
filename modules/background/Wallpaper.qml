pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import Quickshell.Io
import Quickshell.Services.UPower
import Nilastia.Config
import qs.components
import qs.components.filedialog
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    property string source: Wallpapers.current
    property CachingImage current
    property bool completed
    readonly property bool hasClockLayer: {
        if (root.wallpaperType !== "parallax" || root.parallaxConfig === null || !root.parallaxConfig.parallax || !root.parallaxConfig.parallax.layers) return false;
        const layers = root.parallaxConfig.parallax.layers;
        for (let i = 0; i < layers.length; i++) {
            if (layers[i].source === "virtual://clock") return true;
        }
        return false;
    }

    // Helper functions to resolve types inline to avoid QML binding race conditions
    function checkIsVideo(path) {
        if (!path) return false;
        let lower = path.toLowerCase();
        return lower.endsWith(".mp4") || lower.endsWith(".webm") || lower.endsWith(".mkv") || lower.endsWith(".mov");
    }

    function checkIsParallax(path) {
        if (!path) return false;
        let lower = path.toLowerCase();
        return lower.endsWith("wallpaper.json") || lower.endsWith(".nilawall");
    }

    function checkIsGif(path) {
        if (!path) return false;
        return path.toLowerCase().endsWith(".gif");
    }

    readonly property string wallpaperType: {
        if (!source) return "none";
        if (checkIsGif(source)) return "gif";
        if (checkIsVideo(source)) return "video";
        if (checkIsParallax(source)) return "parallax";
        return "static";
    }

    // Fullscreen/Covered detection for energy savings (0 FPS when covered)
    readonly property bool wallpaperCovered: Hypr.activeToplevel !== null && Hypr.activeToplevel.lastIpcObject.fullscreen > 0 && !Hypr.inOverview
    readonly property bool videoPaused: wallpaperCovered || (Config.background.pauseLiveWallpaperOnBattery && UPower.onBattery)





    // Parallax configuration parsing using Quickshell's FileView
    property var parallaxConfig: null
    readonly property real intensity: root.parallaxConfig?.parallax?.intensity !== undefined ? root.parallaxConfig?.parallax?.intensity : 1.0
    readonly property real targetIntensity: Hypr.anyWindowVisible ? 0.0 : root.intensity
    property real activeIntensity: targetIntensity
    Behavior on activeIntensity {
        NumberAnimation {
            duration: 800
            easing.type: Easing.OutCubic
        }
    }
    readonly property int glideDuration: root.parallaxConfig?.parallax?.animation?.duration !== undefined ? root.parallaxConfig?.parallax?.animation?.duration : 800
    property string basePath: ""
    readonly property real globalParallaxX: (root.inputX + root.idleX + root.transitionX) * root.activeIntensity * (root.parallaxConfig?.parallax?.maxDisplacementX ?? 35)
    readonly property real globalParallaxY: (root.inputY + root.idleY + root.transitionY) * root.activeIntensity * (root.parallaxConfig?.parallax?.maxDisplacementY ?? 20)

    FileView {
        id: parallaxConfigReader
        path: root.checkIsParallax(root.source) ? root.source : ""
        watchChanges: true
        onFileChanged: reload()
        printErrors: false
        
        onLoaded: {
            try {
                let jsonText = text();
                root.parallaxConfig = JSON.parse(jsonText);
                
                let idx = root.source.lastIndexOf("/");
                root.basePath = idx >= 0 ? root.source.slice(0, idx + 1) : "";
                
                console.log("DEBUG: parsed parallax config via FileView: layers =", root.parallaxConfig.parallax?.layers?.length);
            } catch (e) {
                console.error("Failed to parse parallax config JSON:", e);
                root.parallaxConfig = null;
                root.basePath = "";
            }
        }
        
        onLoadFailed: {
            console.error("Failed to load parallax file via FileView:", path);
            root.parallaxConfig = null;
            root.basePath = "";
        }
    }

    onSourceChanged: {
        let isStatic = source && !checkIsVideo(source) && !checkIsParallax(source) && !checkIsGif(source);
        if (isStatic) {
            if (!current || current.path !== source) {
                // Destroy old to prevent overlay
                if (current) current.destroy();
                current = imgComp.createObject(root, {
                    path: source
                });
            }
        } else {
            if (current) {
                current.destroy();
                current = null;
            }
        }
        completed = true;
    }

    Component.onCompleted: {
        let isStatic = source && !checkIsVideo(source) && !checkIsParallax(source) && !checkIsGif(source);
        if (isStatic) {
            Qt.callLater(() => {
                if (!current) {
                    current = imgComp.createObject(root, {
                        path: source
                    });
                }
                completed = true;
            });
        } else {
            completed = true;
        }
    }

    // --- Inputs for Parallax ---
    property real targetX: 0
    property real targetY: 0
    property real inputX: targetX
    property real inputY: targetY

    Behavior on inputX {
        NumberAnimation {
            duration: root.glideDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on inputY {
        NumberAnimation {
            duration: root.glideDuration
            easing.type: Easing.OutCubic
        }
    }

    // Transition shifts to animate when launcher/dashboard/overview opens (Option B)
    readonly property real targetTransitionX: {
        const screenState = ShellState.forActive();
        if (!screenState) return 0.0;
        return (screenState.launcher ? 0.35 : 0.0) + (screenState.dashboard ? -0.25 : 0.0) + (screenState.overview ? 0.15 : 0.0);
    }
    readonly property real targetTransitionY: {
        const screenState = ShellState.forActive();
        if (!screenState) return 0.0;
        return (screenState.launcher ? 0.15 : 0.0) + (screenState.dashboard ? 0.1 : 0.0) + (screenState.overview ? -0.1 : 0.0);
    }

    property real transitionX: targetTransitionX
    property real transitionY: targetTransitionY

    Behavior on transitionX {
        NumberAnimation {
            duration: root.glideDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on transitionY {
        NumberAnimation {
            duration: root.glideDuration
            easing.type: Easing.OutCubic
        }
    }

    // Subtle idle floating camera animation
    property real idleX: 0
    property real idleY: 0

    SequentialAnimation on idleX {
        loops: Animation.Infinite
        running: root.wallpaperType === "parallax" && !root.wallpaperCovered && !(Config.background.pauseLiveWallpaperOnBattery && UPower.onBattery)

        NumberAnimation {
            from: -0.35
            to: 0.35
            duration: 15000
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            from: 0.35
            to: -0.35
            duration: 15000
            easing.type: Easing.InOutSine
        }
    }

    SequentialAnimation on idleY {
        loops: Animation.Infinite
        running: root.wallpaperType === "parallax" && !root.wallpaperCovered && !(Config.background.pauseLiveWallpaperOnBattery && UPower.onBattery)

        NumberAnimation {
            from: -0.22
            to: 0.22
            duration: 12000
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            from: 0.22
            to: -0.22
            duration: 12000
            easing.type: Easing.InOutSine
        }
    }





    // --- Renderer 1: Static Image ---
    // Rendered via dynamically created CachingImage (current)

    // --- Renderer 2: Video Mode ---
    Item {
        id: videoContainer
        anchors.fill: parent
        visible: root.wallpaperType === "video"
        opacity: visible ? 1 : 0
        Behavior on opacity { Anim { type: Anim.SlowEffects } }

        Loader {
            anchors.fill: parent
            active: root.wallpaperType === "video"
            
            sourceComponent: VideoOutput {
                id: videoOutput
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectCrop

                MediaPlayer {
                    id: player
                    source: "file://" + root.source
                    videoOutput: videoOutput
                    loops: MediaPlayer.Infinite
                    
                    Component.onCompleted: {
                        if (!root.videoPaused) {
                            player.play();
                        }
                    }
                }

                Connections {
                    target: root
                    function onVideoPausedChanged() {
                        if (root.videoPaused) {
                            player.pause();
                        } else {
                            player.play();
                        }
                    }
                }
            }
        }
    }

    // --- Renderer 3: Parallax Mode ---
    Item {
        id: parallaxContainer
        anchors.fill: parent
        visible: root.wallpaperType === "parallax" && root.parallaxConfig !== null
        opacity: visible ? 1 : 0
        Behavior on opacity { Anim { type: Anim.SlowEffects } }

        Repeater {
            model: root.parallaxConfig?.parallax?.layers ?? []
            delegate: Loader {
                id: liveLayerLoader
                required property var modelData
                required property int index

                anchors.fill: parent
                active: modelData !== undefined && (modelData.source !== "virtual://clock" || Time.clockLockPosition)
                sourceComponent: modelData && modelData.source === "virtual://clock" ? clockLayerComponent : imageLayerComponent

                Binding {
                    target: liveLayerLoader.item
                    property: "modelData"
                    value: liveLayerLoader.modelData
                }
            }
        }

        Component {
            id: imageLayerComponent
            CachingImage {
                property var modelData
                width: parent.width
                height: parent.height
                path: modelData && modelData.source ? (modelData.source.startsWith("data:") ? modelData.source : root.basePath + modelData.source) : ""

                // Parallax displacement math
                readonly property real depth: modelData && modelData.depth !== undefined ? modelData.depth : 0.5
                readonly property real sensitivity: modelData && modelData.sensitivity !== undefined ? modelData.sensitivity : 1.0

                // Use pre-calculated global offsets directly on X and Y positions
                x: root.globalParallaxX * depth * sensitivity
                y: root.globalParallaxY * depth * sensitivity

                // Constant scale factor to hide borders smoothly
                scale: 1.05
            }
        }

        Component {
            id: clockLayerComponent
            Item {
                id: clockLayerItem
                property var modelData
                width: parent.width
                height: parent.height

                readonly property real depth: modelData && modelData.depth !== undefined ? modelData.depth : 0.5
                readonly property real sensitivity: modelData && modelData.sensitivity !== undefined ? modelData.sensitivity : 1.0

                readonly property real dispX: root.globalParallaxX * depth * sensitivity
                readonly property real dispY: root.globalParallaxY * depth * sensitivity

                x: dispX
                y: dispY

                Loader {
                    id: embeddedClockLoader
                    asynchronous: true
                    active: Config.background.desktopClock.enabled

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
                        wallpaper: root.parent // parent behind clock
                        absX: embeddedClockLoader.x + dispX
                        absY: embeddedClockLoader.y + dispY
                    }
                }
            }
        }
    }

    // --- Renderer 4: Animated GIF ---
    Item {
        id: gifContainer
        anchors.fill: parent
        visible: root.wallpaperType === "gif"
        opacity: visible ? 1 : 0
        Behavior on opacity { Anim { type: Anim.SlowEffects } }

        Loader {
            anchors.fill: parent
            active: root.wallpaperType === "gif"

            sourceComponent: AnimatedImage {
                anchors.fill: parent
                source: "file://" + root.source
                fillMode: AnimatedImage.PreserveAspectCrop
                
                // Stop animating when covered or battery saver is active
                playing: !root.wallpaperCovered && !(Config.background.pauseLiveWallpaperOnBattery && UPower.onBattery)
            }
        }
    }

    // Fallback UI if wallpaper missing
    Loader {
        asynchronous: true
        anchors.fill: parent
        active: root.completed && !root.source

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.largeIncreased

                MaterialIcon {
                    text: "sentiment_stressed"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(5).build()
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: qsTr("Wallpaper missing?")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.builders.large.size(28 * 2).weight(Font.Bold).build()
                    }

                    StyledRect {
                        implicitWidth: selectWallText.implicitWidth + Tokens.padding.extraLargeIncreased
                        implicitHeight: selectWallText.implicitHeight + Tokens.padding.small

                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primary

                        FileDialog {
                            id: dialog

                            title: qsTr("Select a wallpaper (Image, Video, or wallpaper.json)")
                            filterLabel: qsTr("Supported Wallpaper Files")
                            filters: ["jpg", "jpeg", "png", "webp", "gif", "mp4", "webm", "mkv", "json"]
                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onPrimary
                            onClicked: dialog.open()
                        }

                        StyledText {
                            id: selectWallText

                            anchors.centerIn: parent

                            text: qsTr("Set it now!")
                            color: Colours.palette.m3onPrimary
                            font: Tokens.font.body.large
                        }
                    }
                }
            }
        }
    }

    // Component for dynamically spawning static CachingImage objects
    Component {
        id: imgComp

        CachingImage {
            id: img
            anchors.fill: parent
            opacity: 0

            Component.onCompleted: {
                if (status === Image.Ready) {
                    opacity = 1;
                }
            }

            onStatusChanged: {
                if (status === Image.Ready)
                    anim.start();
            }

            Anim on opacity {
                id: anim
                type: Anim.SlowEffects
                running: false
                from: 0
                to: 1
            }

            Timer {
                running: root.current !== img && root.current?.status === Image.Ready
                interval: anim.duration
                onTriggered: img.destroy()
            }
        }
    }
}
