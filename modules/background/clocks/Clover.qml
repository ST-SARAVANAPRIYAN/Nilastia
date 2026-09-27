pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import Quickshell
import Nilastia.Config
import qs.components
import qs.services

Item {
    id: clockRoot

    implicitWidth: 260 * root.clockScale
    implicitHeight: 260 * root.clockScale

    SystemClock {
        id: secondClock
        precision: SystemClock.Seconds
    }

    readonly property date date: secondClock.date
    readonly property int hrs: date.getHours()
    readonly property int mins: date.getMinutes()
    readonly property int secs: date.getSeconds()

    // 4-Lobed Material You Clover / Cushion Dial
    MaterialShape {
        id: cloverDial
        anchors.centerIn: parent
        implicitSize: 260 * root.clockScale
        shape: MaterialShape.Cookie4Sided
        color: Colours.tPalette.m3surfaceContainerHigh
        strokeColor: Colours.palette.m3outlineVariant
        strokeWidth: 1.5 * root.clockScale

        // Numerals 12, 3, 6, 9 inside the 4 lobes
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 16 * root.clockScale
            text: "12"
            font: Tokens.font.clock.size(Tokens.font.headline.small.pointSize * root.clockScale).weight(Font.ExtraBold).build()
            color: root.safePrimary
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 20 * root.clockScale
            text: "3"
            font: Tokens.font.clock.size(Tokens.font.headline.small.pointSize * root.clockScale).weight(Font.ExtraBold).build()
            color: root.safePrimary
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16 * root.clockScale
            text: "6"
            font: Tokens.font.clock.size(Tokens.font.headline.small.pointSize * root.clockScale).weight(Font.ExtraBold).build()
            color: root.safePrimary
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 20 * root.clockScale
            text: "9"
            font: Tokens.font.clock.size(Tokens.font.headline.small.pointSize * root.clockScale).weight(Font.ExtraBold).build()
            color: root.safePrimary
        }

        // Integrated Date Chip
        StyledRect {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.verticalCenter
            anchors.topMargin: 36 * root.clockScale
            implicitWidth: dateLabel.implicitWidth + (16 * root.clockScale)
            implicitHeight: 22 * root.clockScale
            radius: implicitHeight / 2
            color: Colours.tPalette.m3surfaceContainerHighest
            border.width: 1
            border.color: Colours.palette.m3outlineVariant

            StyledText {
                id: dateLabel
                anchors.centerIn: parent
                text: Time.format("ddd, MMM d").toUpperCase()
                font: Tokens.font.clock.size(Tokens.font.label.small.pointSize * 0.85 * root.clockScale).letterSpacing(1).weight(Font.Bold).build()
                color: root.safeSecondary
            }
        }

        // Hour Hand
        Item {
            id: hourHandWrapper
            anchors.centerIn: parent
            width: 1
            height: 1

            StyledRect {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.verticalCenter
                anchors.bottomMargin: -8 * root.clockScale
                width: 12 * root.clockScale
                height: 60 * root.clockScale
                radius: width / 2
                color: root.safePrimary
            }

            rotation: ((clockRoot.hrs % 12) * 30) + (clockRoot.mins * 0.5) + (clockRoot.secs * (0.5 / 60))

            Behavior on rotation {
                RotationAnimation {
                    duration: 250
                    direction: RotationAnimation.Shortest
                    easing.type: Easing.OutQuad
                }
            }
        }

        // Minute Hand
        Item {
            id: minuteHandWrapper
            anchors.centerIn: parent
            width: 1
            height: 1

            StyledRect {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.verticalCenter
                anchors.bottomMargin: -10 * root.clockScale
                width: 8 * root.clockScale
                height: 88 * root.clockScale
                radius: width / 2
                color: root.safeSecondary
            }

            rotation: (clockRoot.mins * 6) + (clockRoot.secs * 0.1)

            Behavior on rotation {
                RotationAnimation {
                    duration: 250
                    direction: RotationAnimation.Shortest
                    easing.type: Easing.OutQuad
                }
            }
        }

        // Second Hand
        Item {
            id: secondHandWrapper
            anchors.centerIn: parent
            width: 1
            height: 1

            StyledRect {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.verticalCenter
                anchors.bottomMargin: -22 * root.clockScale
                width: 2.5 * root.clockScale
                height: 114 * root.clockScale
                radius: width / 2
                color: root.safeTertiary
            }

            rotation: clockRoot.secs * 6

            Behavior on rotation {
                RotationAnimation {
                    duration: 150
                    direction: RotationAnimation.Shortest
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }
            }
        }

        // Center Pin
        StyledRect {
            anchors.centerIn: parent
            width: 16 * root.clockScale
            height: width
            radius: width / 2
            color: root.safePrimary

            StyledRect {
                anchors.centerIn: parent
                width: 6 * root.clockScale
                height: width
                radius: width / 2
                color: Colours.palette.m3surface
            }
        }
    }
}
