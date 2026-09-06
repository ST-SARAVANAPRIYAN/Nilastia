# Nilastia Component & Roadmap Status

This file tracks the active state of all Nilastia sub-projects and features to keep future agent pairs aligned on current focus and next steps.

---

## 🛠️ Component States

| Component / Sub-project | Directory | Status | Notes |
| :--- | :--- | :--- | :--- |
| **CLI Utility (`nilastia`)** | `cli/` | 🟢 Working | Python CLI for schemes, wallpapers, presets, doctor. |
| **Material You Generation** | `cli/src/nilastia/utils/` | 🟢 Working | Integrates `materialyoucolor` and `matugen` for shell schemes. |
| **Dynamic Wallpapers** | `modules/background/` | 🟢 Working | Supports static files, GIFs, videos, and parallax `.nilawall` presets. |
| **Lock Screen UI** | `modules/lock/` | 🟢 Working | Unified layout containing Clock, Date, ProfilePic, and PasswordInput. |
| **Kitty Config Generation** | `cli/src/nilastia/utils/` | 🟢 Working | Appends kitty material configurations dynamically. |
| **VSCode Config Generation** | `cli/src/nilastia/utils/` | 🟢 Working | Generates VSCode dynamic colors without losing config. |
| **Chromium Theme Integration**| `cli/src/nilastia/utils/` | 🟢 Working | Automates chrome/brave profile GTK system themes. |
| **Plugins Auto-UI Settings** | `modules/nexus/pages/` | 🟢 Working | Generates native QML settings controls dynamically from schemas. |
| **SDDM Custom Theme** | N/A | 🔴 Dropped | Reverted completely back to commit `f8fbae51` per user request. |

---

## 🚀 Active Roadmap

1.  **Develop Plugins & Extensions:**
    *   Maintain modular plugins and integration tools for additional desktop applications.
    *   Preserve customization schemes when adding new config targets.
2.  **Verify Shell Stability:**
    *   Ensure new widget pages (e.g. Nexus toggles) load and check system capabilities correctly before rendering.
3.  **TUI/CLI Alignment:**
    *   Keep doctor script packages checklists updated with system requirements.
4.  **Theme Restoration & Boot Alignment:**
    *   Resolved race conditions where `FileView` initialized paths before `Paths.state` resolved at boot, avoiding accidental resets to fallback themes.
