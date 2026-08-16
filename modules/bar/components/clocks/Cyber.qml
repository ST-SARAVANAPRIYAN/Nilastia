pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import qs.components
import qs.services

ColumnLayout {
    id: layout
    spacing: 0

    // Futuristic Monotech brackets
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: "["
        font: Tokens.font.body.builders.small.scale(0.85).bold().build()
        color: Colours.palette.m3primary
        opacity: 0.5
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: Time.hourStr
        font: Tokens.font.body.builders.small.scale(1.15).bold().width(120).build()
        color: Colours.palette.m3primary
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: Time.minuteStr
        font: Tokens.font.body.builders.small.scale(1.15).bold().width(120).build()
        color: Colours.palette.m3secondary
    }

    // Small blinking colon
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: ":"
        font: Tokens.font.body.builders.small.scale(0.8).bold().build()
        color: Colours.palette.m3tertiary
        
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.1; duration: 500 }
            NumberAnimation { to: 1.0; duration: 500 }
        }
    }

    // Small seconds ticker
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: {
            let s = Time.second;
            return s < 10 ? "0" + s : "" + s;
        }
        font: Tokens.font.body.builders.small.scale(0.7).width(110).build()
        color: Colours.palette.m3tertiary
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: "]"
        font: Tokens.font.body.builders.small.scale(0.85).bold().build()
        color: Colours.palette.m3primary
        opacity: 0.5
    }
}
