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

    Rect {
        Layout.column: Config.dashboard.showWeather ? 2 : 0
        Layout.columnSpan: Config.dashboard.showWeather ? 3 : 5
        Layout.preferredWidth: Config.dashboard.showWeather ? Tokens.sizes.dashboard.userWidth : -1
        Layout.fillWidth: !Config.dashboard.showWeather
        Layout.fillHeight: true

        radius: Tokens.rounding.extraLarge

        User {
            id: user

            screenState: root.screenState
            facePicker: root.facePicker
        }
    }

    Rect {
        visible: Config.dashboard.showWeather
        Layout.row: 0
        Layout.columnSpan: 2
        Layout.preferredWidth: Tokens.sizes.dashboard.weatherWidth
        Layout.preferredHeight: weather.implicitHeight

        radius: Tokens.rounding.extraLarge * 1.5

        SmallWeather {
            id: weather
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
