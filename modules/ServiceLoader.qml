import QtQuick
import Quickshell
import Caelestia.Config
import qs.services
import Caelestia.Services

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

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }
}
