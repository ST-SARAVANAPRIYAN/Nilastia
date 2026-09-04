pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Nilastia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    function isEntryOn(id: string): bool {
        const item = Config.bar.entries.find(e => e.id === id);
        return item ? (item.enabled ?? true) : false;
    }

    function setEntryOn(id: string, on: bool): void {
        let found = false;
        const next = Config.bar.entries.map(item => {
            if (item.id !== id)
                return item;
            found = true;
            return Object.assign({}, item, {
                enabled: on
            });
        });
        if (!found)
            next.push({
                id,
                enabled: on
            });
        GlobalConfig.bar.entries = next;
    }

    title: qsTr("Tray")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Show system tray icons on the taskbar")
            checked: root.isEntryOn("tray")
            onToggled: root.setEntryOn("tray", checked)
        }

        ToggleRow {
            text: qsTr("Background")
            disabled: !root.isEntryOn("tray")
            checked: Config.bar.tray.background
            onToggled: GlobalConfig.bar.tray.background = checked
        }

        ToggleRow {
            text: qsTr("Recolour icons")
            disabled: !root.isEntryOn("tray")
            checked: Config.bar.tray.recolour
            onToggled: GlobalConfig.bar.tray.recolour = checked
        }

        ToggleRow {
            text: qsTr("Compact")
            disabled: !root.isEntryOn("tray")
            checked: Config.bar.tray.compact
            onToggled: GlobalConfig.bar.tray.compact = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Popout on hover")
            subtext: qsTr("Show the tray menu popout when hovering")
            disabled: !root.isEntryOn("tray")
            checked: Config.bar.popouts.tray
            onToggled: GlobalConfig.bar.popouts.tray = checked
        }
    }
}
