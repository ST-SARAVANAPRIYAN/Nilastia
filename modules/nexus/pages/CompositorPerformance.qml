import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import Nilastia.Services
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root
    isSubPage: true

    title: qsTr("Performance")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        // Battery Power Optimisations
        SectionHeader {
            first: true
            text: qsTr("Power Optimisations")
        }

        ToggleRow {
            first: true
            text: qsTr("Adaptive display refresh rate")
            subtext: qsTr("Switch to 60Hz on battery power, and maximum refresh rate on AC power")
            checked: GlobalConfig.general.battery.adaptiveRefreshRate
            onToggled: GlobalConfig.general.battery.adaptiveRefreshRate = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Adaptive compositor blur")
            subtext: qsTr("Temporarily disable window and layer blur on battery power to extend battery life")
            checked: GlobalConfig.general.battery.adaptiveBlur
            onToggled: GlobalConfig.general.battery.adaptiveBlur = checked
        }
    }
}
