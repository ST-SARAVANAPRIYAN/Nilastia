pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    property bool enabled: false
    property string activeProfile: ""
    property string ssid: props.ssid || "Nilastia-Hotspot"
    property string password: props.password || "password123"
    property bool passwordEnabled: props.passwordEnabled !== undefined ? props.passwordEnabled : true
    property string band: props.band || "bg"
    property var blockedDevices: props.blockedDevices || []
    property var clients: []
    property int clientsCount: clients.length
    property string previousWifi: props.previousWifi || ""
    property string ifname: "wlan0"
    property bool busy: false

    readonly property string qrCodeData: passwordEnabled ? ("WIFI:S:" + ssid + ";T:WPA;P:" + password + ";;") : ("WIFI:S:" + ssid + ";T:nopass;;")

    PersistentProperties {
        id: props

        property string ssid: "Nilastia-Hotspot"
        property string password: "password123"
        property bool passwordEnabled: true
        property string band: "bg"
        property var blockedDevices: []
        property string previousWifi: ""

        reloadableId: "hotspotService"
    }

    function setSsid(name: string): void {
        if (!name || name.trim() === "")
            return;
        props.ssid = name.trim();
        root.ssid = props.ssid;
        if (root.enabled) {
            start();
        }
    }

    function setPassword(pass: string): void {
        if (!pass || pass.length < 8)
            return;
        props.password = pass;
        root.password = props.password;
        if (root.enabled) {
            start();
        }
    }

    function setPasswordEnabled(enable: bool): void {
        props.passwordEnabled = enable;
        root.passwordEnabled = enable;
        if (root.enabled) {
            start();
        }
    }

    function setBand(newBand: string): void {
        if (newBand !== "bg" && newBand !== "a")
            return;
        props.band = newBand;
        root.band = props.band;
        if (root.enabled) {
            start();
        }
    }

    function blockDevice(mac: string): void {
        if (!mac)
            return;
        const cleanMac = mac.trim().toLowerCase();
        let list = [...(props.blockedDevices || [])];
        if (!list.includes(cleanMac)) {
            list.push(cleanMac);
            props.blockedDevices = list;
            root.blockedDevices = list;
        }

        // Immediately kick station and update NetworkManager denylist
        const denylistStr = list.join(" ");
        Quickshell.execDetached(["sh", "-c", `iw dev ${root.ifname} station del ${cleanMac} 2>/dev/null; nmcli con mod "Hotspot" 802-11-wireless.mac-address-denylist "${denylistStr}" 2>/dev/null`]);
        refreshTimer.restart();
    }

    function unblockDevice(mac: string): void {
        if (!mac)
            return;
        const cleanMac = mac.trim().toLowerCase();
        let list = (props.blockedDevices || []).filter(m => m !== cleanMac);
        props.blockedDevices = list;
        root.blockedDevices = list;

        const denylistStr = list.join(" ");
        Quickshell.execDetached(["sh", "-c", `nmcli con mod "Hotspot" 802-11-wireless.mac-address-denylist "${denylistStr}" 2>/dev/null`]);
        refreshTimer.restart();
    }

    function refreshStatus(): void {
        checkStatus.running = false;
        checkStatus.running = true;
    }

    function start(): void {
        root.busy = true;
        const curSsid = root.ssid;
        const curPass = root.passwordEnabled ? root.password : "";
        const curPassEnabled = root.passwordEnabled ? "true" : "false";

        startProc.exec(["/bin/sh", "-c", `
SSID="$1"
PASS="$2"
PASS_ENABLED="$3"
IFACE="wlan0"

if command -v create_ap >/dev/null 2>&1; then
    pkexec create_ap --stop "$IFACE" 2>/dev/null

    CHANNEL=$(iw dev "$IFACE" info 2>/dev/null | awk '/channel/{print $2}')
    BAND_OPT=""
    CHAN_OPT=""
    if [ -n "$CHANNEL" ]; then
        CHAN_OPT="-c $CHANNEL"
        if [ "$CHANNEL" -gt 14 ]; then
            BAND_OPT="--freq-band 5"
        else
            BAND_OPT="--freq-band 2.4"
        fi
    fi

    INTERNET_IFACE="$IFACE"
    if [ -d "/sys/class/net/enp7s0" ] && [ "$(cat /sys/class/net/enp7s0/operstate 2>/dev/null)" = "up" ]; then
        INTERNET_IFACE="enp7s0"
    fi

    if [ "$PASS_ENABLED" = "true" ] && [ -n "$PASS" ] && [ "\${#PASS}" -ge 8 ]; then
        pkexec create_ap --daemon $BAND_OPT $CHAN_OPT "$IFACE" "$INTERNET_IFACE" "$SSID" "$PASS"
    else
        pkexec create_ap --daemon $BAND_OPT $CHAN_OPT -w 0 "$IFACE" "$INTERNET_IFACE" "$SSID"
    fi
else
    nmcli connection delete id Hotspot 2>/dev/null
    if [ "$PASS_ENABLED" = "true" ] && [ -n "$PASS" ] && [ "\${#PASS}" -ge 8 ]; then
        exec nmcli dev wifi hotspot con-name Hotspot ssid "$SSID" password "$PASS"
    else
        exec nmcli dev wifi hotspot con-name Hotspot ssid "$SSID"
    fi
fi
`, "sh", curSsid, curPass, curPassEnabled]);
    }

    function stop(): void {
        root.busy = true;
        stopProc.exec(["/bin/sh", "-c", `
if command -v create_ap >/dev/null 2>&1; then
    pkexec create_ap --stop wlan0 2>/dev/null
fi
nmcli connection down Hotspot 2>/dev/null
`]);
    }

    function toggle(): void {
        if (root.enabled) {
            stop();
        } else {
            start();
        }
    }

    // Check if Hotspot is active via create_ap or NetworkManager
    Process {
        id: checkStatus
        running: false
        command: ["/bin/sh", "-c", `
if command -v create_ap >/dev/null 2>&1; then
    RUNNING=$(pkexec create_ap --list-running 2>/dev/null)
    if echo "$RUNNING" | grep -q "wlan0"; then
        CLIENTS=$(pkexec create_ap --list-clients ap0 2>/dev/null | grep -cE "^[0-9a-fA-F:]+")
        echo "ACTIVE:$CLIENTS"
        exit 0
    fi
fi
if nmcli -t -f NAME connection show --active 2>/dev/null | grep -q "^Hotspot$"; then
    echo "ACTIVE:0"
    exit 0
fi
echo "INACTIVE:0"
`]

        stdout: StdioCollector {
            id: statusCollector
            onStreamFinished: {
                const out = statusCollector.text?.trim() ?? "";
                if (out.startsWith("ACTIVE:")) {
                    const parts = out.split(":");
                    root.enabled = true;
                    root.activeProfile = "Hotspot";
                    root.clientsCount = parts.length > 1 ? (parseInt(parts[1]) || 0) : 0;
                } else {
                    root.enabled = false;
                    root.activeProfile = "";
                    root.clientsCount = 0;
                }
                root.busy = false;
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.enabled = false;
                root.activeProfile = "";
                root.clientsCount = 0;
            }
            root.busy = false;
        }
    }

    // Start process
    Process {
        id: startProc
        running: false

        stderr: StdioCollector {
            id: startErrCollector
        }

        onExited: (exitCode, exitStatus) => {
            root.busy = false;
            root.refreshStatus();
        }
    }

    // Stop process
    Process {
        id: stopProc
        running: false

        onExited: (exitCode, exitStatus) => {
            root.busy = false;
            root.refreshStatus();
        }
    }

    // Periodic check every 5 seconds (identical to iNiR)
    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: root.refreshStatus()
    }

    Component.onCompleted: root.refreshStatus()

    IpcHandler {
        target: "hotspot"

        function isEnabled(): bool {
            return root.enabled;
        }

        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            root.start();
        }

        function disable(): void {
            root.stop();
        }

        function getSsid(): string {
            return root.ssid;
        }

        function getClientsCount(): int {
            return root.clientsCount;
        }
    }
}
