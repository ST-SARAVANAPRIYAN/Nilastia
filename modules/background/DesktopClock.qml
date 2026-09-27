pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Nilastia.Config
import qs.components
import qs.services

Item {
    id: root

    required property Item wallpaper
    required property real absX
    required property real absY

    property real clockScale: Time.clockCustomScale
    readonly property bool bgEnabled: Config.background.desktopClock.background.enabled
    readonly property bool blurEnabled: bgEnabled && Config.background.desktopClock.background.blur && !GameMode.enabled
    readonly property bool invertColors: Config.background.desktopClock.invertColors
    readonly property bool useLightSet: Colours.light ? !invertColors : invertColors
    readonly property color safePrimary: useLightSet ? Colours.palette.m3primaryContainer : Colours.palette.m3primary
    readonly property color safeSecondary: useLightSet ? Colours.palette.m3secondaryContainer : Colours.palette.m3secondary
    readonly property color safeTertiary: useLightSet ? Colours.palette.m3tertiaryContainer : Colours.palette.m3tertiary

    implicitWidth: (styleLoader.item ? styleLoader.item.implicitWidth : 350) + (Tokens.padding.large * 4 * root.clockScale)
    implicitHeight: (styleLoader.item ? styleLoader.item.implicitHeight : 150) + (Tokens.padding.extraLargeIncreased * root.clockScale)

    width: implicitWidth
    height: implicitHeight

    Item {
        id: clockContainer

        anchors.fill: parent

        layer.enabled: Config.background.desktopClock.shadow.enabled
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Colours.palette.m3shadow
            shadowOpacity: Config.background.desktopClock.shadow.opacity
            shadowBlur: Config.background.desktopClock.shadow.blur
        }

        Loader {
            asynchronous: true
            anchors.fill: parent
            active: root.blurEnabled

            sourceComponent: MultiEffect {
                source: ShaderEffectSource {
                    id: clockShaderSource
                    sourceItem: root.wallpaper
                    sourceRect: Qt.rect(root.absX, root.absY, root.width, root.height)
                    live: false

                    Connections {
                        target: root
                        function onAbsXChanged() { clockShaderSource.scheduleUpdate(); }
                        function onAbsYChanged() { clockShaderSource.scheduleUpdate(); }
                        function onWidthChanged() { clockShaderSource.scheduleUpdate(); }
                        function onHeightChanged() { clockShaderSource.scheduleUpdate(); }
                    }

                    Connections {
                        target: Wallpapers
                        function onCurrentChanged() { clockShaderSource.scheduleUpdate(); }
                    }
                }
                maskSource: backgroundPlate
                maskEnabled: true
                blurEnabled: true
                blur: 1
                blurMax: 64
                autoPaddingEnabled: false
            }
        }

        StyledRect {
            id: backgroundPlate

            visible: root.bgEnabled
            anchors.fill: parent
            radius: Tokens.rounding.extraLarge * root.clockScale
            opacity: Config.background.desktopClock.background.opacity
            color: Colours.palette.m3surface

            layer.enabled: root.blurEnabled
        }

        Loader {
            id: styleLoader
            anchors.centerIn: parent
            asynchronous: true

            source: {
                let s = Config.background.desktopClock.style.toLowerCase();
                if (s === "pill") return "clocks/Pill.qml";
                if (s === "minimal") return "clocks/Minimal.qml";
                if (s === "analog") return "clocks/Analog.qml";
                if (s === "flower") return "clocks/Flower.qml";
                if (s === "clover") return "clocks/Clover.qml";
                if (s === "stacked") return "clocks/Stacked.qml";
                if (s === "bento") return "clocks/Bento.qml";
                return "clocks/Default.qml";
            }
        }
    }

    // Outline border when unlocked OR hovered
    StyledRect {
        anchors.fill: parent
        anchors.margins: -4
        color: "transparent"
        border.color: Colours.palette.m3primary
        border.width: 1.5
        radius: backgroundPlate.radius + 4
        visible: !Time.clockLockPosition || dragArea.containsMouse
        opacity: (!Time.clockLockPosition && (dragArea.pressed || resizeArea.pressed)) ? 0.8 : ((!Time.clockLockPosition || dragArea.containsMouse) ? 0.35 : 0.0)

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    // Top-right lock / unlock control pill
    StyledRect {
        id: lockPill
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 6
        width: 28
        height: 28
        radius: 14
        color: Colours.palette.m3surfaceContainerHigh
        opacity: (dragArea.containsMouse || lockBtnArea.containsMouse || !Time.clockLockPosition) ? 0.9 : 0.0
        visible: opacity > 0
        z: 10

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: Time.clockLockPosition ? "lock" : "lock_open"
            color: Time.clockLockPosition ? Colours.palette.m3outline : Colours.palette.m3primary
            fontStyle: Tokens.font.icon.small
        }

        MouseArea {
            id: lockBtnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                Time.clockLockPosition = !Time.clockLockPosition;
                Time.saveClockState();
            }

            onDoubleClicked: {
                Time.resetClock();
            }
        }
    }

    // Drag area for moving
    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: !Time.clockLockPosition ? Qt.SizeAllCursor : Qt.ArrowCursor

        property point clickPos: "0,0"
        property real startX: 0
        property real startY: 0

        onDoubleClicked: {
            Time.resetClock();
        }

        onPressed: event => {
            if (event.button === Qt.RightButton) {
                Time.clockLockPosition = !Time.clockLockPosition;
                return;
            }
            if (Time.clockLockPosition)
                return;

            clickPos = root.wallpaper ? mapToItem(root.wallpaper, event.x, event.y) : Qt.point(event.x, event.y);
            if (Time.clockHasCustomPosition) {
                startX = Time.clockOffsetX;
                startY = Time.clockOffsetY;
            } else {
                startX = root.parent ? root.parent.x : 0;
                startY = root.parent ? root.parent.y : 0;
            }
        }

        onPositionChanged: event => {
            if (!root.wallpaper) return;
            const curPos = mapToItem(root.wallpaper, event.x, event.y);

            const cx = root.wallpaper.width / 2;
            const cy = root.wallpaper.height / 2;
            if (cx > 0 && cy > 0) {
                const rawTx = Math.max(-1.0, Math.min(1.0, (curPos.x - cx) / cx));
                const rawTy = Math.max(-1.0, Math.min(1.0, (curPos.y - cy) / cy));
                const tx = Math.sign(rawTx) * Math.pow(Math.abs(rawTx), 0.7);
                const ty = Math.sign(rawTy) * Math.pow(Math.abs(rawTy), 0.7);
                const comp = ShellState.forActive() ? ShellState.componentsFor(ShellState.forActive().modelData) : null;
                const wp = comp ? comp.wallpaperItem : null;
                if (wp && wp.item) {
                    wp.item.targetX = tx;
                    wp.item.targetY = ty;
                }
            }

            if (Time.clockLockPosition || !pressed || (event.buttons & Qt.LeftButton) === 0)
                return;

            if (!Time.clockHasCustomPosition) {
                startX = root.parent ? root.parent.x : 0;
                startY = root.parent ? root.parent.y : 0;
                Time.clockOffsetX = startX;
                Time.clockOffsetY = startY;
                Time.clockHasCustomPosition = true;
            }

            let newX = startX + (curPos.x - clickPos.x);
            let newY = startY + (curPos.y - clickPos.y);

            let screenWidth = root.wallpaper.width;
            let screenHeight = root.wallpaper.height;

            const edgeMargin = Math.max(Tokens.padding.extraLargeIncreased, Config.border.clampedThickness + 32);
            const leftMargin = Tokens.sizes.bar.innerWidth + edgeMargin;

            const minX = leftMargin;
            const maxX = Math.max(minX, screenWidth - root.width - edgeMargin);
            const minY = edgeMargin;
            const maxY = Math.max(minY, screenHeight - root.height - edgeMargin);

            newX = Math.max(minX, Math.min(maxX, newX));
            newY = Math.max(minY, Math.min(maxY, newY));

            Time.clockOffsetX = newX;
            Time.clockOffsetY = newY;
        }

        onReleased: {
            Time.saveClockState();
        }
    }

    // Corner handle icon when unlocked
    MaterialIcon {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 4
        text: "south_east"
        color: Colours.palette.m3primary
        fontStyle: Tokens.font.icon.small
        visible: !Time.clockLockPosition
        z: 10
    }

    // Resize area for scaling
    MouseArea {
        id: resizeArea
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 28
        height: 28
        cursorShape: Qt.SizeFDiagCursor
        enabled: !Time.clockLockPosition
        hoverEnabled: true
        z: 10

        property point clickPos: "0,0"
        property real startScale: 1.0

        onPressed: event => {
            clickPos = root.wallpaper ? mapToItem(root.wallpaper, event.x, event.y) : Qt.point(event.x, event.y)
            startScale = Time.clockCustomScale
        }

        onPositionChanged: event => {
            if (!pressed || !root.wallpaper) return;
            let curPos = mapToItem(root.wallpaper, event.x, event.y)
            let dx = curPos.x - clickPos.x
            let dy = curPos.y - clickPos.y
            let delta = (dx + dy) / 2.0
            let newScale = startScale + (delta / 250.0)
            let clampedScale = Math.max(0.5, Math.min(3.0, newScale))
            Time.clockCustomScale = clampedScale

            if (Time.clockHasCustomPosition) {
                let screenWidth = root.wallpaper.width;
                let screenHeight = root.wallpaper.height;
                const edgeMargin = Math.max(Tokens.padding.extraLargeIncreased, Config.border.clampedThickness + 32);
                const leftMargin = Tokens.sizes.bar.innerWidth + edgeMargin;

                const minX = leftMargin;
                const maxX = Math.max(minX, screenWidth - root.width - edgeMargin);
                const minY = edgeMargin;
                const maxY = Math.max(minY, screenHeight - root.height - edgeMargin);

                if (Time.clockOffsetX > maxX) Time.clockOffsetX = maxX;
                if (Time.clockOffsetY > maxY) Time.clockOffsetY = maxY;
            }
        }

        onReleased: {
            Time.saveClockState();
        }
    }

    Behavior on clockScale {
        enabled: !resizeArea.pressed
        Anim {}
    }
}
