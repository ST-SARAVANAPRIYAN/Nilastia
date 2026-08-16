pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import qs.components
import qs.services

ColumnLayout {
    id: layout
    anchors.centerIn: parent
    spacing: Tokens.spacing.small * root.clockScale

    // Huge Elegant Time (Sans-Serif Light/Thin variant)
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: {
            let h = Time.date.getHours();
            let m = Time.date.getMinutes();
            if (Time.clockTimeFormat === "12h") {
                h = h % 12;
                if (h === 0) h = 12;
            }
            let hStr = h < 10 ? "0" + h : "" + h;
            let mStr = m < 10 ? "0" + m : "" + m;
            return hStr + ":" + mStr;
        }
        font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 5 * root.clockScale).weight(Font.Light).build()
        color: root.safePrimary
    }

    // Sleek horizontal divider line
    StyledRect {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 180 * root.clockScale
        implicitHeight: 2 * root.clockScale
        color: Colours.palette.m3primary
        opacity: 0.7
        radius: 1
    }

    // Spaced, clean date
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.spacing.extraSmall * root.clockScale
        text: Time.format("dddd, MMMM d").toUpperCase()
        font: Tokens.font.clock.size(Tokens.font.body.medium.pointSize * 0.85 * root.clockScale).letterSpacing(4).weight(Font.Medium).build()
        color: root.safeSecondary
    }
}
