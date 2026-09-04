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
7.  **Keep Awake (Caffeine / Idle Inhibition) Fix:**
    *   Connected `IdleInhibitor.enabled` directly to `IdleMonitors.qml`'s root `enabled` binding, `handleIdleAction`, and `IdleMonitor` delegates, ensuring that all idle timers (screen lock at 3m, DPMS off at 5m, and suspend at 10m) are disabled when Keep Awake is active.
    *   Integrated a background `systemd-inhibit` process (`--what=idle:sleep:handle-lid-switch`) into `IdleInhibitor.qml` to prevent OS-level systemd suspend/sleep while Keep Awake is toggled on.
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
