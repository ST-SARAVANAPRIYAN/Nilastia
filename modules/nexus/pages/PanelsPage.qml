import QtQuick.Layouts
import Nilastia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Panels")

    function getModeSubtext(enabled: bool, mode: string, defaultMode: string): string {
        if (!enabled)
            return qsTr("Disabled");
        const m = mode || defaultMode;
        if (m === "hover")
            return qsTr("Reveal on hover");
        if (m === "click")
            return qsTr("Reveal on click");
        return qsTr("Drag / Shortcut only");
    }

    function getOsdModeSubtext(enabled: bool, mode: string): string {
        if (!enabled)
            return qsTr("Disabled");
        const m = mode || "keys";
        if (m === "keys")
            return qsTr("Hardware keys only");
        if (m === "hover")
            return qsTr("Reveal on hover");
        if (m === "click")
            return qsTr("Reveal on click");
        return qsTr("Keys only");
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        NavRow {
            first: true
            icon: "dashboard"
            text: qsTr("Dashboard")
            subtext: root.getModeSubtext(Config.dashboard.enabled, Config.dashboard.revealMode, "hover")
            onClicked: root.nState.openSubPage(1)
        }

        NavRow {
            icon: "dock_to_bottom"
            text: qsTr("Taskbar")
            subtext: Config.bar.persistent ? qsTr("Always visible") : root.getModeSubtext(true, Config.bar.revealMode, "hover")
            onClicked: root.nState.openSubPage(2)
        }

        NavRow {
            icon: "apps"
            text: qsTr("Launcher")
            subtext: root.getModeSubtext(Config.launcher.enabled, Config.launcher.revealMode, "off")
            onClicked: root.nState.openSubPage(3)
        }

        NavRow {
            icon: "notifications"
            text: qsTr("Notifications")
            subtext: root.getModeSubtext(Config.sidebar.enabled, Config.sidebar.revealMode, "off")
            onClicked: root.nState.openSubPage(4)
        }

        NavRow {
            icon: "volume_up"
            text: qsTr("Volume & Brightness")
            subtext: root.getOsdModeSubtext(Config.osd.enabled, Config.osd.revealMode)
            onClicked: root.nState.openSubPage(11)
        }

        NavRow {
            last: true
            icon: "construction"
            text: qsTr("Utilities")
            subtext: root.getModeSubtext(Config.utilities.enabled, Config.utilities.revealMode, "hover")
            onClicked: root.nState.openSubPage(5)
        }
    }
}
