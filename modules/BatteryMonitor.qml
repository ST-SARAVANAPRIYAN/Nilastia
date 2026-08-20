import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Nilastia
import Nilastia.Config
import Nilastia.Services

Scope {
    id: root

    readonly property list<var> warnLevels: [...GlobalConfig.general.battery.warnLevels].sort((a, b) => a.level - b.level)
    property real lastPercentage: 100

    // Process to query active Niri outputs and determine highest/lowest refresh rate modes
    Process {
        id: outputsQuery
        running: false
        command: ["niri", "msg", "-j", "outputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(text);
                    let edpKey = Object.keys(data).find(k => k.startsWith("eDP-"));
                    if (edpKey) {
                        let output = data[edpKey];
                        let modes = output.modes;
                        if (modes && modes.length > 0) {
                            // Sort modes by refresh_rate ascending (lowest first, highest last)
                            modes.sort((a, b) => a.refresh_rate - b.refresh_rate);
                            let lowest = modes[0];
                            let highest = modes[modes.length - 1];

                            let lowModeStr = lowest.width + "x" + lowest.height + "@" + (lowest.refresh_rate / 1000).toFixed(3);
                            let highModeStr = highest.width + "x" + highest.height + "@" + (highest.refresh_rate / 1000).toFixed(3);

                            if (GlobalConfig.general.battery.adaptiveRefreshRate) {
                                let targetMode = UPower.onBattery ? lowModeStr : highModeStr;
                                console.log("[AdaptiveRefreshRate] Setting display", edpKey, "to", targetMode);

                                applyAdaptiveRate.command = ["nilastia", "output", edpKey, "-m", targetMode];
                                applyAdaptiveRate.running = true;
                            } else {
                                // Restore highest refresh rate when adaptive is disabled
                                console.log("[AdaptiveRefreshRate] Disabled! Restoring highest rate:", highModeStr);
                                applyAdaptiveRate.command = ["nilastia", "output", edpKey, "-m", highModeStr];
                                applyAdaptiveRate.running = true;
                            }
                        }
                    }
                } catch (e) {
                    console.log("[AdaptiveRefreshRate] Failed to parse Niri outputs JSON:", e);
                }
            }
        }
    }

    // Process to apply the adaptive refresh rate changes
    Process {
        id: applyAdaptiveRate
        running: false
    }

    // Process to update Niri GPU selection rules
    Process {
        id: applyGpuSelector
        command: ["nilastia-gpu-select"]
        running: false
    }

    Connections {
        target: GlobalConfig.general.battery
        function onAdaptiveRefreshRateChanged(): void {
            outputsQuery.running = true;
        }
        function onAdaptiveBlurChanged(): void {
            root.applyAdaptiveBlur();
        }
        function onGpuModeChanged(): void {
            applyGpuSelector.running = true;
        }
    }

    function applyAdaptiveBlur(): void {
        if (GlobalConfig.general.battery.adaptiveBlur) {
            let enable = !UPower.onBattery;
            console.log("[AdaptiveBlur] Setting window and layer blur to", enable);
            Compositor.saveValue("window_blur_enabled", enable);
            Compositor.saveValue("layer_blur_enabled", enable);
        } else {
            console.log("[AdaptiveBlur] Disabled, restoring window and layer blur to true");
            Compositor.saveValue("window_blur_enabled", true);
            Compositor.saveValue("layer_blur_enabled", true);
        }
    }

    function handleBatteryWarnings(): void {
        const p = UPower.displayDevice.percentage * 100;

        if (!UPower.onBattery) {
            root.lastPercentage = p;
            return;
        }

        if (root.lastPercentage >= 0) {
            for (const level of root.warnLevels) {
                if (p <= level.level && root.lastPercentage > level.level) {
                    Toaster.toast(level.title ?? qsTr("Battery warning"), level.message ?? qsTr("Battery level is low"), level.icon ?? "battery_android_alert", level.critical ? Toast.Error : Toast.Warning);
                    break;
                }
            }
        }

        if (!hibernateTimer.running && p <= GlobalConfig.general.battery.criticalLevel) {
            Toaster.toast(qsTr("Hibernating in 5 seconds"), qsTr("Hibernating to prevent data loss"), "battery_android_alert", Toast.Error);
            hibernateTimer.start();
        }

        root.lastPercentage = p;
    }

    Connections {
        function onOnBatteryChanged(): void {
            if (!UPower.displayDevice.ready)
                return;

            if (GlobalConfig.general.battery.adaptiveRefreshRate) {
                outputsQuery.running = true;
            }

            if (GlobalConfig.general.battery.adaptiveBlur) {
                root.applyAdaptiveBlur();
            }

            if (GlobalConfig.general.battery.gpuMode === "adaptive") {
                applyGpuSelector.running = true;
            }

            if (UPower.onBattery) {
                if (GlobalConfig.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Charger unplugged"), qsTr("Battery is discharging"), "power_off");
                root.handleBatteryWarnings();
            } else {
                if (GlobalConfig.utilities.toasts.chargingChanged)
                    Toaster.toast(qsTr("Charger plugged in"), qsTr("Battery is charging"), "power");
                root.lastPercentage = 100;
            }
        }

        target: UPower
    }

    Connections {
        function onReadyChanged(): void {
            if (!UPower.displayDevice.ready)
                return;
            if (GlobalConfig.general.battery.adaptiveRefreshRate) {
                outputsQuery.running = true;
            }
            if (GlobalConfig.general.battery.adaptiveBlur) {
                root.applyAdaptiveBlur();
            }
            if (GlobalConfig.general.battery.gpuMode === "adaptive") {
                applyGpuSelector.running = true;
            }
            root.handleBatteryWarnings();
        }

        target: UPower.displayDevice
    }

    Connections {
        function onPercentageChanged(): void {
            if (!UPower.displayDevice.ready)
                return;
            root.handleBatteryWarnings();
        }

        target: UPower.displayDevice
    }

    Timer {
        id: hibernateTimer

        interval: 5000
        onTriggered: SessionManager.hibernate()
    }
}
