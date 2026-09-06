pragma ComponentBehavior: Bound

import "lock"
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import Nilastia.Config
import Nilastia.Services
import qs.services

Scope {
    id: root

    required property Lock lock
    readonly property bool hasPlayer: Players.list.some(p => p.isPlaying) || (Audio.streams && Audio.streams.some(s => s.ready && !s.audio?.muted))
    readonly property bool isCharging: !UPower.onBattery
    readonly property bool isGaming: GameMode.enabled || (function() {
        const cls = Hypr.activeToplevel?.lastIpcObject?.class?.toLowerCase() || "";
        return cls.includes("bottles") || cls.includes("wine") || cls.includes("steam") || cls.includes("lutris") || cls.includes("heroic");
    })()

    readonly property bool enabled: {
        if (IdleInhibitor.enabled)
            return false;
        if (GlobalConfig.general.idle.inhibitWhenAudio && hasPlayer)
            return false;
        if (GlobalConfig.general.idle.inhibitWhenCharging && isCharging)
            return false;
        if (GlobalConfig.general.idle.inhibitWhenGaming && isGaming)
            return false;
        return true;
    }

    function handleIdleAction(action: var): void {
        if (!action || IdleInhibitor.enabled)
            return;

        if (action === "lock") {
            lock.lock.locked = true;
        } else if (action === "unlock") {
            lock.lock.locked = false;
        } else if (action === "dpms off") {
            Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"]);
        } else if (action === "dpms on") {
            // Niri automatically powers on monitors upon keyboard/mouse activity.
        } else if (typeof action === "string") {
            Hypr.dispatch(action);
        } else if (!SessionManager.exec(action)) {
            Quickshell.execDetached(action);
        }
    }

    Connections {
        function onAboutToSleep(): void {
            if (!IdleInhibitor.enabled && GlobalConfig.general.idle.lockBeforeSleep)
                root.lock.lock.locked = true;
        }

        function onLockRequested(): void {
            if (!IdleInhibitor.enabled)
                root.lock.lock.locked = true;
        }

        function onUnlockRequested(): void {
            root.lock.lock.unlock();
        }

        target: SessionManager
    }

    Connections {
        function onEnabledChanged(): void {
            if (IdleInhibitor.enabled) {
                Quickshell.execDetached(["niri", "msg", "action", "power-on-monitors"]);
            }
        }

        target: IdleInhibitor
    }

    Variants {
        model: GlobalConfig.general.idle.timeouts

        IdleMonitor {
            required property var modelData

            enabled: {
                if (IdleInhibitor.enabled || !root.enabled || !(modelData.enabled ?? true) || (modelData.timeout === 0))
                    return false;
                if (modelData.inhibitWhenAudio && root.hasPlayer)
                    return false;
                if (modelData.inhibitWhenCharging && root.isCharging)
                    return false;
                if (modelData.inhibitWhenGaming && root.isGaming)
                    return false;
                return true;
            }
            timeout: modelData.timeout
            respectInhibitors: modelData.respectInhibitors ?? true
            onIsIdleChanged: root.handleIdleAction(isIdle ? modelData.idleAction : modelData.returnAction)
        }
    }
}
