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

    // Time Section (Super-sized modern font)
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Tokens.spacing.small * root.clockScale

        StyledText {
            text: {
                let h = Time.date.getHours();
                if (Time.clockTimeFormat === "12h") {
                    h = h % 12;
                    if (h === 0) h = 12;
                }
                return h < 10 ? "0" + h : "" + h;
            }
            font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 4.5 * root.clockScale).weight(Font.ExtraBold).build()
            color: root.safePrimary
        }

        // Animated glowing separator dot
        StyledText {
            text: ":"
            font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 4.5 * root.clockScale).weight(Font.Light).build()
            color: root.safeTertiary
            
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.2; duration: 1000; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutQuad }
            }
        }

        StyledText {
            text: {
                let m = Time.date.getMinutes();
                return m < 10 ? "0" + m : "" + m;
            }
            font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 4.5 * root.clockScale).weight(Font.ExtraBold).build()
            color: root.safeSecondary
        }
    }

    // Date Pill (Glass plate style capsule)
    StyledRect {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: dateRow.implicitWidth + Tokens.padding.large * 4 * root.clockScale
        implicitHeight: dateRow.implicitHeight + Tokens.padding.medium * 1.5 * root.clockScale
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
                font: Tokens.font.clock.size(Tokens.font.title.small.pointSize * 0.9 * root.clockScale).letterSpacing(2).weight(Font.Bold).build()
                color: root.safePrimary
            }

            Rectangle {
                width: 4 * root.clockScale
                height: 4 * root.clockScale
                radius: 2 * root.clockScale
                color: Colours.palette.m3outlineVariant
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                text: Time.format("MMM d").toUpperCase()
                font: Tokens.font.clock.size(Tokens.font.title.small.pointSize * 0.9 * root.clockScale).letterSpacing(2).weight(Font.Medium).build()
                color: root.safeSecondary
            }
        }
    }
}
