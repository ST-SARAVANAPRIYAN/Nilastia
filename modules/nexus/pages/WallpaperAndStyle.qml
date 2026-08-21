pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import QtMultimedia
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

    title: qsTr("Wallpaper & lockscreen")

    readonly property list<MenuItem> lockTimeoutsList: [
        MenuItem { text: qsTr("1 minute"); property int value: 60 },
        MenuItem { text: qsTr("2 minutes"); property int value: 120 },
        MenuItem { text: qsTr("3 minutes"); property int value: 180 },
        MenuItem { text: qsTr("5 minutes"); property int value: 300 },
        MenuItem { text: qsTr("10 minutes"); property int value: 600 },
        MenuItem { text: qsTr("15 minutes"); property int value: 900 },
        MenuItem { text: qsTr("30 minutes"); property int value: 1800 },
        MenuItem { text: qsTr("Never"); property int value: 0 }
    ]

    readonly property list<MenuItem> dpmsTimeoutsList: [
        MenuItem { text: qsTr("1 minute"); property int value: 60 },
        MenuItem { text: qsTr("2 minutes"); property int value: 120 },
        MenuItem { text: qsTr("3 minutes"); property int value: 180 },
        MenuItem { text: qsTr("5 minutes"); property int value: 300 },
        MenuItem { text: qsTr("10 minutes"); property int value: 600 },
        MenuItem { text: qsTr("15 minutes"); property int value: 900 },
        MenuItem { text: qsTr("30 minutes"); property int value: 1800 },
        MenuItem { text: qsTr("Never"); property int value: 0 }
    ]

    readonly property list<MenuItem> suspendTimeoutsList: [
        MenuItem { text: qsTr("5 minutes"); property int value: 300 },
        MenuItem { text: qsTr("10 minutes"); property int value: 600 },
        MenuItem { text: qsTr("15 minutes"); property int value: 900 },
        MenuItem { text: qsTr("30 minutes"); property int value: 1800 },
        MenuItem { text: qsTr("45 minutes"); property int value: 2700 },
        MenuItem { text: qsTr("1 hour"); property int value: 3600 },
        MenuItem { text: qsTr("Never"); property int value: 0 }
    ]

    function getTimeoutItem(list, val) {
        for (let i = 0; i < list.length; i++) {
            if (list[i].value === val) return list[i];
        }
        return list[0];
    }

    function updateIdleTimeout(index, val, idleAction, returnAction) {
        let currentList = JSON.parse(JSON.stringify(GlobalConfig.general.idle.timeouts));
        if (!currentList || currentList.length <= index) return;
        currentList[index].timeout = val;
        currentList[index].enabled = (val > 0);
        if (idleAction) currentList[index].idleAction = idleAction;
        if (returnAction) currentList[index].returnAction = returnAction;
        GlobalConfig.general.idle.timeouts = currentList;
    }

    readonly property bool supportsLightMode: [
        "dynamic", "nilastia", "gruvbox", "everforest", "catppuccin", "rosepine",
        "angel", "fieldsoftheshire", "vitesse", "sakura", "zengarden"
    ].includes(Colours.scheme)

    function checkIsVideo(path) {
        if (!path) return false;
        let p = path.toLowerCase();
        return p.endsWith(".mp4") || p.endsWith(".webm") || p.endsWith(".mkv");
    }

    function checkIsParallax(path) {
        return false;
    }

    property var previewParallaxConfig: null
    property string previewParallaxBasePath: ""



    readonly property list<MenuItem> clockStylesList: [
        MenuItem {
            text: qsTr("Default")
            property string value: "default"
        },
        MenuItem {
            text: qsTr("Pill")
            property string value: "pill"
        },
        MenuItem {
            text: qsTr("Minimal")
            property string value: "minimal"
        },
        MenuItem {
            text: qsTr("Cyber")
            property string value: "cyber"
        }
    ]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        FileView {
            id: previewParallaxConfigReader
            path: root.checkIsParallax(Wallpapers.currentPreviewPath) ? Wallpapers.currentPreviewPath : ""
            watchChanges: true
            printErrors: false
            
            onLoaded: {
                try {
                    let jsonText = text();
                    root.previewParallaxConfig = JSON.parse(jsonText);
                    let idx = path.lastIndexOf("/");
                    root.previewParallaxBasePath = idx >= 0 ? path.slice(0, idx + 1) : "";
                    wallIndicatorLoader.opacity = 0;
                } catch (e) {
                    root.previewParallaxConfig = null;
                    root.previewParallaxBasePath = "";
                }
            }
            
            onLoadFailed: {
                root.previewParallaxConfig = null;
                root.previewParallaxBasePath = "";
            }
        }

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
                        let showLoader = true;
                        if (wallPreviewLoader.item) {
                            if (root.checkIsVideo(Wallpapers.currentPreviewPath)) {
                                if (wallPreviewLoader.item.player && wallPreviewLoader.item.player.playbackState === MediaPlayer.PlayingState) {
                                    showLoader = false;
                                }
                            } else {
                                if (wallPreviewLoader.item.status === Image.Ready) {
                                    showLoader = false;
                                }
                            }
                        }
                        if (showLoader) {
                            wallIndicatorLoader.opacity = 1;
                        }
                    }
                }

                 Loader {
                    id: wallPreviewLoader
                    anchors.fill: parent
                    sourceComponent: root.checkIsVideo(Wallpapers.currentPreviewPath) ? videoPreview : (root.checkIsParallax(Wallpapers.currentPreviewPath) ? parallaxPreview : imagePreview)
                }

                Connections {
                    target: Wallpapers
                    function onCurrentPreviewPathChanged() {
                        wallLoadDebounceTimer.restart();
                    }
                }

                Component {
                    id: parallaxPreview
                    Item {
                        anchors.fill: parent

                        MouseArea {
                            id: previewMouseTracker
                            anchors.fill: parent
                            hoverEnabled: true
                            preventStealing: true
                            
                            property real targetX: 0
                            property real targetY: 0
                            property real inputX: targetX
                            property real inputY: targetY

                            onPositionChanged: {
                                let cx = width / 2;
                                let cy = height / 2;
                                targetX = (mouseX - cx) / cx;
                                targetY = (mouseY - cy) / cy;
                            }

                            onExited: {
                                targetX = 0;
                                targetY = 0;
                            }

                            Behavior on inputX {
                                SpringAnimation {
                                    spring: 20.0
                                    damping: 0.8
                                    epsilon: 0.0001
                                }
                            }

                            Behavior on inputY {
                                SpringAnimation {
                                    spring: 20.0
                                    damping: 0.8
                                    epsilon: 0.0001
                                }
                            }
                        }

                        Repeater {
                            model: root.previewParallaxConfig?.parallax?.layers ?? []
                            delegate: CachingImage {
                                anchors.fill: parent
                                path: modelData && modelData.source ? (modelData.source.startsWith("data:") ? modelData.source : root.previewParallaxBasePath + modelData.source) : ""
                                
                                readonly property real depth: modelData && modelData.depth !== undefined ? modelData.depth : 0.5
                                readonly property real sensitivity: modelData && modelData.sensitivity !== undefined ? modelData.sensitivity : 1.0
                                
                                readonly property real dispX: previewMouseTracker.inputX * depth * sensitivity * 35
                                readonly property real dispY: previewMouseTracker.inputY * depth * sensitivity * 20

                                transform: Translate {
                                    x: dispX
                                    y: dispY
                                }

                                scale: 1.15

                                onStatusChanged: {
                                    if (status === Image.Ready) {
                                        wallLoadDebounceTimer.stop();
                                        wallIndicatorLoader.opacity = 0;
                                    }
                                }
                            }
                        }
                    }
                }

                Component {
                    id: imagePreview
                    FadeImage {
                        anchors.fill: parent
                        source: Wallpapers.currentPreviewPath
                        preventInit: wallIndicatorLoader.opacity > 0
                        fadeOutAnim: Anim.DefaultEffects
                        fadeInAnim: Anim.SlowEffects

                        onStatusChanged: {
                            if (status === Image.Ready) {
                                wallLoadDebounceTimer.stop();
                                wallIndicatorLoader.opacity = 0;
                            }
                        }
                    }
                }

                Component {
                    id: videoPreview
                    VideoOutput {
                        id: videoOutput
                        anchors.fill: parent
                        fillMode: VideoOutput.PreserveAspectCrop

                        property alias player: player

                        MediaPlayer {
                            id: player
                            source: "file://" + Wallpapers.currentPreviewPath
                            videoOutput: videoOutput
                            loops: MediaPlayer.Infinite

                            Component.onCompleted: player.play()

                            onPlaybackStateChanged: {
                                if (playbackState === MediaPlayer.PlayingState) {
                                    wallLoadDebounceTimer.stop();
                                    wallIndicatorLoader.opacity = 0;
                                }
                            }
                        }
                    }
                }
            }
        }

        Flickable {
            id: buttonRowFlickable
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Tokens.spacing.large
            implicitHeight: buttonRow.implicitHeight
            contentWidth: Math.max(width, buttonRow.implicitWidth)
            flickableDirection: Flickable.HorizontalFlick
            clip: true
            interactive: buttonRow.implicitWidth > width

            ButtonRow {
                id: buttonRow
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
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

                IconTextButton {
                    icon: "lock"
                    text: qsTr("Lockscreen")
                    font: Tokens.font.body.large
                    isRound: true
                    shapeMorph: true
                    type: IconTextButton.Tonal
                    horizontalPadding: Tokens.padding.extraLarge
                    verticalPadding: Tokens.padding.medium
                    onClicked: root.nState.openSubPage(6) // Lockscreen page
                }
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
                    title: qsTr("Select backdrop wallpaper (Image, Video, or wallpaper.json)")
                    filterLabel: qsTr("Supported Wallpaper Files")
                    filters: ["jpg", "jpeg", "png", "webp", "gif", "mp4", "webm", "mkv", "json"]
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
            visible: Config.background.wallpaperEnabled
            text: qsTr("Wallpaper Performance")
        }

        ToggleRow {
            visible: Config.background.wallpaperEnabled
            first: true
            last: true
            text: qsTr("Pause live wallpaper on battery")
            subtext: qsTr("Pause GIF, video, and parallax wallpapers when running on battery to save power")
            checked: Config.background.pauseLiveWallpaperOnBattery
            onToggled: GlobalConfig.background.pauseLiveWallpaperOnBattery = checked
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

        SelectRow {
            visible: Config.background.desktopClock.enabled
            label: qsTr("Clock style")
            subtext: qsTr("Select layout style for the desktop wallpaper clock")
            menuItems: root.clockStylesList
            active: {
                const style = Config.background.desktopClock.style.toLowerCase();
                for (let i = 0; i < root.clockStylesList.length; i++) {
                    if (root.clockStylesList[i].value === style) {
                        return root.clockStylesList[i];
                    }
                }
                return root.clockStylesList[0];
            }
            onSelected: item => {
                GlobalConfig.background.desktopClock.style = item.value;
            }
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

        SectionHeader {
            text: qsTr("Lockscreen")
        }

        RowButton {
            first: true
            last: true
            text: qsTr("Lockscreen & Idle Settings")
            subtext: qsTr("Configure screen lock timeout, display power-off, suspend, and gaming rules")
            icon: "lock"
            onClicked: root.nState.openSubPage(6)
        }
    }
}