5.  **PlatypusLink Integration:**
    *   Created and enabled the `saravana/platypuslink` plugin. Spawns a background Node.js process using native WebSockets and Quickshell's `SplitParser` to capture events from the `platypusd` local daemon, dynamically displaying calling overlay OSD panels.
    *   Rebuilt and compiled the Rust-based core daemon (`platypusd-core`) in release mode.
    *   Polished and redesigned the settings interface as a responsive, multi-page standalone desktop application featuring native sidebar navigation, high-performance folder-tree lazy loading via `ListView`, and automatic background management of the Rust daemon process.
    *   Fixed dynamic connectivity status tracking by adding `DeviceConnected` and `DeviceDisconnected` events to the websocket listener stream.
    *   Implemented native pairing configurations on the Devices tab by auto-detecting the host's local IP address and displaying a QR Code.
    *   Reworked the File Explorer to automatically start/stop the mobile file server, added List/Compact/Grid layout viewing modes, integrated a mobile delete endpoint (`/delete` route), and enabled opening clicked files in default system applications (via `/view`).
    *   Redesigned the Audio Sync configuration tab, adding a master ON/OFF switch, playback target devices selector (destination only vs both), fine-tuning sync slider range (-30ms to 30ms), and a dedicated stream start/stop trigger button.
    *   Fixed a window loading visibility bug by explicitly configuring the `visible: true` property on the standalone floating window, and resolved custom Menu attachment requirements by targeting the root item of the window.
    *   Reworked the File Explorer sorting interface into a unified, responsive segmented control button group (Name/Size/Date) with dynamic sorting direction indicators (▲/▼).
    *   Fixed the dropdown instant-close bug by individually disabling/enabling child rows (`SelectRow` and `SliderRow`) instead of toggling the parent `ColumnLayout` state, preventing QML layout passes from canceling active mouse event grabs.
    *   Implemented automatic background call audio exclusion by listening for active call state events and immediately disabling Wi-Fi speaker streaming (`wifi_speaker_active = false`) to bypass Wi-Fi/Bluetooth hardware antenna coexistence and routing conflicts.
    *   Implemented a robust startup shell cleanup sequence that terminates orphaned daemon (`platypusd-core`) and recorder (`parec`) processes, and unloads any left-over virtual `module-loopback` modules from previous shell sessions to prevent PipeWire pipeline congestion.
    *   Added a background audio stream migration sweep loop in `wifi_speaker.rs` using numeric sink ID resolution, ensuring newly spawned application streams are cleanly routed to the Wi-Fi speaker virtual sink without triggering infinite process spawning loops.
    *   Updated the Android mobile app (`MainActivity.kt`) to dynamically request `READ_PHONE_STATE` permissions at runtime, allowing correct interception of call state changes for auto-muting.
    *   Fixed the "Keep Awake" (caffeine) toggle by changing the underlying `IdleInhibitor` window size from 0x0 to 1x1, allowing the Wayland compositor to map the surface and register the inhibitor correctly.
    *   Created and installed a custom application desktop launcher (`nilastia-nexus.desktop`) to make opening the shell configuration settings (Nexus panel) searchable and launchable via application runner menus.
    *   **Parallax Refactor & Glide Transition:** Replaced CPU-bound spring physics inside `Wallpaper.qml` with lightweight hardware-accelerated ease-out cubic glides (duration configurable from 200ms to 2000ms), and added transition-linked workspace depth shifting. Replaced the legacy spring stiffness/damping controls in the Wallpaper Builder UI with a single Glide Duration slider and changed the sub-process invoker to pass the JSON string directly as an argument, fixing a long-standing shell compilation deadlock.
    *   **Interactive Desktop Clock Parallax Translation & Unpack Editor:** Exposed active parallax offsets to the root of `Wallpaper.qml` and applied a `Translate` transform to the clock loader in `Background.qml` to allow rendering the clock on the interactive `Bottom` layer shell layer rather than the non-interactive `Background` layer. Restored the portable, single-file base64 `.nilawall` format by adding a `--unpack` parser to `wallpaper_builder.py` that extracts config layers into temporary local files, preventing argument limits (`E2BIG`) and local parsing locks when editing active wallpapers.
    *   **Blur Shader Downscaling & Idle Shell Blur Deactivation:** Applied 4x buffer downscaling (`layer.textureSize`) and bilinear interpolation on full-screen backdrop and lockscreen blur shaders, dropping shader pixel fill overhead by 93.75%. Removed a debug `FrameAnimation` FPS tracker that triggered on every frame. Added an `anyPanelOpen` condition to the layershell `BackgroundEffect.blurRegion` on `ContentWindow.qml`, completely unregistering the blur region from Niri when all drawer panels are closed, avoiding idle compositor blur overhead and preserving native 144Hz.
    *   **Platypus Link Contacts & Dialer Integration (Smartwatch Mode):** Resolved a circular deadlock where setting the Bluetooth card profile to `off` during idle would cause the phone to report `is_connected=false` and clear the cached MAC address from the daemon. Modified the WebSocket event handler in the daemon (`ws.rs`) to retain the MAC address if provided in the payload, allowing successful card profile switching when a call starts. Created a dedicated "Call Gateway" page in `StandaloneSettings.qml` with a contacts explorer, automatic contact-list fetching from Android (`READ_CONTACTS`), and custom dialer keypad (`CALL_PHONE`) that allows placing calls directly from the desktop. Compiled the updated code into the new GitHub Release `v0.2.0` (`app-debug.apk`) and added an interactive APK download QR code card to the Desktop Settings UI.
6.  **Universal Shell Bluetooth Service & Power Transition Synchronization:**
    *   Created and registered `SystemBluetooth.qml` as a core service singleton, replacing fragile D-Bus-only adapter bindings.
    *   Resolved the Linux kernel / BlueZ `PowerState: off-blocked` deadlock by synchronizing `rfkill unblock` with `bluetoothctl power on` and `bluetoothctl power off` with `rfkill block`.
    *   Unified state bindings and toggle handlers across the Quick Settings drawer (`Toggles.qml`), Nexus Connected Devices page (`BluetoothPage.qml`), status bar icon (`BluetoothStatus.qml`), and Taskbar Bluetooth popout (`modules/bar/popouts/Bluetooth.qml`). Added IPC handler `target: "bluetooth"` for external CLI toggling.
