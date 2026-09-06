pragma Singleton

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    property alias enabled: inhibitorSettings.enabled
    property date enabledSince: new Date()

    Settings {
        id: inhibitorSettings
        category: "IdleInhibitor"
        property bool enabled: false
    }

    onEnabledChanged: {
        if (enabled) {
            enabledSince = new Date();
            systemdInhibitProc.running = true;
            Quickshell.execDetached(["/usr/bin/pkill", "-x", "swayidle"]);
            Quickshell.execDetached(["niri", "msg", "action", "power-on-monitors"]);
        } else {
            systemdInhibitProc.running = false;
        }
    }

    Process {
        id: systemdInhibitProc
        command: ["systemd-inhibit", "--what=idle:sleep:handle-lid-switch", "--who=Nilastia", "--why=Keep Awake enabled", "sleep", "infinity"]
        running: inhibitorSettings.enabled
    }

    Component.onCompleted: {
        Quickshell.execDetached(["/usr/bin/pkill", "-f", "systemd-inhibit --what=idle:sleep:handle-lid-switch --who=Nilastia"]);
        if (root.enabled) {
            systemdInhibitProc.running = false;
            systemdInhibitProc.running = true;
        }
    }

    Component.onDestruction: {
        Quickshell.execDetached(["/usr/bin/pkill", "-f", "systemd-inhibit --what=idle:sleep:handle-lid-switch --who=Nilastia"]);
    }

    IdleInhibitor {
        enabled: root.enabled
        window: PanelWindow {
            visible: root.enabled
            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayershell.Background
            WlrLayershell.keyboardFocus: WlrLayershell.None
        }
    }

    function isEnabled(): bool {
        return root.enabled;
    }

    function toggle(): void {
        root.enabled = !root.enabled;
    }

    function enable(): void {
        root.enabled = true;
    }

    function disable(): void {
        root.enabled = false;
    }

    IpcHandler {
        target: "idleInhibitor"

        function isEnabled(): bool {
            return root.enabled;
        }

        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            root.enable();
        }

        function disable(): void {
            root.disable();
        }
    }
}
