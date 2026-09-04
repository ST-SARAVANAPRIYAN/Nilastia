pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    property alias enabled: props.enabled
    readonly property alias enabledSince: props.enabledSince

    onEnabledChanged: {
        if (enabled) {
            props.enabledSince = new Date();
            systemdInhibitProc.running = true;
        } else {
            systemdInhibitProc.running = false;
        }
    }

    PersistentProperties {
        id: props

        property bool enabled: false
        property date enabledSince

        reloadableId: "idleInhibitor"
    }

    Process {
        id: systemdInhibitProc
        command: ["systemd-inhibit", "--what=idle:sleep:handle-lid-switch", "--who=Nilastia", "--why=Keep Awake enabled", "sleep", "infinity"]
        running: props.enabled
    }

    IdleInhibitor {
        enabled: props.enabled
        window: PanelWindow {
            width: 1
            height: 1
            color: "transparent"
            mask: Region {}
            exclusionMode: PanelWindow.None
            WlrLayershell.layer: WlrLayershell.Background
            WlrLayershell.keyboardFocus: WlrLayershell.None
        }
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

        target: "idleInhibitor"
    }
}
