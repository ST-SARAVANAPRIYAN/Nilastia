pragma Singleton

import QtQuick
import Qt.labs.settings
import Quickshell
import Nilastia.Config

Singleton {
    property alias enabled: clock.enabled
    readonly property date date: clock.date
    readonly property int hours: clock.hours
    readonly property int minutes: clock.minutes
    readonly property int seconds: clock.seconds

    readonly property string timeStr: format(GlobalConfig.services.useTwelveHourClock ? "hh:mm:A" : "hh:mm")
    readonly property list<string> timeComponents: timeStr.split(":")
    readonly property string hourStr: timeComponents[0] ?? ""
    readonly property string minuteStr: timeComponents[1] ?? ""
    readonly property string amPmStr: timeComponents[2] ?? ""

    function format(fmt: string): string {
        return Qt.formatDateTime(clock.date, fmt);
    }

    Settings {
        id: clockSettings
        category: "DesktopClock"
        property bool hasCustomPosition: false
        property real offsetX: 0
        property real offsetY: 0
        property real customScale: 1.0
        property string timeFormat: "12h"
        property bool showAmPm: true
        property bool lockPosition: true
    }

    property alias clockHasCustomPosition: clockSettings.hasCustomPosition
    property alias clockOffsetX: clockSettings.offsetX
    property alias clockOffsetY: clockSettings.offsetY
    property alias clockCustomScale: clockSettings.customScale
    property alias clockTimeFormat: clockSettings.timeFormat
    property alias clockShowAmPm: clockSettings.showAmPm
    property alias clockLockPosition: clockSettings.lockPosition

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }
}
