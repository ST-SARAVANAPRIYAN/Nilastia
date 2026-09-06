pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false
    property var defaultAdapter: root
    property var devices: ({ "values": [] })

    readonly property Process statusProc: Process {
        command: ["sh", "-c", "if rfkill list bluetooth 2>/dev/null | grep -q 'Soft blocked: yes'; then echo 'off'; elif bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then echo 'on'; else echo 'off'; fi"]
        stdout: SplitParser {
            onRead: function(line) {
                let clean = line.trim();
                if (clean === "on") {
                    root.enabled = true;
                } else if (clean === "off") {
                    root.enabled = false;
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statusProc.running)
                statusProc.running = true;
        }
    }

    Timer {
        id: refreshTimer
        interval: 500
        onTriggered: {
            if (!statusProc.running)
                statusProc.running = true;
        }
    }

    function enable(): void {
        enabled = true;
        Quickshell.execDetached(["sh", "-c", "rfkill unblock bluetooth 2>/dev/null; sleep 0.2; bluetoothctl power on 2>/dev/null"]);
        refreshTimer.restart();
    }

    function disable(): void {
        enabled = false;
        Quickshell.execDetached(["sh", "-c", "bluetoothctl power off 2>/dev/null; sleep 0.2; rfkill block bluetooth 2>/dev/null"]);
        refreshTimer.restart();
    }

    function toggle(): void {
        if (enabled)
            disable();
        else
            enable();
    }

    IpcHandler {
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

        target: "bluetooth"
    }
}
