import "dash"
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.services

GridLayout {
    id: root

    required property ScreenState screenState
    required property FileDialog facePicker

    rowSpacing: Tokens.spacing.medium
    columnSpacing: Tokens.spacing.medium

    // Row 0: Weather + User
    RowLayout {
        Layout.row: 0
        Layout.column: 0
        Layout.columnSpan: 5
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: Config.dashboard.showWeather ? weather.implicitHeight : 120
        spacing: Tokens.spacing.medium

        Rect {
            visible: Config.dashboard.showWeather
            Layout.preferredWidth: Tokens.sizes.dashboard.weatherWidth
            Layout.fillHeight: true

            radius: Tokens.rounding.extraLarge * 1.5

            SmallWeather {
                id: weather
            }
        }

        Rect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Tokens.rounding.extraLarge

            User {
                id: user

                screenState: root.screenState
                facePicker: root.facePicker
            }
        }
    }

    Rect {
        Layout.row: 1
        Layout.preferredWidth: dateTime.implicitWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.large

        DateTime {
            id: dateTime
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 1
        Layout.columnSpan: 3
        Layout.fillWidth: true
        Layout.preferredHeight: calendar.implicitHeight

        radius: Tokens.rounding.extraLarge

        Calendar {
            id: calendar

            screenState: root.screenState
        }
    }

    Rect {
        Layout.row: 1
        Layout.column: 4
        Layout.preferredWidth: resources.implicitWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.large

        Resources {
            id: resources
        }
    }

    Rect {
        Layout.row: 0
        Layout.column: 5
        Layout.rowSpan: 2
        Layout.preferredWidth: media.implicitWidth
        Layout.fillHeight: true

        radius: Tokens.rounding.extraLarge * 2

        Media {
            id: media
        }
    }

    component Rect: StyledRect {
        color: Colours.tPalette.m3surfaceContainer
    }
}
