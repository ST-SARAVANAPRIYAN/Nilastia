pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import qs.components
import qs.services

ColumnLayout {
    id: layout
    anchors.centerIn: parent
    spacing: Tokens.spacing.medium * root.clockScale

    // Dual Bento Cards Row
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Tokens.spacing.medium * root.clockScale

        // Hours Bento Card
        StyledRect {
            implicitWidth: 135 * root.clockScale
            implicitHeight: 110 * root.clockScale
            radius: 28 * root.clockScale
            color: Colours.palette.m3primaryContainer

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2 * root.clockScale

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4 * root.clockScale

                    MaterialIcon {
                        text: "schedule"
                        fontStyle: Tokens.font.icon.extraSmall
                        color: Colours.palette.m3onPrimaryContainer
                        opacity: 0.8
                    }

                    StyledText {
                        text: "HOURS"
                        font: Tokens.font.clock.size(Tokens.font.label.small.pointSize * 0.75 * root.clockScale).letterSpacing(1.5).weight(Font.Bold).build()
                        color: Colours.palette.m3onPrimaryContainer
                        opacity: 0.8
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        let h = Time.date.getHours();
                        if (Time.clockTimeFormat === "12h") {
                            h = h % 12;
                            if (h === 0) h = 12;
                        }
                        return h < 10 ? "0" + h : "" + h;
                    }
                    font: Tokens.font.clock.size(Tokens.font.headline.large.pointSize * 1.8 * root.clockScale).weight(Font.ExtraBold).build()
                    color: Colours.palette.m3onPrimaryContainer
                }
            }
        }

        // Minutes Bento Card
        StyledRect {
            implicitWidth: 135 * root.clockScale
            implicitHeight: 110 * root.clockScale
            radius: 28 * root.clockScale
            color: Colours.palette.m3secondaryContainer

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2 * root.clockScale

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4 * root.clockScale

                    MaterialIcon {
                        text: "timelapse"
                        fontStyle: Tokens.font.icon.extraSmall
                        color: Colours.palette.m3onSecondaryContainer
                        opacity: 0.8
                    }

                    StyledText {
                        text: "MINUTES"
                        font: Tokens.font.clock.size(Tokens.font.label.small.pointSize * 0.75 * root.clockScale).letterSpacing(1.5).weight(Font.Bold).build()
                        color: Colours.palette.m3onSecondaryContainer
                        opacity: 0.8
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        let m = Time.date.getMinutes();
                        return m < 10 ? "0" + m : "" + m;
                    }
                    font: Tokens.font.clock.size(Tokens.font.headline.large.pointSize * 1.8 * root.clockScale).weight(Font.ExtraBold).build()
                    color: Colours.palette.m3onSecondaryContainer
                }
            }
        }
    }

    // Bottom Date Capsule Pill
    StyledRect {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: dateRow.implicitWidth + (Tokens.padding.large * 3 * root.clockScale)
        implicitHeight: dateRow.implicitHeight + (Tokens.padding.small * 1.5 * root.clockScale)
        radius: implicitHeight / 2
        color: Colours.tPalette.m3surfaceContainerHigh
        border.width: 1
        border.color: Colours.palette.m3outlineVariant

        RowLayout {
            id: dateRow
            anchors.centerIn: parent
            spacing: Tokens.spacing.small * root.clockScale

            StyledText {
                text: Time.format("dddd").toUpperCase()
                font: Tokens.font.clock.size(Tokens.font.title.small.pointSize * 0.85 * root.clockScale).letterSpacing(1.5).weight(Font.Bold).build()
                color: root.safePrimary
            }

            Rectangle {
                width: 4 * root.clockScale
                height: 4 * root.clockScale
                radius: 2 * root.clockScale
                color: Colours.palette.m3outlineVariant
            }

            StyledText {
                text: Time.format("MMMM d").toUpperCase()
                font: Tokens.font.clock.size(Tokens.font.title.small.pointSize * 0.85 * root.clockScale).letterSpacing(1.5).weight(Font.Medium).build()
                color: root.safeSecondary
            }

            Loader {
                active: Time.clockTimeFormat === "12h" && Time.clockShowAmPm
                visible: active

                sourceComponent: RowLayout {
                    spacing: Tokens.spacing.small * root.clockScale

                    Rectangle {
                        width: 4 * root.clockScale
                        height: 4 * root.clockScale
                        radius: 2 * root.clockScale
                        color: Colours.palette.m3outlineVariant
                    }

                    StyledText {
                        text: Time.format("AP")
                        font: Tokens.font.clock.size(Tokens.font.title.small.pointSize * 0.85 * root.clockScale).weight(Font.Bold).build()
                        color: root.safeTertiary
                    }
                }
            }
        }
    }
}
