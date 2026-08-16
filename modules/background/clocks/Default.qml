pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import qs.components
import qs.services

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