7.  **Keep Awake (Caffeine / Idle Inhibition) Fix & Quick Toggle:**
    *   Added disk persistence via `QtCore.Settings` (`category: "IdleInhibitor"`) in `services/IdleInhibitor.qml`, eliminating state loss across reboots, logouts, and shell restarts.
    *   Integrated a dedicated `keepAwake` Quick Toggle button (coffee icon) into `modules/utilities/cards/Toggles.qml` and `plugin/src/Nilastia/Config/utilitiesconfig.hpp`, complete with auto-injection for existing user configs.
    *   Connected `IdleInhibitor.enabled` directly to `IdleMonitors.qml`'s root `enabled` binding, `handleIdleAction`, `SessionManager` lock connections, and `IdleMonitor` delegates, ensuring that all idle timers (screen lock at 3m, DPMS off at 5m, and suspend at 10m) are disabled when Keep Awake is active.
    *   Integrated a background `systemd-inhibit` process (`--what=idle:sleep:handle-lid-switch`) into `IdleInhibitor.qml` with automated process cleanup on start and destruction.
    *   Added instant display wake (`niri msg action power-on-monitors`) upon enabling Keep Awake.
    *   Clarified the label in `modules/nexus/pages/panels/UtilitiesPanel.qml` to "Keep awake card" so card visibility is no longer confused with the sleep inhibitor itself.
8.  **Native Wi-Fi Hotspot Feature (Simultaneous Wi-Fi Repeater Mode):**
    *   Rebuilt `Hotspot.qml` to support true simultaneous Wi-Fi client + Hotspot (AP-STA concurrency / Repeater mode):
        - When `create_ap` is available (installed via `linux-wifi-hotspot`), automatically runs `pkexec create_ap --daemon $BAND_OPT $CHAN_OPT wlan0 <upstream-iface> <SSID> <PASS>`.
        - Automatically detects `wlan0` channel and frequency band (2.4 GHz vs 5 GHz) to enforce `#channels <= 1` compliance on the Wi-Fi card.
        - Keeps `wlan0` 100% connected to the home Wi-Fi router with full working internet (0 packet loss, low latency) while broadcasting the hotspot on virtual adapter `ap0`.
        - Employs password-free Polkit rule (`90-org.opensuse.policykit.wihotspot.rules`) for seamless execution.
        - Provides automatic graceful fallback to standard NetworkManager hotspot if `create_ap` is absent.
    *   Eliminated the misleading `nm-applet` notification and network drops.
    *   Decoupled Taskbar Status Icons: Separated the `hotspot` symbol (`wifi_tethering`) from the `network` symbol (`signal_wifi_*_bar`) in `StatusIcons.qml` and `BarConfig` so both display independently when active without replacing each other.
    *   Fixed layout collision in `modules/bar/popouts/Network.qml` by computing explicit `implicitHeight` on the hotspot broadcasting card, eliminating overlapping text.
    *   Updated installer and dependency scripts (`cli/src/nilastia/subcommands/install.py`, `extras/install.sh`, `setup_nilastia.sh`) to include `hostapd` and `linux-wifi-hotspot-bin`.
    *   Integrated UI controls across the shell: Quick Toggle in `Toggles.qml` / `UtilitiesPanel.qml`, expandable `HotspotCard.qml` with credentials and QR code, dedicated settings sub-page `HotspotSettingsPage.qml`, and network popout controls.
9.  **Taskbar System Tray Activation & Settings Integration:**
    *   Enabled `tray` by default in `BarConfig` (`plugin/src/Nilastia/Config/barconfig.hpp`) and added auto-injection in `Bar.qml`'s entry repeater to support systems with existing saved configs.
    *   Added master `Enabled` toggle in `modules/nexus/pages/panels/taskbar/BarTray.qml` to configure tray visibility, recolouring, compact mode, and hover popouts directly from Nexus.
    *   Optimized `Tray.qml` to dynamically adjust visibility and height according to active StatusNotifierItem count.
10. **Dropdown Menus & PopupRow Visual Hierarchy Resolution:**
    *   Fixed a critical regression in `components/controls/Menu.qml` and `modules/nexus/common/PopupRow.qml` where attempting to read non-existent `item.window` caused `parent` to resolve to `null`, breaking all dropdown selectors (Color Palette, Theme Flavour, Taskbar popouts mode, Hotspot frequency band).
    *   Implemented robust parent tree walk to the window's root `contentItem` and `interactionWrapper`, guaranteeing proper rendering and outside-click dismissal across both drawer popouts and standalone floating windows.
11. **Parallax Wallpaper Create & Edit Options Restoration:**
    *   Resolved blank page bug in `WallpaperBuilder.qml` caused by `savePromptOverlay` declaring as a secondary root visual item, overriding `PageBase`'s single `default property Item contentChild` and orphaning the entire UI `ColumnLayout` (`parent = null`).
    *   Relocated `savePromptOverlay`, `previewImageComponent`, and `previewClockComponent` into `resources: [ ... ]` with `parent: root` on the overlay dialog, restoring `ColumnLayout` as the singular visual child in `flickable.contentItem` with full height and valid anchors.
    *   Fixed invalid tokens in `savePromptOverlay` (`Colours.surface`, `Colours.primary`, `Colours.outlineVariant`, `Colours.text`, `Tokens.font.heading.small`), updating them to standard M3 palette and typography tokens.
    *   Guarded config loader and unpacker execution to strictly run in edit mode (`editActiveWallpaperOnly`), preventing accidental state leaks into "Create New Parallax".
    *   Added active wallpaper type detection (`isCurrentParallax`) to gracefully disable "Edit Active Parallax" in `ParallaxFlow.qml` when a static picture is active, and added dynamic status banners in `WallpaperBuilder.qml`.
