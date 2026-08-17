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
    readonly property bool hasClockLayer: root.wallpaperType === "parallax" && root.parallaxConfig !== null && JSON.stringify(root.parallaxConfig).includes("virtual://clock")

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
    readonly property bool wallpaperCovered: Hypr.activeToplevel !== null && !Hypr.activeToplevel.lastIpcObject.floating && !Hypr.inOverview
    readonly property bool videoPaused: wallpaperCovered || (Config.background.pauseLiveWallpaperOnBattery && UPower.onBattery)

    // Parallax configuration parsing using Quickshell's FileView
    property var parallaxConfig: null
    readonly property real intensity: root.parallaxConfig?.parallax?.intensity !== undefined ? root.parallaxConfig?.parallax?.intensity : 1.0
    property string basePath: ""

    FileView {
        id: parallaxConfigReader
        path: root.checkIsParallax(root.source) ? root.source : ""
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
        SpringAnimation {
            spring: root.parallaxConfig?.parallax?.spring?.stiffness ?? 12.0
            damping: root.parallaxConfig?.parallax?.spring?.damping ?? 0.8
            epsilon: 0.0005
        }
    }

    Behavior on inputY {
        SpringAnimation {
            spring: root.parallaxConfig?.parallax?.spring?.stiffness ?? 12.0
            damping: root.parallaxConfig?.parallax?.spring?.damping ?? 0.8
            epsilon: 0.0005
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

    // --- Mouse Area for Tracking ---
    MouseArea {
        id: mouseTracker
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton // Passthrough clicks to items below
        
        onPositionChanged: {
            if (root.wallpaperType === "parallax" && !root.wallpaperCovered && !(Config.background.pauseLiveWallpaperOnBattery && UPower.onBattery)) {
                let cx = width / 2;
                let cy = height / 2;
                root.targetX = (mouseX - cx) / cx;
                root.targetY = (mouseY - cy) / cy;
            }
        }
        
        onExited: {
            root.targetX = 0;
            root.targetY = 0;
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
                active: modelData !== undefined
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
                anchors.fill: parent
                path: modelData && modelData.source ? (modelData.source.startsWith("data:") ? modelData.source : root.basePath + modelData.source) : ""

                // Parallax displacement math
                readonly property real depth: modelData && modelData.depth !== undefined ? modelData.depth : 0.5
                readonly property real sensitivity: modelData && modelData.sensitivity !== undefined ? modelData.sensitivity : 1.0

                 readonly property real dispX: (root.inputX + root.idleX) * depth * sensitivity * root.intensity * (root.parallaxConfig?.parallax?.maxDisplacementX ?? 35)
                readonly property real dispY: (root.inputY + root.idleY) * depth * sensitivity * root.intensity * (root.parallaxConfig?.parallax?.maxDisplacementY ?? 20)

                transform: Translate {
                    x: dispX
                    y: dispY
                }

                // Constant scale factor to hide borders smoothly
                scale: 1.05
            }
        }

        Component {
            id: clockLayerComponent
            Item {
                property var modelData
                anchors.fill: parent

                readonly property real depth: modelData && modelData.depth !== undefined ? modelData.depth : 0.5
                readonly property real sensitivity: modelData && modelData.sensitivity !== undefined ? modelData.sensitivity : 1.0

                readonly property real dispX: (root.inputX + root.idleX) * depth * sensitivity * root.intensity * (root.parallaxConfig?.parallax?.maxDisplacementX ?? 35)
                readonly property real dispY: (root.inputY + root.idleY) * depth * sensitivity * root.intensity * (root.parallaxConfig?.parallax?.maxDisplacementY ?? 20)

                Loader {
                    id: embeddedClockLoader
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
                        if (pos.endsWith("left")) return leftMargin;
                        if (pos.endsWith("center")) return (parent.width - width) / 2;
                        if (pos.endsWith("right")) return parent.width - width - defaultMargin;
                        return defaultMargin;
                    }

                    y: {
                        if (Time.clockHasCustomPosition) {
                            return Time.clockOffsetY;
                        }
                        let pos = Config.background.desktopClock.position;
                        if (pos.startsWith("top")) return defaultMargin;
                        if (pos.startsWith("middle")) return (parent.height - height) / 2;
                        if (pos.startsWith("bottom")) return parent.height - height - defaultMargin;
                        return defaultMargin;
                    }

                    sourceComponent: DesktopClock {
                        wallpaper: root.parent // parent behind clock
                        absX: embeddedClockLoader.x + dispX
                        absY: embeddedClockLoader.y + dispY
                    }
                }

                transform: Translate {
                    x: dispX
                    y: dispY
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
