pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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

    // Outer Dial Face
    StyledRect {
        id: dialPlate
        anchors.fill: parent
        radius: width / 2
        color: Colours.tPalette.m3surfaceContainerHigh
        border.width: 1.5 * root.clockScale
        border.color: Colours.palette.m3outlineVariant

        // Subtle concentric inner accent track
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.88
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.35)
        }

        // Major Hour Numerals (12, 3, 6, 9)
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 12 * root.clockScale
            text: "12"
            font: Tokens.font.clock.size(Tokens.font.title.large.pointSize * 1.1 * root.clockScale).weight(Font.ExtraBold).build()
            color: root.safePrimary
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 16 * root.clockScale
            text: "3"
            font: Tokens.font.clock.size(Tokens.font.title.large.pointSize * 1.1 * root.clockScale).weight(Font.ExtraBold).build()
            color: root.safePrimary
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12 * root.clockScale
            text: "6"
            font: Tokens.font.clock.size(Tokens.font.title.large.pointSize * 1.1 * root.clockScale).weight(Font.ExtraBold).build()
            color: root.safePrimary
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 16 * root.clockScale
            text: "9"
            font: Tokens.font.clock.size(Tokens.font.title.large.pointSize * 1.1 * root.clockScale).weight(Font.ExtraBold).build()
            color: root.safePrimary
        }

        // Minor hour tick dots (1, 2, 4, 5, 7, 8, 10, 11)
        Repeater {
            model: [1, 2, 4, 5, 7, 8, 10, 11]

            Item {
                anchors.centerIn: parent
                width: 1
                height: 1
                rotation: modelData * 30

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.verticalCenter
                    anchors.bottomMargin: (dialPlate.width * 0.44) - (12 * root.clockScale)
                    width: 5 * root.clockScale
                    height: 5 * root.clockScale
                    radius: width / 2
                    color: Colours.palette.m3outline
                    opacity: 0.7
                }
            }
        }

        // Integrated Date Chip
        StyledRect {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.verticalCenter
            anchors.topMargin: 32 * root.clockScale
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
                height: 62 * root.clockScale
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
                height: 90 * root.clockScale
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
                height: 115 * root.clockScale
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