12. **Desktop Parallax Intensity & Sensitivity Alignment:**
    *   Implemented high-response curved mouse tracking (`Math.sign(tx) * Math.pow(Math.abs(tx), 0.7)`) in `Background.qml` to boost center-region cursor sensitivity by ~2.5x without dead-zones.
    *   Expanded displacement limits and preset ranges in `WallpaperBuilder.qml` and `wallpaper_builder.py` from 35/20px up to 75/45px (Balanced) and 130/80px (Cinematic) with manual tuning up to 180/120px.
    *   Proportionally scaled the live preview box displacement (`previewScaleX = parent.width / 1920.0`) in `WallpaperBuilder.qml` to guarantee 1:1 WYSIWYG parity between the preview card and physical desktop monitor.
    *   Refined `targetIntensity` in `Wallpaper.qml` to only freeze (`0.0`) when an application window is truly fullscreen (`root.wallpaperCovered`), retaining lively 65% depth motion during windowed desktop multitasking.
    *   Attenuated idle camera drift factor (`0.25x`) to eliminate directional interference with user mouse movements, and increased layer border scaling from `1.05` to `1.12` to prevent boundary seams during large glides.
13. **Dashboard Weather Component & Weather Tab Overflow Resolution:**
    *   Resolved text overflow in `SmallWeather.qml` where concatenating temperature and city into an unconstrained 28px demi-bold expanded font (`Weather.temp + " (" + Weather.city + ")"`) caused the headline to exceed the 275px card boundary and paint on top of the adjacent User card.
    *   Refactored `SmallWeather.qml` into a clean two-line vertical hierarchy: Line 1 displays `Weather.temp` in bold `Tokens.font.headline.medium`, and Line 2 displays `Weather.city • Weather.description` in `Tokens.font.body.small` with strict `elide: Text.ElideRight` and width bound to `maxAvailableTextWidth`.
    *   Added `clip: true` on the weather card `Rect` in `Dash.qml` to guarantee boundary containment.
    *   Hardened `WeatherTab.qml` against layout overflows by adding `width: parent ? parent.width : implicitWidth` to root, constraining header city and subtitle text with `elide: Text.ElideRight` and proportional width limits, and adding `clip: true` and child column bounding widths on the 7-day forecast card tiles.
14. **Platypus Plugin Rename, Daemon Lifecycle & Call Audio Routing Fixes:**
    *   **Plugin Renaming & Cleanup:** Renamed the entire plugin from `platypuslink` to `platypus` across the plugin repository (`/home/saravana/projects/nilastia-platypus-plugin`), installed plugin folder (`~/.local/share/nilastia/plugins/saravana.platypus`), desktop applications file (`nilastia-platypus.desktop`), UI headers, and `plugins.json`. Kept `platypuslink` IPC alias for backwards compatibility.
    *   **Unified Daemon Packaging & Runner:** Created `run_daemon.sh` with automatic executable discovery (`./bin/platypusd-core`, `~/.local/bin/platypusd-core`, `$PATH`, auto-build fallback), eliminating hardcoded developer paths and seamlessly linking daemon process lifecycle with the shell plugin.
    *   **Call Notification Visibility:** Fixed broken window setup in `CallPopup.qml` by switching from undefined `StyledWindow` to native Quickshell `PanelWindow` with top-right overlay anchoring (`WlrLayer.Overlay`, `WlrKeyboardFocus.None`), explicit dimensions (400x168), and integrated critical desktop notification alerts via `notify-send` on incoming calls.
    *   **Contacts Synchronization & Search:** Fixed `ContactsListSynced` WebSocket parsing in `ws.rs`, added persistent thread-safe caching in `AppState`, created `GET /api/v1/contacts` endpoint, and added instant search filtering and startup auto-fetching in `StandaloneSettings.qml`.
    *   **Desktop Mic & Speaker Call Audio Routing:** Upgraded `CallService` in daemon to automatically transition connected Bluetooth phone cards to headset profile (HFP/HSP), set up low-latency (40ms) bidirectional PipeWire loopbacks (`@DEFAULT_SINK@` and `@DEFAULT_SOURCE@`), filter out monitor devices, and cleanly teardown loops on call completion.
