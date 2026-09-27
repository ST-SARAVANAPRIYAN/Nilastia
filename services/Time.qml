pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Nilastia.Config
import qs.utils

Singleton {
    id: root

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

    PersistentProperties {
        id: clockSettings

        reloadableId: "desktopClock"

        property bool hasCustomPosition: false
        property real offsetX: 0
        property real offsetY: 0
        property real customScale: 1.0
        property string timeFormat: "12h"
        property bool showAmPm: true
        property bool lockPosition: false
    }

    property alias clockHasCustomPosition: clockSettings.hasCustomPosition
    property alias clockOffsetX: clockSettings.offsetX
    property alias clockOffsetY: clockSettings.offsetY
    property alias clockCustomScale: clockSettings.customScale
    property alias clockTimeFormat: clockSettings.timeFormat
    property alias clockShowAmPm: clockSettings.showAmPm
    property alias clockLockPosition: clockSettings.lockPosition

    property bool isStorageLoaded: false

    FileView {
        id: clockStorage
        path: Paths.state ? `${Paths.state}/desktop_clock.json` : ""
        printErrors: false

        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (data.offsetX !== undefined)
                    clockSettings.offsetX = Number(data.offsetX);
                if (data.offsetY !== undefined)
                    clockSettings.offsetY = Number(data.offsetY);
                if (data.customScale !== undefined)
                    clockSettings.customScale = Number(data.customScale);
                if (data.hasCustomPosition !== undefined)
                    clockSettings.hasCustomPosition = Boolean(data.hasCustomPosition);
                if (data.timeFormat !== undefined)
                    clockSettings.timeFormat = String(data.timeFormat);
                if (data.showAmPm !== undefined)
                    clockSettings.showAmPm = Boolean(data.showAmPm);
                if (data.lockPosition !== undefined)
                    clockSettings.lockPosition = Boolean(data.lockPosition);
            } catch (e) {
                console.warn("[Time.qml] Error reading desktop_clock.json:", e);
            }
            root.isStorageLoaded = true;
        }

        onLoadFailed: err => {
            root.isStorageLoaded = true;
            if (err === FileViewError.FileNotFound) {
                Qt.callLater(() => saveClockState());
            }
        }
    }

    function saveClockState(): void {
        if (!isStorageLoaded || !Paths.state) return;
        const state = {
            hasCustomPosition: clockSettings.hasCustomPosition,
            offsetX: clockSettings.offsetX,
            offsetY: clockSettings.offsetY,
            customScale: clockSettings.customScale,
            timeFormat: clockSettings.timeFormat,
            showAmPm: clockSettings.showAmPm,
            lockPosition: clockSettings.lockPosition
        };
        clockStorage.setText(JSON.stringify(state, null, 2));
    }

    Timer {
        id: saveTimer
        interval: 300
        repeat: false
        onTriggered: saveClockState()
    }

    Connections {
        target: clockSettings
        function onHasCustomPositionChanged() { if (root.isStorageLoaded) saveTimer.restart(); }
        function onOffsetXChanged() { if (root.isStorageLoaded) saveTimer.restart(); }
        function onOffsetYChanged() { if (root.isStorageLoaded) saveTimer.restart(); }
        function onCustomScaleChanged() { if (root.isStorageLoaded) saveTimer.restart(); }
        function onTimeFormatChanged() { if (root.isStorageLoaded) saveTimer.restart(); }
        function onShowAmPmChanged() { if (root.isStorageLoaded) saveTimer.restart(); }
        function onLockPositionChanged() { if (root.isStorageLoaded) saveTimer.restart(); }
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    function resetClock(): void {
        clockSettings.hasCustomPosition = false;
        clockSettings.offsetX = 0;
        clockSettings.offsetY = 0;
        clockSettings.customScale = 1.0;
        clockSettings.lockPosition = false;
        saveClockState();
    }

    IpcHandler {
        target: "clock"

        function reset(): void {
            Time.resetClock();
        }

        function unlock(): void {
            clockSettings.lockPosition = false;
            Time.saveClockState();
        }

        function lock(): void {
            clockSettings.lockPosition = true;
            Time.saveClockState();
        }

        function toggleLock(): void {
            clockSettings.lockPosition = !clockSettings.lockPosition;
            Time.saveClockState();
        }
    }
}
