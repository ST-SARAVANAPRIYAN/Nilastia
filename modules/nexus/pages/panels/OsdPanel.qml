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
            text: qsTr("Keys only (Recommended)")
            value: "keys"
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

    title: qsTr("Volume & Brightness")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        // General
        SectionHeader {
            first: true
            text: qsTr("General")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Show the volume and brightness on-screen display")
            checked: Config.osd.enabled
            onToggled: GlobalConfig.osd.enabled = checked
        }

        SelectRow {
            label: qsTr("Reveal mode")
            subtext: qsTr("How to reveal the volume & brightness sliders on the right screen edge")
            menuItems: root.revealModeItems
            active: {
                const mode = Config.osd.revealMode || (Config.osd.showOnHover ? "hover" : "keys");
                return root.revealModeItems.find(i => i.value === mode) || root.revealModeItems[0];
            }
            onSelected: item => {
                GlobalConfig.osd.revealMode = item.value;
                GlobalConfig.osd.showOnHover = (item.value === "hover");
            }
        }

        ToggleRow {
            text: qsTr("Brightness slider")
            subtext: qsTr("Include brightness controls in the on-screen display")
            checked: Config.osd.enableBrightness
            onToggled: GlobalConfig.osd.enableBrightness = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Microphone indicator")
            subtext: qsTr("Show input microphone level changes in the OSD")
            checked: Config.osd.enableMicrophone
            onToggled: GlobalConfig.osd.enableMicrophone = checked
        }

        // Timing
        SectionHeader {
            text: qsTr("Timing")
        }

        StepperRow {
            first: true
            last: true
            label: qsTr("Auto-hide delay")
            subtext: qsTr("Milliseconds the slider stays visible after key press (ms)")
            value: Config.osd.hideDelay
            from: 500
            to: 5000
            stepSize: 250
            onMoved: v => GlobalConfig.osd.hideDelay = Math.round(v)
        }
    }
}
