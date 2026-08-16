pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import qs.components
import qs.services

ColumnLayout {
    id: layout
    spacing: Tokens.spacing.extraSmall

    StyledRect {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: Tokens.sizes.bar.innerWidth - Tokens.padding.extraSmall * 2
        implicitHeight: pillLayout.implicitHeight + Tokens.padding.medium * 2
        radius: implicitWidth / 2
        
        color: Colours.tPalette.m3surfaceContainerHigh
        border.width: 1
        border.color: Colours.palette.m3outlineVariant

        ColumnLayout {
            id: pillLayout
            anchors.centerIn: parent
            spacing: 2

            // Date circle at the top
            Loader {
                Layout.alignment: Qt.AlignHCenter
                active: Config.bar.clock.showDate
                visible: active
                sourceComponent: StyledRect {
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 12
                    color: Colours.palette.m3primaryContainer

                    StyledText {
                        anchors.centerIn: parent
                        text: Time.format("d")
                        font: Tokens.font.body.builders.small.scale(0.85).bold().build()
                        color: Colours.palette.m3onPrimaryContainer
                    }
                }
            }

            // Bold stacked hours in Primary color
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Time.hourStr
                font: root.font.scale(1.2).bold().build()
                color: Colours.palette.m3primary
            }

            // Separator dot
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 4
                height: 4
                radius: 2
                color: Colours.palette.m3outline
                
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 1000; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutQuad }
                }
            }

            // Bold stacked minutes in Secondary color
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Time.minuteStr
                font: root.font.scale(1.2).bold().build()
                color: Colours.palette.m3secondary
            }
        }
    }
}
