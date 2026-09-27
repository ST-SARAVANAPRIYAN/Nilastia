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

    // 12-Lobed Material You Flower / Cookie Dial
    MaterialShape {
        id: flowerDial
        anchors.centerIn: parent
        implicitSize: 260 * root.clockScale
        shape: MaterialShape.Cookie12Sided
        color: Colours.tPalette.m3surfaceContainerHigh
        strokeColor: Colours.palette.m3outlineVariant
        strokeWidth: 1.5 * root.clockScale

        // Center Day / Date Circular Disc
        StyledRect {
            anchors.centerIn: parent
            width: 84 * root.clockScale
            height: width
            radius: width / 2
            color: Qt.alpha(Colours.palette.m3primaryContainer, 0.35)
            border.width: 1
            border.color: Qt.alpha(Colours.palette.m3primary, 0.25)

            ColumnLayout {
                anchors.centerIn: parent
                spacing: -2 * root.clockScale

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Time.format("ddd").toUpperCase()
                    font: Tokens.font.clock.size(Tokens.font.label.small.pointSize * 0.9 * root.clockScale).letterSpacing(1.5).weight(Font.Bold).build()
                    color: root.safePrimary
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Time.format("d")
                    font: Tokens.font.clock.size(Tokens.font.headline.small.pointSize * 1.1 * root.clockScale).weight(Font.ExtraBold).build()
                    color: root.safeSecondary
                }
            }
        }

        // 12 Petal Accents
        Repeater {
            model: 12

            Item {
                anchors.centerIn: parent
                width: 1
                height: 1
                rotation: index * 30

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.verticalCenter
                    anchors.bottomMargin: (112 * root.clockScale)
                    width: 5 * root.clockScale
                    height: 5 * root.clockScale
                    radius: width / 2
                    color: Colours.palette.m3primary
                    opacity: 0.65
                }
            }
        }

        // Playful Wide Pill Hour Hand
        Item {
            id: hourHandWrapper
            anchors.centerIn: parent
            width: 1
            height: 1

            StyledRect {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.verticalCenter
                anchors.bottomMargin: -8 * root.clockScale
                width: 14 * root.clockScale
                height: 58 * root.clockScale
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

        // Playful Rounded Pill Minute Hand
        Item {
            id: minuteHandWrapper
            anchors.centerIn: parent
            width: 1
            height: 1

            StyledRect {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.verticalCenter
                anchors.bottomMargin: -10 * root.clockScale
                width: 9 * root.clockScale
                height: 86 * root.clockScale
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

        // Second Hand with Accent Counterweight Circle
        Item {
            id: secondHandWrapper
            anchors.centerIn: parent
            width: 1
            height: 1

            StyledRect {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.verticalCenter
                anchors.bottomMargin: -24 * root.clockScale
                width: 2.5 * root.clockScale
                height: 118 * root.clockScale
                radius: width / 2
                color: root.safeTertiary

                // Counterweight decorative pill
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6 * root.clockScale
                    width: 7 * root.clockScale
                    height: 7 * root.clockScale
                    radius: width / 2
                    color: root.safeTertiary
                }
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
            width: 18 * root.clockScale
            height: width
            radius: width / 2
            color: root.safePrimary

            StyledRect {
                anchors.centerIn: parent
                width: 7 * root.clockScale
                height: width
                radius: width / 2
                color: Colours.palette.m3surface
            }
        }
    }
}
