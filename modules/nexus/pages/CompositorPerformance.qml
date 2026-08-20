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

    title: qsTr("Performance & GPU")

    readonly property list<MenuItem> gpuItems: [
        MenuItem { text: qsTr("Auto (System choice)"); property string value: "auto" },
        MenuItem { text: qsTr("Integrated GPU Only"); property string value: "igpu" },
        MenuItem { text: qsTr("Discrete GPU Only"); property string value: "dgpu" },
        MenuItem { text: qsTr("Adaptive Mode (AC/Battery)"); property string value: "adaptive" }
    ]

    function getActiveGpuItem(mode) {
        for (let i = 0; i < gpuItems.length; i++) {
            if (gpuItems[i].value === mode) return gpuItems[i];
        }
        return gpuItems[0];
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        // GPU Selection Section
        SectionHeader {
            first: true
            text: qsTr("GPU rendering profile")
        }

        SelectRow {
            first: true
            last: true
            label: qsTr("Preferred GPU")
            subtext: Gpu.name ? qsTr("Active Renderer: %1").arg(Gpu.name) : qsTr("Select rendering GPU")
            menuItems: root.gpuItems
            active: root.getActiveGpuItem(GlobalConfig.general.battery.gpuMode)
            onSelected: item => {
                GlobalConfig.general.battery.gpuMode = item.value;
            }
        }

        // Help Text
        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            Layout.bottomMargin: Tokens.spacing.large
            text: qsTr("Note: GPU switches require a desktop session restart to take effect. In adaptive mode, the GPU is chosen based on whether your charger is plugged in when the session starts.")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.Wrap
        }

        // Battery Power Optimisations
        SectionHeader {
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
