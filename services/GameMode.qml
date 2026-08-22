pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Nilastia
import Nilastia.Config
import qs.services

Singleton {
    id: root

    property alias enabled: props.enabled

    property bool originalAnimationsOff: false
    property bool originalBlurEnabled: true
    property bool originalStored: false

    onEnabledChanged: {
        if (enabled) {
            originalAnimationsOff = Compositor.animations_off;
            originalBlurEnabled = Compositor.window_blur_enabled;
            originalStored = true;

            Compositor.saveValue("animations_off", true);
            Compositor.saveValue("window_blur_enabled", false);

            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Game mode enabled"), qsTr("Disabled desktop animations and window background blur"), "gamepad");
        } else {
            if (originalStored) {
                Compositor.saveValue("animations_off", originalAnimationsOff);
                Compositor.saveValue("window_blur_enabled", originalBlurEnabled);
                originalStored = false;
            }
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Game mode disabled"), qsTr("Desktop settings restored"), "gamepad");
        }
    }

    PersistentProperties {
        id: props

        property bool enabled: false

        reloadableId: "gameMode"
    }

    IpcHandler {
        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            props.enabled = !props.enabled;
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }

        target: "gameMode"
    }
}
