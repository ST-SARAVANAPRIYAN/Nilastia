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
                if (s === "cyber") return "clocks/Cyber.qml";
                return "clocks/Default.qml";
            }
        }
    }

    // Outline border when unlocked AND actively clicked/dragged/resized
    StyledRect {
        anchors.fill: parent
        anchors.margins: -4
        color: "transparent"
        border.color: Colours.palette.m3primary
        border.width: 1.5
        radius: backgroundPlate.radius + 4
        visible: !Time.clockLockPosition
        opacity: (!Time.clockLockPosition && (dragArea.pressed || resizeArea.pressed)) ? 0.6 : 0.0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    // Drag area for moving
    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: !Time.clockLockPosition
        cursorShape: enabled ? Qt.SizeAllCursor : Qt.ArrowCursor

        property point clickPos: "0,0"
        property real startX: 0
        property real startY: 0

        onPressed: event => {
            clickPos = mapToItem(root.wallpaper, event.x, event.y)
            startX = root.parent.x
            startY = root.parent.y
        }

        onPositionChanged: event => {
            let curPos = mapToItem(root.wallpaper, event.x, event.y)

            if (!Time.clockHasCustomPosition) {
                Time.clockOffsetX = root.parent.x
                Time.clockOffsetY = root.parent.y
                Time.clockHasCustomPosition = true
                startX = root.parent.x
                startY = root.parent.y
            }

            let newX = startX + (curPos.x - clickPos.x)
            let newY = startY + (curPos.y - clickPos.y)

            let screenWidth = root.wallpaper.width
            let screenHeight = root.wallpaper.height
            newX = Math.max(0, Math.min(screenWidth - root.width, newX))
            newY = Math.max(0, Math.min(screenHeight - root.height, newY))

            Time.clockOffsetX = newX
            Time.clockOffsetY = newY
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
    }

    // Resize area for scaling
    MouseArea {
        id: resizeArea
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 32 * root.clockScale
        height: 32 * root.clockScale
        cursorShape: Qt.SizeFDiagCursor
        enabled: !Time.clockLockPosition

        property point clickPos: "0,0"
        property real startScale: 1.0

        onPressed: event => {
            clickPos = mapToItem(root.wallpaper, event.x, event.y)
            startScale = Time.clockCustomScale
        }

        onPositionChanged: event => {
            let curPos = mapToItem(root.wallpaper, event.x, event.y)
            let dx = curPos.x - clickPos.x
            let newScale = startScale + (dx / 250.0)
            Time.clockCustomScale = Math.max(0.5, Math.min(3.0, newScale))
        }
    }

    Behavior on clockScale {
        Anim {}
    }

    Behavior on implicitWidth {
        Anim {
            type: Anim.StandardSmall
        }
    }
}
