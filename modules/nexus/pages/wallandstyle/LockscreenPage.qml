pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Lockscreen & Idle")
    isSubPage: true

    readonly property list<MenuItem> lockTimeoutsList: [
        MenuItem { text: qsTr("1 minute"); property int value: 60 },
        MenuItem { text: qsTr("2 minutes"); property int value: 120 },
        MenuItem { text: qsTr("3 minutes"); property int value: 180 },
        MenuItem { text: qsTr("5 minutes"); property int value: 300 },
        MenuItem { text: qsTr("10 minutes"); property int value: 600 },
        MenuItem { text: qsTr("15 minutes"); property int value: 900 },
        MenuItem { text: qsTr("30 minutes"); property int value: 1800 },
        MenuItem { text: qsTr("Never"); property int value: 0 }
    ]

    readonly property list<MenuItem> dpmsTimeoutsList: [
        MenuItem { text: qsTr("1 minute"); property int value: 60 },
        MenuItem { text: qsTr("2 minutes"); property int value: 120 },
        MenuItem { text: qsTr("3 minutes"); property int value: 180 },
        MenuItem { text: qsTr("5 minutes"); property int value: 300 },
        MenuItem { text: qsTr("10 minutes"); property int value: 600 },
        MenuItem { text: qsTr("15 minutes"); property int value: 900 },
        MenuItem { text: qsTr("30 minutes"); property int value: 1800 },
        MenuItem { text: qsTr("Never"); property int value: 0 }
    ]

    readonly property list<MenuItem> suspendTimeoutsList: [
        MenuItem { text: qsTr("5 minutes"); property int value: 300 },
        MenuItem { text: qsTr("10 minutes"); property int value: 600 },
        MenuItem { text: qsTr("15 minutes"); property int value: 900 },
        MenuItem { text: qsTr("30 minutes"); property int value: 1800 },
        MenuItem { text: qsTr("45 minutes"); property int value: 2700 },
        MenuItem { text: qsTr("1 hour"); property int value: 3600 },
        MenuItem { text: qsTr("Never"); property int value: 0 }
    ]

    function getTimeoutItem(list, val) {
        for (let i = 0; i < list.length; i++) {
            if (list[i].value === val) return list[i];
        }
        return list[0];
    }

    function updateIdleTimeout(index, val, idleAction, returnAction) {
        let currentList = JSON.parse(JSON.stringify(GlobalConfig.general.idle.timeouts));
        if (!currentList || currentList.length <= index) return;
        currentList[index].timeout = val;
        currentList[index].enabled = (val > 0);
        if (idleAction) currentList[index].idleAction = idleAction;
        if (returnAction) currentList[index].returnAction = returnAction;
        GlobalConfig.general.idle.timeouts = currentList;
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            text: qsTr("Inactivity & Power Timeouts")
        }

        SelectRow {
            first: true
            label: qsTr("Screen lock timeout")
            subtext: qsTr("Time of inactivity before automatically locking screen")
            menuItems: root.lockTimeoutsList
            active: root.getTimeoutItem(root.lockTimeoutsList, GlobalConfig.general.idle.timeouts[0]?.timeout ?? 180)
            onSelected: item => root.updateIdleTimeout(0, item.value, "lock")
        }

        SelectRow {
            label: qsTr("Screen turn-off (DPMS) timeout")
            subtext: qsTr("Time of inactivity before turning displays off")
            menuItems: root.dpmsTimeoutsList
            active: root.getTimeoutItem(root.dpmsTimeoutsList, GlobalConfig.general.idle.timeouts[1]?.timeout ?? 300)
            onSelected: item => root.updateIdleTimeout(1, item.value, "dpms off", "dpms on")
        }

        SelectRow {
            last: true
            label: qsTr("System suspend timeout")
            subtext: qsTr("Time of inactivity before system enters sleep state")
            menuItems: root.suspendTimeoutsList
            active: root.getTimeoutItem(root.suspendTimeoutsList, GlobalConfig.general.idle.timeouts[2]?.timeout ?? 600)
            onSelected: item => root.updateIdleTimeout(2, item.value, ["suspendThenHibernate"])
        }

        SectionHeader {
            text: qsTr("Behavior & Smart Rules")
        }

        ToggleRow {
            first: true
            text: qsTr("Lock before sleep")
            subtext: qsTr("Automatically lock the screen before system suspends")
            checked: GlobalConfig.general.idle.lockBeforeSleep
            onToggled: GlobalConfig.general.idle.lockBeforeSleep = checked
        }

        ToggleRow {
            text: qsTr("Inhibit idle when gaming & Bottles")
            subtext: qsTr("Prevent automatic lock or DPMS off during games, Bottles, Wine, or GameMode")
            checked: GlobalConfig.general.idle.inhibitWhenGaming
            onToggled: GlobalConfig.general.idle.inhibitWhenGaming = checked
        }

        ToggleRow {
            text: qsTr("Inhibit idle when audio/media playing")
            subtext: qsTr("Prevent automatic lock while playing music or video streams")
            checked: GlobalConfig.general.idle.inhibitWhenAudio
            onToggled: GlobalConfig.general.idle.inhibitWhenAudio = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Inhibit idle when charging")
            subtext: qsTr("Prevent automatic lock when connected to AC power")
            checked: GlobalConfig.general.idle.inhibitWhenCharging
            onToggled: GlobalConfig.general.idle.inhibitWhenCharging = checked
        }
    }
}