15. **Platypus Daemon Lifecycle Controls, Polling & Log Capture:**
    *   **Fixed Sub-process Restart Loop:** Diagnosed and resolved 5-second restart cycle caused by `exec cmd | tee` running in subshells, which caused the parent wrapper script to exit prematurely (`exit 0`). Replaced with direct `exec "$DAEMON_BIN" "$@"` so `platypusd-core` replaces the wrapper process and runs continuously in the foreground.
    *   **Dynamic Daemon Status Polling:** Implemented a repeating 3000ms timer in `Platypus.qml` calling `queryDaemonStatus()`, ensuring `isOnline` and device states accurately reflect live daemon availability rather than freezing on boot failure.
    *   **Sidebar & Settings UI Controls:** Added interactive Restart (`restart_alt`), Copy Logs (`content_copy`), and Refresh (`refresh`) buttons directly in the sidebar status card, and integrated a complete "Device & Service Settings" management section on Page 5 with a live status pill, action buttons, and scrollable log terminal previewing recent daemon output.
    *   **Universal Log Copying:** Integrated `Quickshell.clipboardText` and `wl-copy` to copy captured log history to the system clipboard, persisting logs to disk (`~/.local/state/nilastia/platypusd.log`) with visual desktop notifications.
16. **Platypus Shell Plugin Uninstallation & Standalone Review:**
    *   Uninstalled the `saravana.platypus` plugin from Nilastia shell (`~/.local/share/nilastia/plugins/saravana.platypus` removed, `saravana/platypus` removed from `~/.config/nilastia/plugins.json`, desktop launcher removed) per user request while UI redesign and Bluetooth/PipeWire call audio routing are refactored.
    *   Terminated background `platypusd-core` and Node WebSocket client processes.
    *   All source code and ongoing work safely preserved in the dedicated repositories (`/home/saravana/projects/nilastia-platypus-plugin` and `/home/saravana/projects/platypusd`).
17. **Dual-Session Hybrid GPU Architecture (`niri-session` vs `niri-session-gpu`):**
    *   Created dedicated `~/.config/niri/config-gpu.kdl` explicitly configuring `render-drm-device "/dev/dri/by-path/pci-0000:01:00.0-render"` to direct Niri's rendering to the NVIDIA GeForce RTX 4050 dGPU.
    *   Created executable wrappers in `~/.local/bin/` (`niri-session` and `niri-session-gpu`):
        - `niri-session-gpu`: Sets `NIRI_CONFIG`, unsets conflicting variables, launches session on dGPU, and cleans up on exit.
        - `niri-session`: Explicitly unsets any lingering GPU variables from systemd user manager before launching `/usr/bin/niri-session`, guaranteeing a clean, battery-saving Intel iGPU session by default.
18. **GPU Session 16 FPS PCIe Throttle Elimination & Universal Refresh Rate IPC:**
    *   **PCIe DMA Copy Bottleneck Resolution:** Resolved the critical 16 FPS / 62.5ms latency bottleneck in `niri-session-gpu` caused by the NVIDIA RTX 4050 idling in performance state P8 (315 MHz core, 405 MHz memory, PCIe Gen 1.1 @ 2.5 GT/s). Configured `niri-session-gpu` to elevate clocks out of P8 (`sudo nvidia-smi -pm 1`, `-lgc 600,2100`, `-lmc 5000,8001`) before launch and cleanly restore idle defaults on session exit via trap.
    *   **Universal Runtime Niri IPC (`output.py`):** Updated `cli/src/nilastia/subcommands/output.py` to immediately execute runtime Niri IPC commands (`niri msg output <name> mode/scale/vrr/off/on`), dynamically resolve active `NIRI_CONFIG` from systemd user environment, and keep sibling `eDP` outputs (`eDP-1` and `eDP-2`) synchronized in the configuration file.
    *   **Display Settings UI Decoupling (`DisplayPage.qml`):** Removed `disabled: GlobalConfig.general.battery.adaptiveRefreshRate` from the refresh rate selector, automatically resetting adaptive mode to manual upon user selection, and expanded the revert countdown from 5 to 15 seconds.
    *   **Dynamic Connector Probing (`power-change.sh`):** Dynamically probes the active eDP connector name from `niri msg -j outputs` instead of hardcoding `eDP-1`, ensuring AC/battery power transitions function seamlessly across all monitor naming configurations.
