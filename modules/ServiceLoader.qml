import QtQuick
import Quickshell
import Nilastia.Config
import qs.services
import Nilastia.Services

Scope {
    Component.onCompleted: {
        // Force certain singletons to load on shell init instead of lazily

        IdleInhibitor;
        GameMode;
        Notifs;
        Players;
        Brightness;
        Weather.reload();
        Compositor;
        SystemBluetooth;
        Hotspot;

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }
}
