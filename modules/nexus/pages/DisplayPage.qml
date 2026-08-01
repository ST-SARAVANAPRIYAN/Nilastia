import QtQuick
import QtQuick.Layouts
import QtQml
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Display")

    property var outputsData: ({})
    property list<string> outputNames: []
    property string selectedOutputName: ""

    // Loaded properties for the active output
    readonly property var activeOutputInfo: selectedOutputName ? outputsData[selectedOutputName] : null
    readonly property bool vrrSupported: activeOutputInfo ? activeOutputInfo.vrr_supported : false
    readonly property bool vrrEnabled: activeOutputInfo ? activeOutputInfo.vrr_enabled : false
    readonly property real currentScale: activeOutputInfo && activeOutputInfo.logical ? activeOutputInfo.logical.scale : 1.0

    // List of modes formatted for MenuItem
    property var rawModes: activeOutputInfo ? activeOutputInfo.modes : []
    property list<var> formattedModes: []

    // Rebuild formatted modes list when active output modes change
    onRawModesChanged: {
        let temp = [];
        if (rawModes) {
            for (let i = 0; i < rawModes.length; i++) {
                let m = rawModes[i];
                let refresh = (m.refresh_rate / 1000).toFixed(3);
                let labelText = m.width + "x" + m.height + " @ " + refresh + " Hz" + (m.is_preferred ? " (" + qsTr("preferred") + ")" : "");
                let valueText = m.width + "x" + m.height + "@" + refresh;
                temp.push({ text: labelText, value: valueText });
            }
        }
        root.formattedModes = temp;
    }

    function applyChange(modeVal, scaleVal, vrrVal, offVal) {
        if (!selectedOutputName) return;

        let cmd = ["caelestia", "output", selectedOutputName];
        if (offVal) {
            cmd.push("--off");
        } else {
            if (modeVal) {
                cmd.push("-m", modeVal);
            }
            if (scaleVal) {
                cmd.push("-s", String(scaleVal));
            }
            if (vrrVal) {
                cmd.push("--vrr");
            }
        }
        applyProcess.command = cmd;
        applyProcess.running = true;
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        height: implicitHeight
        spacing: Tokens.spacing.extraSmall / 2

        // Process to query active Niri outputs
        Process {
            id: refreshProcess
            running: true
            command: ["niri", "msg", "-j", "outputs"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        let data = JSON.parse(text);
                        root.outputsData = data;
                        let keys = Object.keys(data);
                        root.outputNames = keys;
                        if (keys.length > 0 && !keys.includes(root.selectedOutputName)) {
                            root.selectedOutputName = keys[0];
                        }
                    } catch (e) {
                        console.log("Failed to parse Niri outputs JSON:", e);
                    }
                }
            }
        }

        // Process to apply configuration changes
        Process {
            id: applyProcess
            running: false
            onRunningChanged: {
                if (!running) {
                    // Refresh data once settings are applied
                    refreshProcess.running = true;
                }
            }
        }

        // Dynamically generate menu items for outputs selection dropdown
        Instantiator {
            id: outputsInstantiator
            model: root.outputNames
            delegate: MenuItem {
                required property string modelData
                text: modelData
                value: modelData
            }
        }

        // Dynamically generate menu items for modes dropdown
        Instantiator {
            id: modesInstantiator
            model: root.formattedModes
            delegate: MenuItem {
                required property var modelData
                text: modelData.text
                value: modelData.value
            }
        }

        // Dynamically generate scaling items list
        readonly property list<MenuItem> scaleItems: [
            MenuItem {
                text: "1.0x (" + qsTr("No scaling") + ")"
                value: 1.0
            },
            MenuItem {
                text: "1.25x"
                value: 1.25
            },
            MenuItem {
                text: "1.5x"
                value: 1.5
            },
            MenuItem {
                text: "2.0x (" + qsTr("Double size") + ")"
                value: 2.0
            }
        ]

        function getActiveModeIndex(): int {
            if (!activeOutputInfo || !formattedModes || formattedModes.length === 0) return 0;
            let curIdx = activeOutputInfo.current_mode;
            if (curIdx >= 0 && curIdx < formattedModes.length) {
                return curIdx;
            }
            return 0;
        }

        function getActiveScaleIndex(): int {
            let sc = root.currentScale;
            if (sc === 1.25) return 1;
            if (sc === 1.5) return 2;
            if (sc === 2.0) return 3;
            return 0;
        }

        SectionHeader {
            first: true
            text: qsTr("Display Devices")
        }

        // Dropdown to select active output device
        SelectRow {
            first: true
            last: true
            label: qsTr("Active Display")
            subtext: qsTr("Select display device to configure")
            menuItems: outputsInstantiator.count > 0 ? outputsInstantiator.objects : []
            active: (outputsInstantiator.count > 0 && root.outputNames.length > 0) ? outputsInstantiator.objects[Math.max(0, root.outputNames.indexOf(root.selectedOutputName))] : null
            onSelected: item => {
                root.selectedOutputName = item.value;
            }
        }

        SectionHeader {
            text: qsTr("Display Configuration")
            visible: !!root.selectedOutputName
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            visible: !!root.selectedOutputName

            // Status Toggle
            ToggleRow {
                first: true
                text: qsTr("Enable Display")
                subtext: qsTr("Turn this display connector on or off")
                checked: activeOutputInfo ? !activeOutputInfo.off : true
                onToggled: {
                    let isOff = !checked;
                    root.applyChange(null, null, root.vrrEnabled, isOff);
                }
            }

            // Mode dropdown
            SelectRow {
                label: qsTr("Resolution")
                subtext: qsTr("Select output screen resolution and refresh rate")
                menuItems: modesInstantiator.count > 0 ? modesInstantiator.objects : []
                active: (modesInstantiator.count > 0 && root.formattedModes.length > 0) ? modesInstantiator.objects[root.getActiveModeIndex()] : null
                visible: activeOutputInfo ? !activeOutputInfo.off : false
                onSelected: item => {
                    root.applyChange(item.value, root.currentScale, root.vrrEnabled, false);
                }
            }

            // Scale dropdown
            SelectRow {
                label: qsTr("Scaling")
                subtext: qsTr("Adjust interface size scaling factor")
                menuItems: scaleItems
                active: scaleItems[root.getActiveScaleIndex()] ?? null
                visible: activeOutputInfo ? !activeOutputInfo.off : false
                onSelected: item => {
                    root.applyChange(null, item.value, root.vrrEnabled, false);
                }
            }

            // VRR Toggle
            ToggleRow {
                text: qsTr("Variable Refresh Rate")
                subtext: qsTr("Reduce screen tearing (FreeSync / G-Sync)")
                checked: root.vrrEnabled
                visible: activeOutputInfo ? (!activeOutputInfo.off && root.vrrSupported) : false
                onToggled: {
                    root.applyChange(null, root.currentScale, checked, false);
                }
            }

            // Adaptive Refresh Rate Toggle (for laptop battery saving)
            ToggleRow {
                last: true
                text: qsTr("Adaptive Refresh Rate")
                subtext: qsTr("Lower refresh rate automatically when running on battery")
                checked: GlobalConfig.general.battery.adaptiveRefreshRate
                visible: activeOutputInfo ? (selectedOutputName.startsWith("eDP-") && !activeOutputInfo.off) : false
                onToggled: {
                    GlobalConfig.general.battery.adaptiveRefreshRate = checked;
                    // Trigger a refresh/apply immediately based on current state
                    refreshProcess.running = true;
                }
            }
        }
    }
}
