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
    property bool wasForcedOpaque: false

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

    Connections {
        target: GlobalConfig.general.battery
        function onAdaptiveRefreshRateChanged(): void {
            outputsQuery.running = true;
        }
        function onAdaptiveBlurChanged(): void {
            root.applyAdaptiveBlur();
            root.applyAdaptiveOpacity();
        }
        function onAdaptiveOpacityChanged(): void {
            root.applyAdaptiveOpacity();
        }
    }

    function applyAdaptiveBlur(): void {
        const targetWindowBlur = GlobalConfig.general.battery.adaptiveBlur && UPower.onBattery
            ? false
            : GlobalConfig.general.battery.preferredWindowBlur;
        const targetLayerBlur = GlobalConfig.general.battery.adaptiveBlur && UPower.onBattery
            ? false
            : GlobalConfig.general.battery.preferredLayerBlur;

        if (Compositor.window_blur_enabled !== targetWindowBlur) {
            console.log("[AdaptiveBlur] Updating window_blur_enabled to", targetWindowBlur);
            Compositor.saveValue("window_blur_enabled", targetWindowBlur);
        }
        if (Compositor.layer_blur_enabled !== targetLayerBlur) {
            console.log("[AdaptiveBlur] Updating layer_blur_enabled to", targetLayerBlur);
            Compositor.saveValue("layer_blur_enabled", targetLayerBlur);
        }
    }

    function applyAdaptiveOpacity(): void {
        const forceOpaque = GlobalConfig.general.battery.adaptiveBlur && GlobalConfig.general.battery.adaptiveOpacity && UPower.onBattery;

        if (forceOpaque) {
            if (!root.wasForcedOpaque) {
                if (Compositor.active_opacity > 0) {
                    GlobalConfig.general.battery.preferredActiveOpacity = Compositor.active_opacity;
                }
                if (Compositor.inactive_opacity > 0) {
                    GlobalConfig.general.battery.preferredInactiveOpacity = Compositor.inactive_opacity;
                }
                GlobalConfig.general.battery.preferredShellTransparency = GlobalConfig.appearance.transparency.enabled;
                root.wasForcedOpaque = true;
            }

            console.log("[AdaptiveOpacity] Forcing 100% opacity on active, inactive windows, and shell on battery");
            if (Compositor.active_opacity !== 1.0) {
                Compositor.saveValue("active_opacity", 1.0);
            }
            if (Compositor.inactive_opacity !== 1.0) {
                Compositor.saveValue("inactive_opacity", 1.0);
            }
            if (GlobalConfig.appearance.transparency.enabled) {
                GlobalConfig.appearance.transparency.enabled = false;
            }
        } else {
            if (root.wasForcedOpaque) {
                root.wasForcedOpaque = false;
                const targetActive = GlobalConfig.general.battery.preferredActiveOpacity;
                const targetInactive = GlobalConfig.general.battery.preferredInactiveOpacity;
                const targetShell = GlobalConfig.general.battery.preferredShellTransparency;

                console.log("[AdaptiveOpacity] Restoring opacities: active=" + targetActive + " inactive=" + targetInactive + " shell=" + targetShell);
                if (Compositor.active_opacity !== targetActive) {
                    Compositor.saveValue("active_opacity", targetActive);
                }
                if (Compositor.inactive_opacity !== targetInactive) {
                    Compositor.saveValue("inactive_opacity", targetInactive);
                }
                if (GlobalConfig.appearance.transparency.enabled !== targetShell) {
                    GlobalConfig.appearance.transparency.enabled = targetShell;
                }
            }
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
            root.applyAdaptiveOpacity();

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
            root.applyAdaptiveOpacity();
            root.handleBatteryWarnings();
        }

        target: UPower.displayDevice
    }

    Component.onCompleted: {
        if (!UPower.onBattery) {
            if (Compositor.active_opacity > 0 && GlobalConfig.general.battery.preferredActiveOpacity === 1.0 && Compositor.active_opacity !== 1.0) {
                GlobalConfig.general.battery.preferredActiveOpacity = Compositor.active_opacity;
            }
            if (Compositor.inactive_opacity > 0 && GlobalConfig.general.battery.preferredInactiveOpacity === 0.85 && Compositor.inactive_opacity !== 0.85) {
                GlobalConfig.general.battery.preferredInactiveOpacity = Compositor.inactive_opacity;
            }
            if (!GlobalConfig.general.battery.adaptiveOpacity) {
                GlobalConfig.general.battery.preferredShellTransparency = GlobalConfig.appearance.transparency.enabled;
            }
        }
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
