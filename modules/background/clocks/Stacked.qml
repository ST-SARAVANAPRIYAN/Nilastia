pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import qs.components
import qs.services

ColumnLayout {
    id: layout
    anchors.centerIn: parent
    spacing: -8 * root.clockScale

    // Stacked Hours
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
        font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 4.2 * root.clockScale).weight(Font.ExtraBold).build()
        color: root.safePrimary
    }

    // Stacked Minutes
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: {
            let m = Time.date.getMinutes();
            return m < 10 ? "0" + m : "" + m;
        }
        font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 4.2 * root.clockScale).weight(Font.ExtraBold).build()
        color: root.safeSecondary
    }

    // Integrated Date Capsule
    StyledRect {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10 * root.clockScale
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

            MaterialIcon {
                text: "calendar_today"
                fontStyle: Tokens.font.icon.small
                color: root.safePrimary
            }

            StyledText {
                text: Time.format("ddd, MMM d").toUpperCase()
                font: Tokens.font.clock.size(Tokens.font.title.small.pointSize * 0.9 * root.clockScale).letterSpacing(1.5).weight(Font.Bold).build()
                color: root.safePrimary
            }

            Loader {
                active: Time.clockTimeFormat === "12h" && Time.clockShowAmPm
                visible: active

                sourceComponent: RowLayout {
                    spacing: Tokens.spacing.small * root.clockScale

                    Rectangle {
                        width: 3 * root.clockScale
                        height: 3 * root.clockScale
                        radius: 1.5 * root.clockScale
                        color: Colours.palette.m3outlineVariant
                    }

                    StyledText {
                        text: Time.format("AP")
                        font: Tokens.font.clock.size(Tokens.font.title.small.pointSize * 0.85 * root.clockScale).weight(Font.Medium).build()
                        color: root.safeSecondary
                    }
                }
            }
        }
    }
}