19. **Parallax Wallpaper Builder Live Layer Management & Smooth Slider Controls:**
    *   **Full Layer Management in Tuning View (Step 2):** Added Move Up (▲), Move Down (▼), and Delete controls directly to each layer card in Step 2, and embedded "Add Layer Image", "Insert Clock Layer", and "Auto-Distribute Depths" action buttons so users can add, delete, and reorder layers with real-time preview updates in Edit Mode.
    *   **Eliminated Slider Delegate Reloads:** Replaced plain JS object layers with dynamic `QtObject` instances created via `layerItemComp`. Mutating `.depth` and `.sensitivity` now emits standard QML property change signals without calling `layersListChanged()`, preventing `Repeater` from destroying and re-instantiating delegates mid-drag.
    *   **Mouse Wheel Incrementing:** Wrapped each slider in `CustomMouseArea` with `onWheel` handlers, enabling smooth 0.05 increments via mouse wheel without page scroll jumping or slider disruption.
    *   **Non-Destructive Step Transitions:** Preserved custom unpacked layer depths when switching between Step 1 and Step 2.
20. **Niri Desktop Keybind Integration for Nexus Settings:**
    *   Mapped `Mod+N` (Super+N) to Quickshell IPC endpoint `quickshell -c niri-nilastia-shell ipc call nexus open` in `niri/config.d/70-binds.kdl` and `~/.config/niri/config.d/70-binds.kdl`, enabling instant hotkey access to Nilastia Nexus configuration panel.
21. **Desktop Clock Dragging & Parallax Clock Interactivity:**
    *   Set default `lockPosition` to `false` in `services/Time.qml`, enabling direct desktop mouse dragging out of the box.
    *   Added right-click lock/unlock toggle and an interactive hover lock pill in `DesktopClock.qml` with double-click reset to default anchors.
    *   Exclusively routed parallax virtual clock layers to the interactive `Bottom` layer in `Background.qml`, eliminating non-interactive duplicates on `WlrLayer.Background` in `Wallpaper.qml`.
22. **Video & Live Wallpaper Window Auto-Pause:**
    *   Implemented `hasOpenWindows` (`Hypr.anyWindowVisible && !Hypr.inOverview`) in `Wallpaper.qml`, automatically pausing `MediaPlayer` and stopping `AnimatedImage` playback whenever application windows occupy the workspace.
    *   Automatically resumes playback when windows are minimized, closed, or when switching to an empty workspace / Niri overview.
23. **Parallax Engine & Shell Lightweight Optimizations:**
    *   **High-Res Texture Optimization:** Bound decoded raster dimensions (`sourceSize`) on base64 data URIs in `CachingImage.qml`, enforced `asynchronous: true` decoding, enabled `mipmap: true` and `cache: true` to prevent GPU texture cache thrashing and memory overhead when processing high-resolution (4K/8K) layer slices.
    *   **Hardware Scene Graph Translation:** Replaced dynamic property updates (`x`/`y`) in `Wallpaper.qml` with `transform: Translate` matrix operations, and added `visible: false` on `parallaxContainer` when wallpaper is covered to skip rendering.
    *   **Eliminated `pkexec` Polling Loop:** Replaced `pkexec create_ap --list-running` in `services/Hotspot.qml` with a zero-root `pgrep` check, eliminating periodic PAM root session launches every 5 seconds. Relaxed Bluetooth status polling timer in `SystemBluetooth.qml` to 3000ms.
24. **Wi-Fi Hotspot Toggle Zero-Latency Responsiveness & State Protection:**
    *   **Instant Optimistic UI Switching:** Modified `Hotspot.qml`'s `start()` and `stop()` to flip `root.enabled` immediately upon user toggle (0ms latency), resolving the multi-second UI lag and switch bounce.
    *   **Protected Busy Transition States:** Prevented asynchronous background `checkStatus` callbacks from overriding `root.enabled` while transitions are in progress (`if (root.busy) return;`).
    *   **Fixed Self-Matching `pgrep` Bug:** Replaced `pgrep -f "create_ap"` with `pgrep -x create_ap || ip link show ap0`, eliminating a critical bug where `pgrep -f` matched its own `/bin/sh` wrapper script and perpetually reported the hotspot as active. Added dual-interface stopping (`create_ap --stop wlan0` and `--stop ap0`).
25. **Wi-Fi Hotspot Connected Devices Discovery & Modern Nexus UI:**
    *   **Zero-Root Connected Devices Discovery:** Built a lightweight Python discovery probe running every 5s that correlates world-readable DHCP leases (`dnsmasq.leases`), ARP cache (`/proc/net/arp`), and wireless station diagnostics (`iw dev ap0 station dump`). Populates `Hotspot.clients` and `clientsCount` with device hostname, IP, MAC address, signal strength, and icon type.
    *   **Modern Material 3 Nexus Hotspot UI:** Completely redesigned `HotspotSettingsPage.qml` with dynamic connection status messages, unified settings group, reactive dirty detection with Reset and Filled Apply buttons, enhanced Scan to Connect QR card with a "Copy Password" action button, and a connected devices list featuring avatar icons, signal strength badges, and single-click device blocking.
    *   **Disk Persistence via `QtCore.Settings`:** Hotspot SSID, passphrase, band, and blocked MAC addresses are persisted across reboots and shell restarts.
