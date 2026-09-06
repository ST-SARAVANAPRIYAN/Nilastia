pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Nilastia.Components
import Nilastia.Config
import Nilastia.Plugins
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus
import qs.modules.bar.popouts as BarPopouts

StyledRect {
    id: root

    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts

    readonly property var quickToggles: {
        const seenIds = new Set();
        const configured = Config.utilities.quickToggles;
        const list = [...configured];
        if (!list.some(item => item.id === "hotspot")) {
            list.splice(2, 0, { id: "hotspot", enabled: true });
        }
        if (!list.some(item => item.id === "keepAwake")) {
            list.splice(3, 0, { id: "keepAwake", enabled: true });
        }

        return list.filter(item => {
            if (!(item.enabled ?? true))
                return false;

            if (seenIds.has(item.id)) {
                return false;
            }

            if (item.id === "vpn") {
                return GlobalConfig.utilities.vpn.selectedProvider.length > 0;
            }

            seenIds.add(item.id);
            return true;
        });
    }

    implicitHeight: layout.implicitHeight + Tokens.padding.extraLargeIncreased

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        StyledText {
            Layout.bottomMargin: Tokens.spacing.medium - parent.spacing
            text: qsTr("Quick Toggles")
            font: Tokens.font.body.medium
        }

        Repeater {
            model: {
                const arr = root.quickToggles;
                const n = arr.length;
                if (n < 3)
                    return [arr];

                const k = Math.ceil(n / 6);
                const baseSize = Math.floor(n / k);
                const remainder = n % k;

                const subsets = [];
                let start = 0;

                for (let i = 0; i < k; i++) {
                    const size = baseSize + (i < remainder ? 1 : 0);
                    subsets.push(arr.slice(start, start + size));
                    start += size;
                }

                return subsets;
            }

            QuickToggleRow {}
        }
    }

    LoggingCategory {
        id: logCat

        name: "nilastia.utilities.toggles"
        defaultLogLevel: LoggingCategory.Info
    }

    component QuickToggleRow: ButtonRow {
        id: toggleRow

        required property var modelData

        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall

        Repeater {
            id: repeater

            model: toggleRow.modelData

            delegate: DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "wifi"
                    delegate: Toggle {
                        icon: "wifi"
                        checked: Nmcli.wifiEnabled
                        onClicked: Nmcli.toggleWifi()
                    }
                }
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: Toggle {
                        icon: "bluetooth"
                        checked: SystemBluetooth.enabled
                        onClicked: SystemBluetooth.toggle()
                    }
                }
                DelegateChoice {
                    roleValue: "hotspot"
                    delegate: Toggle {
                        icon: "wifi_tethering"
                        checked: Hotspot.enabled
                        onClicked: Hotspot.toggle()
                    }
                }
                DelegateChoice {
                    roleValue: "keepAwake"
                    delegate: Toggle {
                        icon: "coffee"
                        checked: IdleInhibitor.enabled
                        onClicked: IdleInhibitor.toggle()
                    }
                }
                DelegateChoice {
                    roleValue: "mic"
                    delegate: Toggle {
                        icon: "mic"
                        checked: !Audio.sourceMuted
                        onClicked: {
                            const audio = Audio.source?.audio;
                            if (audio)
                                audio.muted = !audio.muted;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "settings"
                    delegate: Toggle {
                        icon: "settings"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        isToggle: false
                        onClicked: {
                            root.screenState.utilities = false;
                            WindowFactory.create();
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "gameMode"
                    delegate: Toggle {
                        icon: "gamepad"
                        checked: GameMode.enabled
                        onClicked: GameMode.enabled = !GameMode.enabled
                    }
                }
                DelegateChoice {
                    roleValue: "dnd"
                    delegate: Toggle {
                        icon: "notifications_off"
                        checked: Notifs.dnd
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                }
                DelegateChoice {
                    roleValue: "vpn"
                    delegate: Toggle {
                        icon: "vpn_key"
                        checked: VPN.connected && VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        enabled: !VPN.connecting && !VPN.disconnecting
                        isToggle: VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        onClicked: VPN.toggle()
                    }
                }
                DelegateChoice {
                    roleValue: "reload"
                    delegate: Toggle {
                        icon: "refresh"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        isToggle: false
                        onClicked: {
                            root.screenState.utilities = false;
                            Quickshell.reload(true);
                        }
                    }
                }
                DelegateChoice {
                    delegate: EntryPointLoader {
                        id: entryLoader

                        required property var modelData

                        // qmllint disable missing-property
                        readonly property bool fillWidth: item?.fillWidth ?? true
                        readonly property bool shapeMorph: item?.shapeMorph ?? true
                        readonly property real shapeMorphExpansion: item?.shapeMorphExpansion ?? 0
                        // qmllint enable missing-property

                        entryPoint: {
                            const id = modelData.id;
                            const entry = Plugins.entryPoints(EntryPointType.QuickToggle).find(e => e.properties.name === id);
                            if (!entry)
                                console.warn(logCat, "No plugin entry point found for", id);
                            return entry;
                        }
                    }
                }
            }
        }
    }

    component Toggle: IconButton {
        inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
        fillWidth: true
        isToggle: true
        isRound: true
        shapeMorph: true
    }
}
