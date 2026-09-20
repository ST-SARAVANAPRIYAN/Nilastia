pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import qs.modules.nexus.common
import qs.components.controls

PageBase {
    id: root

    readonly property list<MenuItem> revealModeItems: [
        MenuItem {
            text: qsTr("Off (Shortcut only)")
            value: "off"
        },
        MenuItem {
            text: qsTr("Click")
            value: "click"
        },
        MenuItem {
            text: qsTr("Hover")
            value: "hover"
        }
    ]

    title: qsTr("Notifications")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Notification Center")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Enable the notification drawer on the right screen edge")
            checked: Config.sidebar.enabled
            onToggled: GlobalConfig.sidebar.enabled = checked
        }

        SelectRow {
            label: qsTr("Reveal mode")
            subtext: qsTr("How to reveal the notification center at the right screen edge")
            menuItems: root.revealModeItems
            active: {
                const mode = Config.sidebar.revealMode || (Config.sidebar.showOnHover ? "hover" : "off");
                return root.revealModeItems.find(i => i.value === mode) || root.revealModeItems[0];
            }
            onSelected: item => {
                GlobalConfig.sidebar.revealMode = item.value;
                GlobalConfig.sidebar.showOnHover = (item.value === "hover");
            }
        }

        StepperRow {
            last: true
            label: qsTr("Drag threshold")
            subtext: qsTr("Pixels dragged from the right edge before the notification center opens")
            value: Config.sidebar.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.sidebar.dragThreshold = v
        }
    }
}
