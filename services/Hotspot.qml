pragma Singleton

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    property bool enabled: false
    property string activeProfile: ""
    property string ssid: props.ssid || "Edith"
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

    Settings {
        id: props
        category: "Hotspot"

        property string ssid: "Edith"
        property string password: "password123"
        property bool passwordEnabled: true
        property string band: "bg"
        property var blockedDevices: []
        property string previousWifi: ""
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
        Quickshell.execDetached(["sh", "-c", `iw dev ${root.ifname} station del ${cleanMac} 2>/dev/null; iw dev ap0 station del ${cleanMac} 2>/dev/null; nmcli con mod "Hotspot" 802-11-wireless.mac-address-denylist "${denylistStr}" 2>/dev/null`]);
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
        root.enabled = true;
        root.busy = true;
        if (stopProc.running)
            stopProc.running = false;

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
    pkexec create_ap --stop ap0 2>/dev/null

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
        root.enabled = false;
        root.busy = true;
        root.clients = [];
        root.clientsCount = 0;
        if (startProc.running)
            startProc.running = false;

        stopProc.exec(["/bin/sh", "-c", `
if command -v create_ap >/dev/null 2>&1; then
    pkexec create_ap --stop wlan0 2>/dev/null
    pkexec create_ap --stop ap0 2>/dev/null
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

    // Check if Hotspot is active via create_ap or NetworkManager and discover connected clients
    Process {
        id: checkStatus
        running: false
        command: [
            "python3",
            "-c",
            `import glob, json, subprocess, os

ap_ifaces = []
try:
    out = subprocess.check_output(["iw", "dev"], text=True, stderr=subprocess.DEVNULL)
    cur_iface = None
    for line in out.splitlines():
        line = line.strip()
        if line.startswith("Interface "):
            cur_iface = line.split()[1]
        elif cur_iface and line == "type AP":
            ap_ifaces.append(cur_iface)
except Exception:
    if os.path.exists("/sys/class/net/ap0"):
        ap_ifaces = ["ap0"]

if not ap_ifaces:
    try:
        lines = subprocess.check_output(["nmcli", "-t", "-f", "NAME", "connection", "show", "--active"], text=True, stderr=subprocess.DEVNULL)
        if "Hotspot" in lines.splitlines():
            ap_ifaces = ["wlan0"]
    except Exception:
        pass

if not ap_ifaces:
    print("INACTIVE:[]")
    exit(0)

leases = glob.glob("/tmp/create_ap*/*.leases") + glob.glob("/var/lib/misc/dnsmasq*.leases") + glob.glob("/var/lib/NetworkManager/dnsmasq*.leases")
lease_map = {}
for lp in leases:
    try:
        with open(lp, "r") as f:
            for line in f:
                parts = line.strip().split()
                if len(parts) >= 4:
                    mac = parts[1].lower()
                    ip = parts[2]
                    hostname = parts[3] if parts[3] != "*" else ""
                    lease_map[mac] = {"ip": ip, "hostname": hostname}
    except Exception:
        pass

try:
    with open("/proc/net/arp", "r") as f:
        for line in f.readlines()[1:]:
            parts = line.split()
            if len(parts) >= 6 and parts[5] in ap_ifaces:
                ip = parts[0]
                mac = parts[3].lower()
                if mac != "00:00:00:00:00:00" and mac not in lease_map:
                    lease_map[mac] = {"ip": ip, "hostname": ""}
except Exception:
    pass

clients = []
for iface in ap_ifaces:
    try:
        out = subprocess.check_output(["iw", "dev", iface, "station", "dump"], text=True, stderr=subprocess.DEVNULL)
        current_mac = None
        stations = {}
        for line in out.splitlines():
            line = line.strip()
            if line.startswith("Station"):
                current_mac = line.split()[1].lower()
                stations[current_mac] = {"signal": ""}
            elif current_mac and "signal:" in line:
                stations[current_mac]["signal"] = line.split("signal:")[1].strip().split()[0] + " dBm"

        for mac, sdata in stations.items():
            ldata = lease_map.get(mac, {})
            ip = ldata.get("ip", "Unknown IP")
            hostname = ldata.get("hostname", "")
            disp_name = hostname if hostname else (ip if ip != "Unknown IP" else mac)

            lower_name = disp_name.lower()
            if any(x in lower_name for x in ["phone", "android", "iphone", "poco", "redmi", "galaxy", "pixel", "oneplus", "xiaomi"]):
                icon = "smartphone"
            elif any(x in lower_name for x in ["laptop", "pc", "desktop", "macbook", "thinkpad", "arch", "fedora", "ubuntu", "win"]):
                icon = "laptop"
            elif any(x in lower_name for x in ["tv", "cast", "chromecast", "roku"]):
                icon = "tv"
            elif any(x in lower_name for x in ["ipad", "tablet", "tab"]):
                icon = "tablet"
            else:
                icon = "smartphone"

            clients.append({
                "mac": mac,
                "ip": ip,
                "hostname": hostname,
                "name": disp_name,
                "signal": sdata.get("signal", ""),
                "icon": icon
            })
    except Exception:
        pass

print("ACTIVE:" + json.dumps(clients))
`
        ]

        stdout: StdioCollector {
            id: statusCollector
            onStreamFinished: {
                if (root.busy)
                    return;
                const out = statusCollector.text?.trim() ?? "";
                if (out.startsWith("ACTIVE:")) {
                    const jsonStr = out.substring(7);
                    try {
                        const parsed = JSON.parse(jsonStr);
                        root.clients = Array.isArray(parsed) ? parsed : [];
                    } catch (e) {
                        root.clients = [];
                    }
                    root.clientsCount = root.clients.length;
                    root.enabled = true;
                    root.activeProfile = "Hotspot";
                } else {
                    root.enabled = false;
                    root.activeProfile = "";
                    root.clients = [];
                    root.clientsCount = 0;
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (root.busy)
                return;
            if (exitCode !== 0) {
                root.enabled = false;
                root.activeProfile = "";
                root.clients = [];
                root.clientsCount = 0;
            }
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
            if (exitCode !== 0) {
                root.enabled = false;
                Toaster.toast("Hotspot Error", "Failed to start Wi-Fi Hotspot", "wifi_tethering_error", Toast.Error);
            }
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
        id: refreshTimer
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

        function getClients(): string {
            return JSON.stringify(root.clients);
        }
    }
}