26. **Desktop Parallax Windowed Motion Retention & True Layer-Sandwiched Clock Depth:**
    *   **Decoupled `wallpaperCovered` from Open Windows:** Separated `hasOpenWindows` (`Hypr.anyWindowVisible && !Hypr.inOverview`) from `wallpaperCovered` (`isFullscreen`), preventing open desktop windows from falsely flagging the wallpaper as covered and freezing parallax translations or hiding `parallaxContainer`. Parallax motion retains 65% depth glide during windowed desktop multitasking and 100% when no windows are open.
    *   **Layer-Sandwiched Virtual Clock Depth:** Split parallax layer rendering across Wayland layer shell surfaces. Layers before `virtual://clock` (`index < clockLayerIndex`) render on `WlrLayer.Background` inside `Wallpaper.qml`. The desktop clock renders on `WlrLayer.Bottom` inside `Background.qml`. Foreground layers (`index > clockLayerIndex`) render directly above the clock on `WlrLayer.Bottom` in `foregroundLayersContainer`.
    *   **Full Click-Through & Dragging Interactivity:** Foreground layers on `WlrLayer.Bottom` have `enabled: false`, allowing all mouse hover, click, and drag events to pass seamlessly through foreground image slices to `DesktopClock` beneath. Forwarded mouse coordinates from `DesktopClock`'s `dragArea` to the wallpaper target to eliminate cursor tracking stutters when moving across the clock.
27. **Android Circle to Search & Google Lens Plugin (`saravana/circletosearch`):**
    *   **Architecture & Repository:** Created standalone plugin repository in `/home/saravana/projects/nilastia-circle-to-search` and installed into `~/.local/share/nilastia/plugins/saravana.circletosearch`, registered in `~/.config/nilastia/plugins.json`.
    *   **Browser-Native Form POST Google Lens Integration:** Replaced Python automated HTTP requests with an automated HTML launcher (`/tmp/cts-lens.html`) that embeds the selection crop as base64 and populates a hidden `<form action="https://lens.google.com/upload?ep=subb&hl=en">` using HTML5 `DataTransfer`. When opened in Brave, the form POST is submitted directly from the browser's own session and origin. Completely eliminates Google's bot detection, session mismatches, and the permanent "Expired visual search" / infinite skeleton loading screens. Automatically stages image crops to clipboard (`wl-copy --type image/png`).
    *   **Docked & Resizable Niri Window Rules:** Configured Niri window rule in `~/.config/niri/config.d/30-window-rules.kdl` (`match app-id=r#"^brave-.*(google\.com|cts-lens).*"#`) with `open-floating true`, `default-floating-position x=24 y=54 relative-to="top-right"`, `default-column-width { fixed 480; }`, `default-window-height { fixed 980; }`, `min-width 360`, and `max-width 1200`. The side tab stays docked to the right edge and can be freely resized via `Mod + Right Click Drag` or `Mod + Minus / Equal`.
    *   **Multilingual Deep-Learning OCR Engine (13 Languages):**
        - Configured user-space `TESSDATA_PREFIX=~/.local/share/tessdata` populated with fast integer-quantized LSTM models (`tessdata_fast`): English, Japanese, Tamil, Hindi, Spanish, French, German, Simplified Chinese, Korean, Russian, Arabic, Italian, and Portuguese.
        - `backend/ocr.py` runs simultaneous multi-script detection (`-l eng+spa+fra+deu+jpn+tam+hin+chi_sim+kor+rus+ara+ita`) with zero root/sudo requirements, recognizing Latin, CJK, Devanagari, and Dravidian scripts in milliseconds.
    *   **Enhanced Live In-Place Translation:**
        - Optimized `backend/translate.py` with line deduplication and non-alphanumeric noise filtering, dropping batch translation latency to under 4 seconds.
        - Fixed circular QML width binding loops and text wrapping in `LiveTranslateOverlay.qml`, enforcing max width limits (`targetW: Math.max(modelData.w + 16, Math.min(transText.implicitWidth + 36, 420))`), centered vertical alignment, and smooth hover-to-copy interactions.
    *   **Google Lens Quad-Palette Screen Shimmer:** Replaced rainbow shader in `shaders/iridescent.frag` with Google Lens iconic 4-color palette (`#4285F4` Blue, `#EA4335` Red, `#FBBC05` Yellow, `#34A853` Green) flowing smoothly around screen perimeters with a 2px core and delicate 30px exponential atmospheric glow. Compiled with `/usr/lib/qt6/bin/qsb --qt6` into `shaders/iridescent.qsb`.
    *   **Intelligent Multi-Gesture Engine:**
        - **Closed Circle / Loop Detection:** When a circular or closed loop gesture is completed (`isLoop`), immediately and directly launches Google Lens visual search without requiring extra menu taps.
        - **Line Swipe Text Selection:** Drawing an open stroke across words detects intersecting words via `selectWordsIntersectingStroke(pts)` in `WordOverlay.qml`, highlighting them with Android teardrop draggable handles.
        - **Single-Tap Word Selection:** Tapping a word highlights it and positions start/end teardrop handles.
        - **Interactive Teardrop Drag Handles:** Draggable teardrop handles (`startHandleItem` and `endHandleItem`) on start/end words at `z: 15` allow dragging across text to dynamically expand or contract the selection range in real time.
    *   **Strict Material 3 UI & Total Emoji Elimination:** Removed all emojis across `ActionMenu.qml`, `BottomBar.qml`, `LiveTranslateOverlay.qml`, and `README.md`. Replaced with Nilastia `MaterialIcon` symbols (`travel_explore`, `content_copy`, `search`, `translate`, `gesture`, `auto_awesome`, `close`, `expand_more`, `arrow_forward`).
    *   **Dynamic Language Selector:** Added interactive language selector pill `[Auto-detect] -> [Target Language ▾]` to `BottomBar.qml` with an M3 popup menu containing popular target languages (English, Spanish, French, German, Tamil, Hindi, Japanese, etc.), updating translations dynamically on selection.
    *   **IPC & Hotkey Integration:** Mapped `Mod+S` (Super+S) in `niri/config.d/70-binds.kdl` to `quickshell -c niri-nilastia-shell ipc call circletosearch open`.
