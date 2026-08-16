pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import qs.components
import qs.services

ColumnLayout {
    id: layout
    spacing: Tokens.spacing.extraSmall

    Loader {
        Layout.alignment: Qt.AlignHCenter
        asynchronous: true
        active: Config.bar.clock.showIcon
        visible: active

        sourceComponent: MaterialIcon {
            text: "calendar_month"
            color: root.colour
        }
    }

    Loader {
        Layout.alignment: Qt.AlignHCenter
        asynchronous: true
        active: Config.bar.clock.showDate
        visible: active

        sourceComponent: ColumnLayout {
            spacing: layout.spacing - 4

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Time.format("ddd")
                font: Tokens.font.body.builders.small.scale(0.9).build()
                color: root.colour
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Time.format("d")
                font: root.font.scale(1.1).build()
                color: root.colour
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.leftMargin: -Tokens.padding.extraSmall
                Layout.rightMargin: -Tokens.padding.extraSmall
                Layout.topMargin: 4
                Layout.bottomMargin: Tokens.padding.extraSmall / 2
                implicitHeight: 1
                color: Colours.palette.m3outlineVariant
            }
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: Time.hourStr
        font: {
            const scale = text === "11" ? 1.15 : Math.min(1.05, Math.max(hourMetrics.width, minMetrics.width) / hourMetrics.width);
            return root.font.width(scale * 100).letterSpacing(scale).build();
        }
        color: root.colour

        TextMetrics {
            id: hourMetrics

            font: root.font.build()
            text: Time.hourStr
        }
    }

    StyledText {
        Layout.topMargin: -parent.spacing - 4
        Layout.alignment: Qt.AlignHCenter
        text: Time.minuteStr
        font: {
            const scale = text === "11" ? 1.15 : Math.min(1.05, Math.max(hourMetrics.width, minMetrics.width) / minMetrics.width);
            return root.font.width(scale * 100).letterSpacing(scale).build();
        }
        color: root.colour

        TextMetrics {
            id: minMetrics

            font: root.font.build()
            text: Time.minuteStr
        }
    }

    Loader {
        Layout.topMargin: -parent.spacing - 4
        Layout.alignment: Qt.AlignHCenter
        asynchronous: true
        active: GlobalConfig.services.useTwelveHourClock
        visible: active

        sourceComponent: StyledText {
            text: Time.amPmStr.toLowerCase()
            font: Tokens.font.body.builders.small.scale(0.9).build()
            color: root.colour
        }
    }
}
