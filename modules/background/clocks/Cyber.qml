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

    // Left tech bracket
    StyledText {
        text: "{"
        font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 2.5 * root.clockScale).weight(Font.ExtraLight).build()
        color: root.safePrimary
        opacity: 0.4
    }

    // Time Section (Monospace digital clock)
    ColumnLayout {
        spacing: 0

        RowLayout {
            spacing: 2 * root.clockScale

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
            }

            StyledText {
                text: {
                    let m = Time.date.getMinutes();
                    return m < 10 ? "0" + m : "" + m;
                }
                font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 3 * root.clockScale).weight(Font.Bold).build()
                color: root.safeSecondary
            }

            // Small Seconds
            StyledText {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: Tokens.padding.medium * root.clockScale
                text: {
                    let s = Time.second;
                    return s < 10 ? "0" + s : "" + s;
                }
                font: Tokens.font.clock.size(Tokens.font.title.small.pointSize * root.clockScale).build()
                color: root.safeTertiary
                opacity: 0.7
            }
        }

        // Sub-text showing system timestamp
        StyledText {
            text: "SYS_TIME_OK // " + Time.format("yyyy.MM.dd").toUpperCase()
            font: Tokens.font.clock.size(Tokens.font.body.small.pointSize * 0.75 * root.clockScale).letterSpacing(2).build()
            color: root.safeSecondary
            opacity: 0.6
        }
    }

    // Right tech bracket
    StyledText {
        text: "}"
        font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 2.5 * root.clockScale).weight(Font.ExtraLight).build()
        color: root.safePrimary
        opacity: 0.4
    }
}