28. **CachyOS GRUB UEFI NVRAM Boot Registration:**
    *   Replaced the confusing dual "Windows Boot Manager" UEFI state where `Boot0003` was masquerading rEFInd under Windows branding.
    *   Executed `grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=cachyos --recheck`, registering `Boot0004* cachyos` pointing directly to `\EFI\cachyos\grubx64.efi`.
    *   Regenerated `/boot/grub/grub.cfg` with `grub-mkconfig`, applying the graphical CachyOS GRUB theme and detecting Windows Boot Manager on `/dev/nvme0n1p1` via `os-prober`.
    *   Configured `BootOrder: 0004,0003,0000,2001,2002,2003` so CachyOS GRUB sits at the very top of BIOS boot priority.
29. **Universal Browser Resolution & Responsive Side-Drawer Integration:**
    *   **Universal Browser Auto-Detection (`backend/lens.py`):** Replaced hardcoded browser calls with `resolve_browser(preferred)`. Auto-detects installed Chromium-based browsers (`brave`, `google-chrome-stable`, `google-chrome`, `chromium`, `chromium-browser`, `vivaldi`, `microsoft-edge`, `opera`) to launch in frameless native app mode (`--app=`, `--window-size=640,980`). If absent, falls back to Firefox-based browsers (`zen-browser`, `zen`, `firefox`, `librewolf`, `waterfox`, `floorp`) using `--new-window`, followed by standard desktop `xdg-open`.
    *   **Graceful Zero-Browser Fallback:** If no graphical browser binary exists, stages image crop to the system clipboard via `wl-copy` and triggers a desktop notification via `notify-send` alerting the user that the selection was copied and no browser was found.
    *   **640px Responsive Layout & Side-Tab Docking:** Added `<meta name="viewport" content="width=device-width, initial-scale=1">` to the generated Lens form launcher `/tmp/cts-lens.html`, allowing Google Lens results to reflow into a clean 2-column mobile/tablet responsive layout without horizontal scrolling.
    *   **Universal Chromium Niri Window Rules:** Updated `30-window-rules.kdl` regex to `match app-id=r#"^(brave|chrome|chromium|google-chrome|vivaldi|microsoft-edge|opera)-.*(google\.com|cts-lens).*"#`, ensuring all Chromium variants open as floating, borderless side-drawers at `default-column-width: 640`, `default-window-height: 980` docked at `x=24 y=54`.
    *   **Configurable Plugin Settings:** Defaulted `lensBrowser: "auto"` in `Settings.qml` and `Overlay.qml`, permitting users to either retain automatic resolution or specify any custom browser binary.


