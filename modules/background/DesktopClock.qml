pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Caelestia.Config
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

    implicitWidth: layout.implicitWidth + (Tokens.padding.large * 4 * root.clockScale)
    implicitHeight: layout.implicitHeight + (Tokens.padding.extraLargeIncreased * root.clockScale)

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
                    sourceItem: root.wallpaper
                    sourceRect: Qt.rect(root.absX, root.absY, root.width, root.height)
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

        RowLayout {
            id: layout

            anchors.centerIn: parent
            spacing: Tokens.spacing.large * root.clockScale

            RowLayout {
                spacing: Tokens.spacing.small

                StyledText {
                    text: {
                        let h = Time.date.getHours();
                        if (Time.clockTimeFormat === "12h") {
                            h = h % 12;
                            if (h === 0) h = 12;
                        }
                        return h < 10 ? "0" + h : "" + h;
                    }
                    font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 3 * root.clockScale).weight(Font.Bold).build()
                    color: root.safePrimary
                }

                StyledText {
                    text: ":"
                    font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 3 * root.clockScale).build()
                    color: root.safeTertiary
                    opacity: 0.8
                    Layout.topMargin: -Tokens.padding.large * 1.5 * root.clockScale
                }

                StyledText {
                    text: {
                        let m = Time.date.getMinutes();
                        return m < 10 ? "0" + m : "" + m;
                    }
                    font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 3 * root.clockScale).weight(Font.Bold).build()
                    color: root.safeSecondary
                }

                Loader {
                    asynchronous: true
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Tokens.padding.large * 1.4 * root.clockScale

                    active: Time.clockTimeFormat === "12h" && Time.clockShowAmPm
                    visible: active

                    sourceComponent: StyledText {
                        text: Time.format("AP")
                        font: Tokens.font.clock.size(Tokens.font.title.medium.pointSize * root.clockScale).build()
                        color: root.safeSecondary
                    }
                }
            }

            StyledRect {
                Layout.fillHeight: true
                Layout.preferredWidth: 4 * root.clockScale
                Layout.topMargin: Tokens.spacing.large * root.clockScale
                Layout.bottomMargin: Tokens.spacing.large * root.clockScale
                radius: Tokens.rounding.full
                color: root.safePrimary
                opacity: 0.8
            }

            ColumnLayout {
                spacing: 0

                StyledText {
                    text: Time.format("MMMM").toUpperCase()
                    font: Tokens.font.clock.size(Tokens.font.title.medium.pointSize * root.clockScale).letterSpacing(4).weight(Font.Bold).build()
                    color: root.safeSecondary
                }

                StyledText {
                    text: Time.format("dd")
                    font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * root.clockScale).letterSpacing(2).weight(Font.Medium).build()
                    color: root.safePrimary
                }

                StyledText {
                    text: Time.format("dddd")
                    font: Tokens.font.clock.size(Tokens.font.body.large.pointSize * root.clockScale).letterSpacing(2).build()
                    color: root.safeSecondary
                }
            }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: !Time.clockLockPosition
        cursorShape: enabled ? Qt.SizeAllCursor : Qt.ArrowCursor

        property point clickPos: "0,0"

        onPressed: event => {
            clickPos = Qt.point(event.x, event.y)
        }

        onPositionChanged: event => {
            let delta = Qt.point(event.x - clickPos.x, event.y - clickPos.y)
            let newX = root.parent.x + delta.x
            let newY = root.parent.y + delta.y
            
            let screenWidth = root.wallpaper.width
            let screenHeight = root.wallpaper.height
            newX = Math.max(0, Math.min(screenWidth - root.width, newX))
            newY = Math.max(0, Math.min(screenHeight - root.height, newY))

            Time.clockHasCustomPosition = true
            root.parent.x = newX
            root.parent.y = newY
            
            Time.clockOffsetX = newX
            Time.clockOffsetY = newY
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
