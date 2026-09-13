pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Wayland as Wayland

Singleton {
    id: root

    property alias enabled: props.enabled
    property date enabledSince: new Date()

    PersistentProperties {
        id: props

        property bool enabled: false

        reloadableId: "idleInhibitor"
    }

    onEnabledChanged: {
        if (enabled) {
            enabledSince = new Date();
            systemdInhibitProc.running = true;
            Quickshell.execDetached(["/usr/bin/pkill", "-x", "swayidle"]);
            Quickshell.execDetached(["niri", "msg", "action", "power-on-monitors"]);
            Quickshell.execDetached(["sh", "-c", "mkdir -p $HOME/.local/state/nilastia && touch $HOME/.local/state/nilastia/keepawake"]);
        } else {
            systemdInhibitProc.running = false;
            Quickshell.execDetached(["/usr/bin/pkill", "-f", "systemd-inhibit --what=idle:sleep:handle-lid-switch --who=Nilastia"]);
            Quickshell.execDetached(["rm", "-f", "/home/saravana/.local/state/nilastia/keepawake"]);
        }
    }

    Process {
        id: systemdInhibitProc
        command: ["systemd-inhibit", "--what=idle:sleep:handle-lid-switch", "--who=Nilastia", "--why=Keep Awake enabled", "sleep", "infinity"]
        running: props.enabled
    }

    Process {
        id: stateCheckProc
        command: ["sh", "-c", "test -f $HOME/.local/state/nilastia/keepawake && echo 1 || echo 0"]
        stdout: SplitParser {
            onRead: function(line) {
                let val = line.trim();
                if (val === "1" && !props.enabled) {
                    props.enabled = true;
                }
            }
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["/usr/bin/pkill", "-f", "systemd-inhibit --what=idle:sleep:handle-lid-switch --who=Nilastia"]);
        stateCheckProc.running = true;
        if (root.enabled) {
            systemdInhibitProc.running = false;
            systemdInhibitProc.running = true;
        }
    }

    Component.onDestruction: {
        Quickshell.execDetached(["/usr/bin/pkill", "-f", "systemd-inhibit --what=idle:sleep:handle-lid-switch --who=Nilastia"]);
    }

    Wayland.IdleInhibitor {
        enabled: root.enabled
        window: PanelWindow {
            screen: Quickshell.screens[0] ?? null
            visible: root.enabled
            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayershell.Background
            WlrLayershell.keyboardFocus: WlrLayershell.None
        }
    }

    function isEnabled() {
        return root.enabled;
    }

    function toggle() {
        root.enabled = !root.enabled;
    }

    function enable() {
        root.enabled = true;
    }

    function disable() {
        root.enabled = false;
    }

    IpcHandler {
        target: "idleInhibitor"

        function isEnabled() {
            return root.enabled;
        }

        function toggle() {
            root.toggle();
        }

        function enable() {
            root.enable();
        }

        function disable() {
            root.disable();
        }
    }
}
