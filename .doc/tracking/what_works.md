# Nilastia Verified Features & Testing Procedures

This document lists all system features that are confirmed working, along with their exact paths, target scripts, and test commands.

---

## 🎨 Material You & Schemes Applying

### What Works
*   The `nilastia scheme` utility successfully generates a complete material palette from an image (using `materialyoucolor` and `matugen`) and applies it dynamically to various configurations.
*   **Kitty Terminal Integration:** Safely appends color specifications to kitty's config and triggers live reload.
*   **VSCode Integration:** Modifies VSCode settings JSON programmatically, updating visual elements without altering the user's settings formatting or invalidating JSON structures.
*   **Web Browsers:** Automatically edits Chromium/Brave preferences to enforce GTK system theme matching.

### How to Test / Run
```bash
# Set a theme scheme by name and notify system processes
nilastia scheme set --name nilastia --notify
```

---

## 🖼️ Wallpaper Management

### What Works
*   Changing and linking wallpapers works dynamically.
*   **Active Symlinks:**
    *   `/home/saravana/.local/state/nilastia/wallpaper/current`: Symlink pointing to the current active wallpaper source file (which can be a static image, a GIF, a video, or a dynamic `.nilawall` JSON config).
    *   `/home/saravana/.local/state/nilastia/wallpaper/thumbnail.jpg`: A `128x128` pixel JPEG thumbnail generated for style panel previews.
*   **Supported File Types:**
    *   Static images (`.png`, `.jpg`, `.jpeg`, `.webp`).
    *   Animated GIFs: Extracts the first frame dynamically to serve as a static fallback.
    *   Videos: Uses `ffmpeg` to capture the first frame.
    *   Parallax Wallpapers (`.nilawall` / `.json`): A JSON layout structure holding multi-layered images. Parallax motion uses a clean, hardware-accelerated ease-out glide (800ms OutCubic) instead of heavy spring physics, and incorporates automatic depth shifts linked to active workspace/launcher navigation transitions for a highly fluid and spatial responsiveness.

### How to Test / Run
```bash
# Set a new wallpaper file
nilastia wallpaper set /path/to/your/wallpaper.jpg
```

---

## 🔒 Lock Screen Interface

### What Works
*   The system lockscreen loads via Quickshell using the unified center-column widget structure.
*   Layout contains:
    *   **Clock & Date:** Styled and centered at the top.
    *   **PasswordInput:** Center field with text input masking, incorrect password shaking animations, and PAM integration.

---

## 🧩 Plugins Configuration Interface

### What Works
*   **Dual Sourcing:** The plugins detail panel dynamically parses the installer state:
    *   **Not Installed:** Only displays the fetched markdown documentation (`README.md`).
    *   **Installed:** Reveals the configuration settings panel on top of the documentation layout.
*   **Auto-Generated Settings UI:** If a plugin declares configuration variables in its settings schema but provides no custom QML (`settingsUi`), Nilastia automatically generates and renders a pixel-perfect interface.
*   **Supported Input Elements:**
    *   **Boolean:** Renders a native toggle (`StyledSwitch`) inside a styled card.
    *   **Numeric (Slider / SpinBox):** Renders a system-styled `StyledSlider` or numeric stepper reflecting `min`/`max`/`step` ranges.
    *   **Text:** Renders a native `StyledTextField`.
    *   **Choices / Dropdowns:** Auto-detects if the setting specifies `options` metadata, and dynamically generates an option stepper selection row (arrows cycle through option strings safely).
*   **Themed Layout:** Automatically wraps generated settings inside `ConnectedRect` containers, matching the native rounded-card style used on other settings pages.
*   **Type Auto-Detection:** Automatically resolves the control type based on the value's JS type if no explicit QML `inputType` metadata is defined.

### How to Test / Run
1.  Open the settings panel (Nexus) and navigate to **Plugins**.
2.  Install any plugin declaring configurations (e.g., `FluidChargingRipple`).
3.  Click the plugin card to open details: the custom settings block will be auto-generated using native card styling. Adjusting any of the sliders (speed, density, width, distortion), toggle switches (auto-theme), text boxes (manual hex color), or arrows (animation style) dynamically modifies the settings and live-refreshes the active desktop shell.

---

## Dynamic Plugin Keybindings & Compositor Injection

### What Works
*   **Declarative Plugin Shortcuts:** Plugins declare their keyboard shortcuts in `manifest.json` under `"binds": [ { "key": "Mod+S", "ipc": "circletosearch open", "description": "..." } ]`.
*   **Automatic Niri Synchronization (`75-plugin-binds.kdl`):**
    *   `Plugins::syncCompositorBinds()` aggregates shortcuts across all enabled plugins and writes them into `~/.config/niri/config.d/75-plugin-binds.kdl`.
    *   Ensures `include "config.d/75-plugin-binds.kdl"` is added to `~/.config/niri/config.kdl` if not already present.
    *   Cleans legacy hardcoded lines from `~/.config/niri/config.d/70-binds.kdl` to prevent duplicate keybind clashes in Niri.
*   **Live Lifecycle Reactivity:**
    *   **Install / Enable:** Instantly injects the plugin's binds into `75-plugin-binds.kdl` and triggers `niri msg action load-config-file`. The keybind works immediately without restarting the session.
    *   **Disable / Uninstall:** Instantly purges the plugin's binds from `75-plugin-binds.kdl` and reloads Niri config.
*   **Zero-Hardcoding in Plugins:**
    *   `CircleToSearch` and `Yoink` resolve `pluginDir` dynamically via `entryPoint.plugin.dir` with `Qt.resolvedUrl(".")` fallback, eliminating hardcoded user directories.

### How to Test / Run
1.  Check generated compositor binds:
    ```bash
    cat ~/.config/niri/config.d/75-plugin-binds.kdl
    ```
2.  Press `Mod+S` to trigger Circle to Search or `Mod+Shift+Y` to trigger Yoink screenshot overlay.
3.  Disable `CircleToSearch` in Nexus Plugins: verify `Mod+S` is removed from `75-plugin-binds.kdl` and Niri reloads. Re-enable to verify immediate restoration.

---

## 🎨 SDF Blob Blending & Rendering Fixes

### What Works
*   **No Bleeding/Artifacts:** Closed panels (like Dashboard and Utilities) sitting offscreen no longer warp the screen border or bleed color/SDF calculations due to the visibility checks.
*   **No Double-Drawing Lines (1px Seams):** Active panels (like the Utilities panel on the right) no longer show a thin 1px vertical gray line next to their outer boundaries. This is resolved by the distance-based discard check inside the shader (`mySdf > smoothFactor`), preventing the fullscreen screen-frame renderer from double-drawing the boundary pixels of other shapes.
*   **Cleaner Closed Panel Tracking:** Bound `sessionBg` and `osdBg` panel properties in `ContentWindow.qml` to their actual inner components rather than wrappers, ensuring they are completely hidden and skipped when not active.

### How to Test / Run
1.  Open the Quick Toggles panel (Utilities) using CLI or hotkeys:
    ```bash
    quickshell ipc -i <instance_id> call drawers toggle utilities
    ```
2.  Observe the left edge of the Utilities panel. The thin vertical gray line that previously floated to the left of the card in the wallpaper background area is now completely gone.
3.  Toggle the Dashboard: the horizontal line/strip artifact along the bottom edge is also completely gone.

---

## 🔒 Theme Mode & Boot Restoration

### What Works
*   **Race-Free Startup Paths:** Prevented `FileView` instances in `Colours.qml` and `Wallpapers.qml` from loading empty or invalid paths (`/scheme.json`, `/wallpaper/path.txt`) at shell initialization before `Paths.state` is resolved. This eliminates the race condition that caused the shell to run destructive wallpaper-reset helper commands at boot, preserving the user's custom color scheme.
*   **Reliable Mode Transitions:** Ensures that the active dark/light mode configurations are loaded cleanly and applied immediately to the shell without requiring retoggling.

---

## 🦦 PlatypusLink Integration Plugin

### What Works
*   **Decoupled Node.js Daemon Helper:** Since the `qt6-websockets` QML module is not installed on this host, the plugin launches a background Node.js helper ([`client.js`](file:///home/saravana/.local/share/nilastia/plugins/saravana.platypuslink/client.js)) leveraging native `WebSocket` support to communicate with `platypusd` and automatically handle reconnection logic.
*   **Automatic Rust Daemon Management:** [`PlatypusLink.qml`](file:///home/saravana/.local/share/nilastia/plugins/saravana.platypuslink/PlatypusLink.qml) automatically spawns, monitors, and auto-restarts the compiled Rust daemon binary (`platypusd-core`) directly.
*   **SplitParser Event Stream:** [`PlatypusLink.qml`](file:///home/saravana/.local/share/nilastia/plugins/saravana.platypuslink/PlatypusLink.qml) consumes stdout line-by-line asynchronously using Quickshell's native `SplitParser`.
*   **Visual Alert Overlays:** Automatically loads [`CallPopup.qml`](file:///home/saravana/.local/share/nilastia/plugins/saravana.platypuslink/CallPopup.qml) when a call is active (in `Ringing`, `Connected`, or `Muted` states) centering a Material-styled modal on top of all active monitors.
*   **Integrated REST Actions:** Pressing Answer/Mute/Decline sends direct HTTP POST requests to `/api/v1/calls/action` to command the mobile device.
*   **Responsive Multi-page Desktop Client Window:** [`StandaloneSettings.qml`](file:///home/saravana/.local/share/nilastia/plugins/saravana.platypuslink/StandaloneSettings.qml) renders a responsive, native-feeling device synchronization desktop client with sidebar-based navigation.
    *   *Dashboard:* Displays system info, active phone pairing details (IP, Wi-Fi link state) that update dynamically when the phone connects/disconnects, and a scrollable synced clipboard view.
    *   *Clipboard Sync:* Full-width text entry field allowing user to push custom text to the mobile device.
    *   *File Explorer:* Supports List, Compact, and Grid layout viewing modes. Automatically commands the phone server to start/stop on tab transition, opens clicked files in Brave/system default browser (via the phone's `/view` route), and supports downloading and recursively deleting mobile files/directories (via `/delete` route).
    *   *Audio Sync:* Configuration page matching Tauri options: includes an Overall Master switch, playback target devices selector (destination only vs both), fine-tuning sync delay offset slider (-30ms to +30ms), and a dedicated Start/Stop Syncing button. Features robust mutual exclusion that automatically turns off Wi-Fi streaming when an active call is connected.
    *   *Call Gateway:* A dedicated, independent section featuring custom smartwatch-style outbound dialing, a synced contacts viewer with direct-dial buttons, an inline Android contacts search/sync fetcher (`FetchContacts`), and Call Routing Gateway switches.
    *   *Devices & Settings:* Displays a pairing QR Code containing auto-detected host connection details and paired mobile devices.

### How to Test / Run
1. Redesigned client will auto-start the compiled daemon. Verify the daemon process is active:
   ```bash
   pgrep -af platypusd-core
   ```
2. Open the desktop settings app using:
   ```bash
   qs -c niri-nilastia-shell ipc call platypuslink toggle
   ```
3. Click navigation items in the sidebar to switch tabs. Try browsing remote files, copying clipboard text, or modifying audio delay offsets.
4. In a terminal, run the following CLI command to simulate an incoming call:
   ```bash
   /home/saravana/projects/platypusd/target/release/platypus-cli simulate-call "+1234567890" "Alice Smith" "Ringing"
   ```
5. A centered glassmorphic popup card will appear on your desktop with Answer/Mute/Decline buttons. Clicking **Decline** or **Answer** will dismiss/update the alert.

---

## 🖼️ Portable Parallax Wallpaper Builder & Unpacker

### What Works
*   **Portable Format Output:** The Wallpaper Builder compiles custom wallpapers back into a single portable `.nilawall` file containing base64 data URIs for all layer images.
*   **JSON Config Unpacking:** When editing or loading a `.nilawall` file, a helper process executes `--unpack` to decode the layers into `/tmp/` files, avoiding command-line limit failures (`E2BIG`) when clicking Build.
*   **Interactive Desktop Clock:** The clock is always rendered on `WlrLayer.Bottom`, making it fully click-through, draggable, and resizable, even when using wallpapers with integrated clock layers. The clock is dynamically shifted in sync with the wallpaper's 3D parallax coordinates.

### How to Test / Run
1. Open the Nexus Style settings page, choose **Wallpaper & Style**, and click the edit icon on the active wallpaper.
2. The builder will successfully load all layers into the preview page, extracting them to `/tmp/`.
3. Try modifying the glide animation duration or depth, then click **Build & Apply**.
4. The wallpaper will re-compile instantly into a single self-contained `.nilawall` file in `~/Pictures/Wallpapers/` and be applied to the desktop.
5. In the settings page, untoggle **Lock clock position**, and verify you can drag and resize the desktop clock.

---

## ⚡ Performance & Battery Optimizations

### What Works
*   **Downscaled Fullscreen Blurs:** The backdrop wallpaper and screencopy lockscreen blurs use a 4x downscaled texture buffer (`layer.textureSize: Qt.size(width / 4, height / 4)`) combined with bilinear hardware filtering (`layer.smooth: true`), eliminating full-resolution shader pipelines.
*   **Sleeping Scene Graph:** Removed the continuous `FrameAnimation` component inside `Background.qml` that was incrementing frames on every display refresh cycle. The shell's rendering thread and systemd journals now completely sleep when the desktop is idle, drastically reducing CPU/GPU cycles and thermal output.
*   **Parallax Deactivation:** The wallpaper's active parallax translations smoothly slide down to `0.0` and freeze whenever any client application windows are visible on the active workspace, avoiding redundant calculations.
*   **Dynamic Shell Blur Deactivation:** The layershell `BackgroundEffect.blurRegion` on `ContentWindow.qml` evaluates to `null` unless the shell background is transparent (`root.surfaceColour.a < 1.0`) AND at least one drawer panel or popout is actively open (`root.anyPanelOpen`). This completely unregisters the blur area from Niri when drawers are closed, eliminating idle blur compositor workload.

### How to Test / Run
1. Open the system monitor or run `top`/`htop`.
2. Observe the CPU usage of the `quickshell` process when the desktop is static: it should settle at `0%` usage.
3. Open application windows and verify the desktop wallpaper parallax stops cleanly to save cycles.
4. Toggle on **Shell Blur** under the compositor settings, make sure all drawer panels are closed, and move your mouse cursor: verify that the screen remains at full **144Hz** and doesn't drop to 100Hz.

---

## 📶 System Bluetooth Management & Quick Toggles

### What Works
*   **Dual-Command Hardware Synchronization:** Powers Bluetooth hardware on/off cleanly by linking `rfkill` unblock with `bluetoothctl power on`, preventing the BlueZ `off-blocked` state lock.
*   **Universal Shell UI Integration:**
    *   *Quick Settings Drawer (`Toggles.qml`):* Toggles system Bluetooth state instantly and reflects live status.
    *   *Status Bar (`BluetoothStatus.qml`):* Displays `bluetooth` / `bluetooth_disabled` / `bluetooth_connected` dynamically.
    *   *Nexus Settings (`BluetoothPage.qml`):* Toggle switch accurately turns Bluetooth adapter on/off without snapping back.
    *   *Taskbar Popout (`modules/bar/popouts/Bluetooth.qml`):* Provides enabled/discovering toggles and device lists.
*   **IPC Control:** Supports querying state (`quickshell ipc -c niri-nilastia-shell call bluetooth isEnabled`) and toggling (`quickshell ipc -c niri-nilastia-shell call bluetooth toggle`).

### How to Test / Run
1. Toggle Bluetooth from the Quick Settings drawer or run:
   ```bash
   quickshell ipc -c niri-nilastia-shell call bluetooth toggle
   ```
2. Check the Bluetooth icon in the status bar and verify it updates between active and disabled.
3. Open the Nexus panel and navigate to **Connected devices**: verify the master Bluetooth toggle switch matches the power state and successfully switches the adapter.

---

## ☕ Keep Awake (Caffeine / Idle Inhibition)

### What Works
*   **Dual-Entry UI (Card & Quick Toggle):** Keep Awake can now be toggled directly from the Quick Toggles row (coffee icon) or via the expandable card in the Utilities drawer (`IdleInhibit.qml`).
*   **Disk Persistence via QSettings:** Stores active state in `~/.config/nilastia/` via `QtCore.Settings` (`category: "IdleInhibitor"`), ensuring Keep Awake stays enabled across reboots, logouts, and shell restarts.
*   **Complete Shell Idle Bypass:** When Keep Awake is enabled, `IdleMonitors.qml` explicitly shuts off all idle monitor timers (`root.enabled = false`), preventing screen lock (180s), display power-off (300s), and suspend/hibernate (600s).
*   **OS-Level Systemd Lock:** Automatically spawns a `systemd-inhibit` background process (`--what=idle:sleep:handle-lid-switch`) to prevent systemd-logind from putting the laptop to sleep or sleeping on lid close while Keep Awake is active.
*   **Instant Display Wake:** Immediately sends `niri msg action power-on-monitors` when turned ON to wake screens up if already asleep.
*   **IPC Control:** Supports querying state (`quickshell ipc -c niri-nilastia-shell call idleInhibitor isEnabled`), toggling (`quickshell ipc -c niri-nilastia-shell call idleInhibitor toggle`), and checking system locks via `systemd-inhibit --list`.

### How to Test / Run
1. Open the Quick Settings drawer and click the **coffee cup Quick Toggle** (or the Keep Awake card switch).
2. Run `systemd-inhibit --list` in a terminal and verify `Nilastia` is listed with `sleep:idle:handle-lid-switch` in `block` mode.
3. Restart the shell service (`systemctl --user restart niri-nilastia-shell`): verify that Keep Awake remains active (`quickshell ipc -c niri-nilastia-shell call idleInhibitor isEnabled` returns `true`).
4. Leave the desktop idle beyond 3 minutes: the screen will remain awake and unlocked.
5. Toggle **Keep Awake** off: verify `systemd-inhibit --list` unregisters the inhibitor immediately.

---

## 🛜 Native Wi-Fi Hotspot & Scan-to-Connect QR Code

### What Works
*   **NetworkManager AP Orchestration:** Enables full Wi-Fi Access Point mode (`Hotspot.qml`) with WPA2-PSK security and automatic DHCP subnet routing (`ipv4.method shared`).
*   **Multi-Interface UI Controls:**
    *   *Quick Settings Drawer:* Hotspot quick toggle in `Toggles.qml`.
    *   *Utilities Hotspot Card:* Dynamic `HotspotCard.qml` showing live status, connected devices count, SSID, password, band, and a scan-to-connect Wi-Fi QR Code (`WIFI:S:...;T:WPA;P:...;;`).
    *   *Taskbar Network Popout (`modules/bar/popouts/Network.qml`):* Hotspot enable/disable switch.
    *   *Nexus Network Settings (`NetworkPage.qml`):* Hotspot toggle row with live connection status.
*   **AP Scan Filtering & Clean Client Isolation:** Automatically filters out the local Hotspot AP SSID from `Nmcli.networks` and ignores AP-mode profiles during internet connectivity detection in [`Nmcli.qml`](file:///home/saravana/projects/calestia/nilastia/services/Nmcli.qml), preventing the desktop from mistaking its own AP for a client connection.
*   **Decoupled Status Bar Indicators:** The `hotspot` symbol (`wifi_tethering`) is decoupled from the `network` symbol (`signal_wifi_*_bar`), so when Hotspot is enabled, both icons display side-by-side on the status bar rather than replacing each other.
*   **Collision-Free Network Popout:** The Hotspot broadcasting card computes dynamic implicit height, ensuring clean spacing above the Wi-Fi scan list without overlapping text.
*   **Simultaneous Wi-Fi Client + Hotspot (Repeater Mode):** Uses `create_ap` (via `linux-wifi-hotspot`) with polkit privileges to automatically create a virtual adapter (`ap0`) matched to `wlan0`'s exact operating frequency. `wlan0` stays connected to the home Wi-Fi router with full internet speed and audio streaming, while `ap0` broadcasts the hotspot to external devices with NAT routing.
*   **Zero-Latency Optimistic UI Switching:** Toggling the hotspot immediately updates the switch state (`root.enabled`), eliminating visual lag and switch bouncing while the background daemon initializes or shuts down.
*   **Transition State Protection:** Prevents background status probes from resetting the switch state during start/stop operations.
*   **Dual-Interface Clean Teardown:** Completely halts both the primary interface (`wlan0`) and the virtual interface (`ap0`) on stop.
*   **IPC Controls:** Supports querying state (`quickshell ipc -c niri-nilastia-shell call hotspot isEnabled`), getting SSID (`quickshell ipc -c niri-nilastia-shell call hotspot getSsid`), and toggling (`quickshell ipc -c niri-nilastia-shell call hotspot toggle`).

### How to Test / Run
1. Connect to your regular home Wi-Fi network (`TP-Link_D9EB`).
2. Turn ON Hotspot from the Quick Settings drawer, the Network popout, or Nexus.
3. Verify that **your home Wi-Fi NEVER disconnects**:
   - Open a browser or ping `1.1.1.1` — your laptop internet is 100% active.
   - Status bar shows `wifi_tethering`.
   - Network popout shows the active Hotspot broadcast card.
4. On your phone, connect to `Nilastia Hotspot` — verify your phone connects and gets internet routed from your laptop's Wi-Fi.
5. Turn OFF Hotspot: verify it cleanly shuts down the virtual adapter while leaving home Wi-Fi completely uninterrupted.

---

## 📥 Taskbar System Tray

### What Works
*   **Default System Tray Display:** Activated `tray` in taskbar entries by default in [`barconfig.hpp`](file:///home/saravana/projects/calestia/nilastia/plugin/src/Nilastia/Config/barconfig.hpp) and [`Bar.qml`](file:///home/saravana/projects/calestia/nilastia/modules/bar/Bar.qml).
*   **Automatic Sizing:** Dynamically collapses and expands based on active `StatusNotifierItem` count (`Tray.qml`).
*   **Nexus Tray Settings:** Master `Enabled` switch and customization options (Background, Recolour icons, Compact mode, Popout on hover) in [`BarTray.qml`](file:///home/saravana/projects/calestia/nilastia/modules/nexus/pages/panels/taskbar/BarTray.qml).
*   **Interactive Item Activation & Menus:** Supports left-click activation, right-click secondary activation, and popout tray context submenus via `TrayMenu.qml`.

---

## 🎨 Dropdown Menus & Selectors

### What Works
*   **Window Root Item Resolution:** Replaced broken `.window` property lookups in [`Menu.qml`](file:///home/saravana/projects/calestia/nilastia/components/controls/Menu.qml) and [`PopupRow.qml`](file:///home/saravana/projects/calestia/nilastia/modules/nexus/common/PopupRow.qml) with robust parent chain traversal.
*   **Colour Palette & Theme Flavours:** The **Color Palette** dropdown (Nilastia, Catppuccin, Tokyo Night, Everforest, Gruvbox, Rose Pine, Dracula, One Dark, Nord, Solarized, Everblush, etc.) and flavour dropdowns (Catppuccin Latte/Frappe/Macchiato/Mocha, Rose Pine Dawn/Main/Moon, Everforest Soft/Medium/Hard, etc.) open smoothly, render on top of the view (`z: 99`), and allow selecting options with instant preview.
*   **Outside Click Dismissal:** Full window overlay `MouseArea` cleanly dismisses the dropdown menu whenever the user clicks outside.

### How to Test / Run
1. Open the Nexus panel and navigate to **Wallpaper & style** -> **Colours**.
2. Click on the **Color Palette** dropdown: verify the full dropdown list of themes opens above the page.
3. Select a theme with flavours (e.g., **Catppuccin** or **Everforest**): verify the Flavour dropdown appears and opens its options list when clicked.

---

## 🖼️ Parallax Wallpaper Builder & Live Editor

### What Works
*   **Create New Parallax:** Navigating to Nexus -> **Wallpaper & style** -> **Choose a wallpaper** -> **Parallax Flow** -> **Create New Parallax** opens Step 1 with a full layers management interface (Info card, Add Layer Image button via Zenity, Insert Clock Layer button, and layer ordering list).
*   **Layer Arrangement & Previewing:** Allows adding multiple PNG/JPG/WebP image slices or embedding the desktop clock. Automatically calculates progressive depth ranges (-0.5 background to +0.5 foreground) and transitions to Step 2 for interactive previewing with real-time mouse tracking.
*   **Preset & Manual Tuning:** Supports selecting presets (*Soft Drift*, *Balanced*, *Cinematic Depth*) or enabling *Manual Tuning Mode* to adjust glide duration (200–2000ms), max X/Y displacement, and per-layer shift/sensitivity.
*   **Build & Export Flow:** Compiles layers into a standalone `.nilawall` package in `~/Pictures/Wallpapers/`, applies it immediately to the active desktop, and displays the success dialog prompting to open the destination folder.
*   **Edit Active Parallax:** If the active wallpaper is a `.nilawall` or `wallpaper.json`, clicking **Edit Active Parallax** automatically extracts the layer images to `/tmp/`, unpacks all physics parameters, and opens the preview tuning step directly. If the active wallpaper is a static picture, the button is cleanly disabled with explanatory subtext.
*   **Desktop Parallax Sensitivity & Scaling:**
    *   *High-Response Cursor Curve:* Uses exponential curve tracking (`Math.sign(tx) * Math.pow(Math.abs(tx), 0.7)`) to dramatically expand center-screen motion sensitivity without having to move the cursor to monitor borders.
    *   *True Desktop Displacements:* Default presets offer 75px X / 45px Y (Balanced) and 130px X / 80px Y (Cinematic) scaled for 1080p+ resolutions, eliminating the visual math disparity with the preview box.
    *   *Multitasking Parallax Retention:* Parallax preserves 65% depth motion when application windows are open on the workspace, automatically muting to 0% only when an app goes truly fullscreen.

### How to Test / Run
1. Launch Nexus (`quickshell ipc -c niri-nilastia-shell call nexus open` or via application launcher).
2. Navigate to **Wallpaper & style** -> click the wallpaper preview or **Choose a wallpaper** -> click the **Parallax** card.
3. Click **Create New Parallax**: verify that Step 1 renders completely with all action buttons and does not open a blank page.
4. Click **Add Layer Image**, select one or more images, then click **Auto-Configure & Preview**: verify the interactive preview box tracks your cursor.
5. Click **Build & Apply**: verify the new wallpaper is compiled and applied to the desktop.
6. Return to desktop and move cursor in the center region: verify the wallpaper layers shift smoothly and noticeably.
7. Open application windows: verify parallax continues to respond with fluid depth motion.

---

## ⛅ Dashboard Weather Component & Weather Tab

### What Works
*   **Dashboard Small Weather Card:**
    *   Features a balanced two-line layout: Line 1 displays the primary temperature (e.g., `37°C`) in bold `headline.medium`, and Line 2 displays the location and condition (e.g., `Karur • Overcast`) in `body.small` with elision.
    *   Respects the 275px card boundary constraint, preventing text from overlapping neighboring cards (such as the User profile card).
    *   Enforces `clip: true` on the parent card container in `Dash.qml`.
    *   Clicking or mouse-scrolling on the card cycles through configured weather locations.
*   **Weather Tab Layout:**
    *   Header location controls enforce maximum widths with right-elision on city and subtitle text, preventing collisions with the Sunrise/Sunset stats on compact display setups.
    *   The 7-Day Forecast card tiles have explicit boundary clipping and internal column constraints to keep dates, icons, and min/max temperature labels within tile borders.

### How to Test / Run
1. Press `Super+G` or run `quickshell -c niri-nilastia-shell ipc call drawers toggle dashboard` to open the Dashboard drawer.
2. Verify the Weather card in the top-left displays `37°C` cleanly on line 1, and `Karur • Overcast` on line 2 with plenty of margin from the User card.
3. Scroll the mouse wheel on the Weather card to cycle locations (e.g. to `Tokyo`): verify the text stays contained within the card.
4. Switch to the **Weather** tab at the top: verify the city selector, sunrise/sunset, current weather banner, detail cards, and 7-Day forecast cards render without clipping or overflowing.

---

## 🦦 Unified Platypus Phone Integration & Audio Call Gateway

### What Works
*   **Unified Name & Plugin Identity:** Fully renamed to `platypus` (`org.nilastia.platypus`, `saravana.platypus`). IPC target `platypus` and legacy alias `platypuslink` both toggle the standalone window smoothly.
*   **Self-Contained Daemon Packaging:** Features an intelligent launcher script (`run_daemon.sh`) and bundles the compiled release binary (`bin/platypusd-core`). The shell automatically starts, supervises, and recovers `platypusd-core` without manual setup.
*   **Instant Glassmorphic Call Overlay & Desktop Alerts:**
    *   `CallPopup.qml` uses native Quickshell `PanelWindow` anchored cleanly to the top-right overlay layer (`WlrLayer.Overlay`, `WlrKeyboardFocus.None`).
    *   Incoming calls dispatch instant desktop notification banners via `notify-send -a Platypus -u critical -i phone "Incoming Call" "<Caller>"`.
    *   Interactive Answer, Decline, Mute, and Unmute buttons issue direct REST commands to `/api/v1/calls/action`.
*   **Contacts Synchronization & Dynamic Search:**
    *   Fixed `ContactsListSynced` JSON payload parsing in the daemon WebSocket handler.
    *   Added persistent in-memory caching in `AppState` and exposed `GET /api/v1/contacts` for instant zero-latency contact retrieval.
    *   Integrated real-time contacts search filtering (`StyledTextField`) and automatic contacts pre-fetching on completed in `StandaloneSettings.qml`.
*   **Hardware-Routed Bidirectional Call Audio:**
    *   Daemon automatically detects incoming/outgoing active calls and transitions connected Bluetooth cards to headset mode (HFP/HSP).
    *   Establishes low-latency (40ms) bidirectional PipeWire loopbacks: Phone Voice $\rightarrow$ `@DEFAULT_SINK@` (desktop speakers/headphones) and `@DEFAULT_SOURCE@` (desktop microphone) $\rightarrow$ Phone Input.
    *   Filters out audio monitor sources to prevent loopback feedback.
    *   Cleanly tears down loopbacks and restores the Bluetooth card profile to `off` on call termination.
*   **Daemon UI Lifecycle Controls, Polling & Log Capture:**
    *   **Periodic Polling:** Added 3-second recurring status poller in [`Platypus.qml`](file:///home/saravana/projects/nilastia-platypus-plugin/Platypus.qml), eliminating frozen offline states and dynamically updating `isOnline` and device link status.
    *   **Sidebar Quick Actions:** Added compact Restart (`restart_alt`), Copy Logs (`content_copy`), and Refresh (`refresh`) buttons directly to the sidebar status card in [`StandaloneSettings.qml`](file:///home/saravana/projects/nilastia-platypus-plugin/StandaloneSettings.qml).
    *   **Device & Service Management Card:** Integrated a dedicated diagnostics card on Page 5 with live status pill, Restart button, Copy Logs button, and an interactive monospace terminal displaying the last 30 log lines from the in-memory buffer.
    *   **System Clipboard Log Copying:** Copies daemon logs to system clipboard via both `Quickshell.clipboardText` and `wl-copy`, updating disk log file (`~/.local/state/nilastia/platypusd.log`) and displaying desktop confirmation toasts.

### How to Test / Run
1. Verify the daemon is running automatically under the shell:
   ```bash
   ps aux | grep -E "platypusd-core|client\.js"
   ```
2. Open the Platypus standalone client:
   ```bash
   qs -c niri-nilastia-shell ipc call platypus toggle
   ```
3. Test contacts retrieval endpoint:
   ```bash
   curl -s http://localhost:8080/api/v1/contacts
   ```
4. Test restarting the daemon via UI:
   - Click the **Restart** button in the sidebar or under **Device & Service Settings**.
   - Verify `platypusd-core` PID updates and desktop notification "Daemon restarted successfully" appears.
5. Test copying logs:
   - Click **Copy Logs** in the sidebar or Page 5.
   - Run `wl-paste` in a terminal to verify the captured daemon logs are in the clipboard.
6. Simulate an incoming call:
   ```bash
   platypus-cli simulate-call "+1234567890" "Alice Smith" "Ringing"
   ```
   - Verify top-right glassmorphic call card appears and system notification displays.
7. Accept the call:
   ```bash
   platypus-cli call accept mock-call
   ```
   - Check journal logs to verify PipeWire audio routing loopbacks are initialized.
8. Reject/hang up the call:
   ```bash
   platypus-cli call reject mock-call
   ```
    - Verify the call card dismisses and loopback modules are cleanly unloaded.

---

## 🚀 Dual-Session Hybrid GPU Selection (`niri-session` vs `niri-session-gpu`)

### What Works
*   **Dedicated GPU Session (`niri-session-gpu`):**
    *   Starts Niri using `~/.config/niri/config-gpu.kdl`, explicitly rendering on the dedicated NVIDIA GeForce RTX 4050 (`/dev/dri/by-path/pci-0000:01:00.0-render`).
    *   Automatically exports and imports NVIDIA Wayland variables into systemd (`GBM_BACKEND=nvidia-drm`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`, `LIBVA_DRIVER_NAME=nvidia`, `__NV_PRIME_RENDER_OFFLOAD=1`, `__VK_LAYER_NV_optimus=NVIDIA_only`, `VK_DRIVER_FILES`).
    *   Hardware-accelerates desktop compositor, blur shaders, and high refresh-rate external HDMI displays.
    *   Automatically unsets all GPU environment variables via bash trap upon session termination.
*   **Standard Power-Saving Session (`niri-session`):**
    *   Starts Niri using `~/.config/niri/config.kdl`, rendering strictly on the Intel UHD Graphics iGPU (`pci-0000:00:02.0-render`).
    *   Unsets any lingering GPU variables from systemd user manager, keeping the NVIDIA RTX 4050 in dynamic power management (~1W idle) for maximum battery life.
    *   Supports launching individual heavy apps on the dGPU using `prime-run <app>`.

### How to Test / Run
1. Log in from a virtual console (TTY):
   - Enter your username and password.
2. For battery saving (Intel UHD Graphics):
   ```bash
   niri-session
   ```
3. For high-performance GPU acceleration (NVIDIA RTX 4050):
   ```bash
   niri-session-gpu
   ```
4. Once inside the session, verify active GPU in terminal:
   ```bash
   niri msg outputs
   nvidia-smi
   ```

---

## 🖥️ Dynamic Display Mode & Universal Refresh Rate Switching

### What Works
*   **Live Zero-Lag Niri IPC Switching:** Executing `nilastia output <name> -m <mode>` or choosing a mode in Nexus -> **Display** immediately issues `niri msg output <name> mode <mode>` to the active compositor without requiring session restart or reloading delay.
*   **Active Config Resolution:** Automatically detects whether `config.kdl` or `config-gpu.kdl` is active by inspecting `os.environ["NIRI_CONFIG"]`, systemd user environment, and running niri process properties.
*   **Multi-Connector eDP Synchronization:** When updating an `eDP` output (e.g. `eDP-1`), `nilastia output` automatically updates sibling blocks (`eDP-2`) in the configuration file, guaranteeing that laptops with dynamic connector enumeration boot smoothly with the user's selected resolution and refresh rate.
*   **Unconstrained Display Settings UI:** Decoupled `DisplayPage.qml` refresh rate selection from `adaptiveRefreshRate` locks. Selecting a manual refresh rate automatically sets adaptive mode to `false`, preventing background battery services from reverting the user's choice.
*   **Extended Safeguard Countdown:** Increased the revert countdown timer from 5 to 15 seconds with smooth visual progress indicator.
*   **Fluid 144Hz GPU Compositor:** With minimum clocks locked to 600 MHz core and 5000 MHz memory in `niri-session-gpu`, PCIe link stays at Gen 3/4, delivering native 144 FPS with sub-millisecond scanout times on hybrid laptops.

### How to Test / Run
1. Switch refresh rate live to 60Hz:
   ```bash
   nilastia output eDP-1 -m 1920x1080@60.001
   ```
2. Verify output mode switches immediately:
   ```bash
   niri msg outputs | grep "Current mode"
   ```
3. Switch refresh rate live to 144Hz:
   ```bash
   nilastia output eDP-1 -m 1920x1080@144.002
   ```
4. Open the Nexus panel (`Super+N` or runner -> Nilastia Settings -> **Display**), choose a refresh rate from the dropdown, and verify the screen changes instantly and the 15-second safeguard bar appears.

---

## 🖼️ Parallax Wallpaper Editor & Live Layer Management

### What Works
*   **Full Layer Management in Tuning View (Step 2):** When opening "Edit Active Parallax", users can reorder layers with Move Up (▲) and Move Down (▼) buttons, delete unwanted layers, add new image slices via Zenity, and insert the desktop clock layer directly within the live preview tuning step.
*   **Zero-Reload Smooth Sliders:** Each layer's depth and sensitivity are managed by dynamic `QtObject` properties. Modifying or scrolling sliders updates values and interactive preview translations in-place without triggering full model resets or destroying/re-creating delegate controls.
*   **Mouse Wheel Incrementing:** Hovering over any layer slider and turning the mouse wheel adjusts depth or sensitivity in smooth 0.05 steps without disrupting page scrolling or losing focus.
*   **Safe Step Navigation:** Switching between Step 1 and Step 2 preserves custom/unpacked layer depths without forcing default linear redistribution.

### How to Test / Run
1. Launch Nexus settings (`Super+N` or runner -> Nilastia Settings).
2. Navigate to **Wallpaper & style** -> **Choose a wallpaper** -> **Parallax** -> **Edit Active Parallax**.
3. Verify that all layers appear in Step 2 with Move Up (▲), Move Down (▼), and Delete buttons.
4. Try dragging the Depth and Sensitivity sliders: verify the sliders slide smoothly without flickering, losing touch grab, or reloading.
5. Scroll the mouse wheel on the slider: verify the value increments/decrements cleanly by 0.05.
6. Click **Add Layer Image** or **Insert Clock Layer**: verify new layers are added and reflect immediately in the live preview.

---

## ⌨️ Desktop Shortcuts & Nexus Keybinding

### What Works
*   **Nexus Panel Hotkey (`Mod+N` / `Super+N`):** Pressing `Super+N` directly invokes `quickshell -c niri-nilastia-shell ipc call nexus open`, launching the Nilastia Nexus control center instantly.

### How to Test / Run
1. Press `Super+N` on the keyboard anywhere in the desktop session.
2. Confirm the Nexus settings window opens smoothly.

---

## 🕒 Desktop Clock Dragging & Interaction

### What Works
*   **Direct Desktop Dragging:** Click and drag anywhere on the desktop clock to move it freely across the display. The custom position is stored and loaded automatically.
*   **Hover Controls & Lock Toggle:** Hovering over the clock reveals a lock/unlock pill in the top-right corner. Clicking toggles lock/unlock, right-clicking the clock toggles lock/unlock, and double-clicking the lock button resets position back to the default anchors.
*   **Parallax Integration:** Virtual clock layers are rendered directly on the interactive `Bottom` layer with hardware parallax matrix translation.

### How to Test / Run
1. Hover the mouse over the desktop clock: confirm the lock/unlock pill and subtle outline appear.
2. Left-click and drag the clock across the screen: verify it moves fluidly and remains at the new position.
3. Click the lock pill or right-click the clock to lock it in place.
4. Double-click the lock pill: verify the clock snaps back to default anchor position.

---

## 🎬 Video Wallpaper Auto-Pause & Shell Optimizations

### What Works
*   **Automatic Window Occlusion Pause:** Whenever an application window is open on the focused workspace, `MediaPlayer` pauses video playback and `AnimatedImage` stops rendering, dropping wallpaper GPU/CPU load to zero. Playback immediately resumes when all windows are closed, minimized, or when viewing an empty workspace.
*   **High-Res Parallax Texture Bounding:** Images in `CachingImage.qml` are decoded asynchronously with mipmaps and capped to `Math.ceil(screen_dimension * 1.15)`, allowing high-resolution (4K/8K) images to run at 144Hz without UI hitches or VRAM exhaustion.
*   **Eliminated Polling PAM Overhead:** Hotspot status checks use `pgrep` instead of `pkexec`, removing constant root session spam every 5 seconds.

---

## 📡 Wi-Fi Hotspot Connected Devices & Modern Nexus UI

### What Works
*   **Zero-Root Connected Devices Discovery:**
    *   Dynamic background probe discovers connected client devices from `/tmp/create_ap.*/*.leases`, `/var/lib/*/dnsmasq*.leases`, `/proc/net/arp`, and `iw dev ap0 station dump`.
    *   Accurately extracts device hostname/friendly name (e.g. `POCO-X4-Pro-5G`), IP address, MAC address, real-time signal strength (e.g. `-30 dBm`), and categorizes the device icon (`smartphone`, `laptop`, `tablet`, `tv`, `devices`).
    *   Exposes `Hotspot.clients` array and `Hotspot.clientsCount` with real-time reactive QML bindings.
*   **Reworked Modern Material 3 Hotspot UI (`HotspotSettingsPage.qml`):**
    *   **Master Switch:** Dynamic subtitle cleanly displays connection state (`Broadcasting "Edith" (1 device connected)` vs `Broadcasting "Edith" (No devices connected)`), with transition state feedback (`Starting hotspot...` / `Stopping hotspot...`).
    *   **Hotspot Settings Group:** Grouped inputs for SSID, WPA2 toggle, passphrase field with password reveal toggle, and 2.4 GHz / 5 GHz band selector.
    *   **Smart Dirty Detection:** "Reset" and Filled "Apply Settings" buttons are dynamically enabled only when unsaved changes exist.
    *   **Scan to Connect QR Card:** Displays a crisp QR code canvas, credentials summary, and a dedicated "Copy Password" button that copies to system clipboard (`Quickshell.clipboardText`) with a visual toast notification.
    *   **Connected Devices List:** Beautiful device cards displaying a circular avatar pill, device hostname, IP, MAC address, real-time signal strength badge pill, and single-click station blocking.
    *   **Disk Persistence via `QtCore.Settings`:** SSID, password, frequency band, and blocked devices persist across shell reboots and system shutdowns.

### How to Test / Run
```bash
# 1. Open Nexus Hotspot Settings page
Super+N -> Network -> Configure hotspot & QR code

# 2. Verify connected devices via IPC
quickshell -c niri-nilastia-shell ipc call hotspot getClientsCount
quickshell -c niri-nilastia-shell ipc call hotspot getClients
```

---

## 🖼️ Parallax Windowed Motion & Layer-Sandwiched Clock Depth

### What Works
*   **Windowed Multitasking Parallax Retention:** Decoupled `hasOpenWindows` from `wallpaperCovered`. Parallax translations and idle camera drifting continue smoothly at 65% depth intensity during everyday desktop multitasking with open windows, freezing down to 0% only when an application window enters true fullscreen mode.
*   **True Layer-Sandwiched Desktop Clock:**
    *   Dynamic layer splitting ensures visual Z-order precisely matches the `.nilawall` layer list:
        - Image layers preceding the clock (`index < clockLayerIndex`) are rendered on `WlrLayer.Background` in `Wallpaper.qml`.
        - The interactive `DesktopClock` is rendered on `WlrLayer.Bottom` in `Background.qml` with its configured layer depth.
        - Foreground image layers succeeding the clock (`index > clockLayerIndex`) are rendered directly on `WlrLayer.Bottom` on top of `DesktopClock` in `foregroundLayersContainer`.
    *   The desktop clock visibly sits tucked behind foreground elements (e.g. anime character cutouts, foreground scenery) while remaining in front of background/midground scenery.
*   **Full Dragging & Interaction Transparency:** Foreground layers render with `enabled: false`, making them 100% transparent to pointer events. Users can click, drag, and toggle lock on `DesktopClock` even when portions of the clock are positioned directly behind foreground layer artwork.
*   **Seamless Parallax Cursor Tracking Across Widgets:** Moving the cursor over `DesktopClock` forwards mouse screen coordinates directly to the wallpaper parallax target, preventing coordinate resets or motion hitches when crossing desktop widgets.

### How to Test / Run
```bash
# 1. Apply multi-layer parallax wallpaper with embedded clock
nilastia wallpaper -f ~/Pictures/Wallpapers/nila-hisen.nilawall

# 2. Open any desktop window (e.g. terminal or browser)
# Move the cursor around: verify wallpaper parallax glides smoothly with cursor movement

# 3. Observe the desktop clock:
# Verify the clock is sandwiched behind the foreground character layer (Layer 3/4) and in front of the background layers (Layer 0/1)

# 4. Click and drag the clock:
# Verify you can click and drag the clock freely even while it sits behind the foreground character!
```

---

## Android Circle to Search & Google Lens Plugin

### What Works
*   **Triggering & Overlay Activation:** Pressing **`Super+S`** (`Mod+S` in Niri) triggers `quickshell -c niri-nilastia-shell ipc call circletosearch open`. Instantly captures screen snapshot via `grim`, displays fullscreen overlay on `WlrLayer.Overlay` with `WlrKeyboardFocus.Exclusive`.
*   **Android-Style Moving Gradient Tint & Iridescent Perimeter Glow:**
    *   Smooth SceneGraph-driven GLSL shader (`shaders/iridescent.qsb`) renders at native 144Hz with zero CPU overhead.
    *   A luminous radial gradient tint sweeps across the display on trigger alongside the iconic Google Lens quad-palette perimeter shimmer (`#4285F4`, `#EA4335`, `#FBBC05`, `#34A853`).
*   **Streamlined Lightweight Architecture:**
    *   Removed heavyweight background Tesseract OCR and translation engines per user request, eliminating CPU spikes and multi-second startup latency.
    *   Selection and circling interactions operate at full 144 FPS with immediate gesture feedback.
*   **Circle / Loop Gesture Search:**
    *   Drawing a closed loop or circle around any visual region (`isLoop`) immediately launches Google Lens visual search on that cropped region without extra confirmation.
*   **Browser-Agnostic Google Lens Integration (Zero 403 / Zero Loading Hangs):**
    *   Crops selection with `magick` with `-strip` to optimize file size.
    *   Uploads selection to unblocked temporary hosting (`uguu.se` primary in <0.7s, `freeimage.host` fallback in <0.8s) and constructs universal GET ingestion link `https://lens.google.com/upload?url={IMAGE_URL}`.
    *   Launches the browser with user session cookies preserved, completely eliminating HTTP 403 Forbidden errors and Cloudflare-induced infinite loading skeleton spinners.
    *   Automatically stages cropped selections to system clipboard (`wl-copy --type image/png`).
*   **Settings UI Browser Dropdown with Dynamic System Probing:**
    *   `SettingsUi.qml` scans the system for installed browsers (`brave`, `google-chrome-stable`, `google-chrome`, `chromium`, `firefox`, `zen-browser`, `zen`, `librewolf`, `vivaldi`, `microsoft-edge-stable`) and populates a dynamic Nilastia `SelectRow` dropdown.
    *   Chromium browsers launch in frameless docked side-drawer mode (`--app=... --window-size=640,980`).
    *   Firefox/Gecko browsers launch in `--new-window`.
*   **Quick Dismissal:** Pressing `Escape` or clicking Close instantly dismisses overlay and restores desktop focus.

### How to Test / Run
```bash
# 1. Trigger via keyboard shortcut:
# Press Super+S

# 2. Or trigger via IPC:
quickshell -c niri-nilastia-shell ipc call circletosearch open

# 3. Direct Circle to Lens test:
# - Draw a closed circle or loop around any image or area on screen
# - The overlay immediately closes and your configured browser (Brave, Chrome, or Firefox) opens with Google Lens search results!
# - Verify the page loads instantly with visual matches and no 403 error or infinite loading spinner.

# 4. Browser Selection test:
# - Open Nexus -> Plugins -> Circle to Search -> Settings
# - Verify the "Browser Application" option displays a dropdown showing your installed browsers (e.g. Brave Browser, Google Chrome, Mozilla Firefox).
```

---

## CachyOS GRUB Bootloader & Dual Boot

### What Works
* **UEFI NVRAM Registration:** `cachyos` is registered as `Boot0004` pointing directly to `\EFI\cachyos\grubx64.efi`.
* **Top Priority Boot Order:** `BootOrder` is set to `0004,0003,0000,2001,2002,2003`, placing CachyOS GRUB as the default first entry when the machine powers on or when viewing the BIOS boot priority screen.
* **Dual-Boot OS Detection:** `/boot/grub/grub.cfg` includes:
  - CachyOS LTS Kernel (`/boot/vmlinuz-linux-cachyos-lts`)
  - Linux LTS Kernel (`/boot/vmlinuz-linux-lts`)
  - Linux Stock Kernel (`/boot/vmlinuz-linux`)
  - Windows Boot Manager on `/dev/nvme0n1p1` (`\EFI\Microsoft\Boot\bootmgfw.efi`)
  - UEFI Firmware Settings entry
* **Graphical Theme:** Configured with official CachyOS theme (`/usr/share/grub/themes/cachyos/theme.txt`).

### How to Test / Run
```bash
# Verify the UEFI boot priority shows 0004 (cachyos) first:
efibootmgr -v
```

---

## Circle to Search Universal Browser Resolution & Responsive Side-Drawer

### What Works
* **Intelligent Auto-Detection:** `resolve_browser()` in `backend/lens.py` automatically detects installed Chromium-based browsers (`brave`, `google-chrome-stable`, `google-chrome`, `chromium`, `chromium-browser`, `vivaldi`, `microsoft-edge`, `opera`) and launches in standalone frameless app mode (`--app=`, `--window-size=640,980`).
* **Gecko/Firefox Fallback:** If no Chromium browser is present, detects Firefox variants (`zen-browser`, `zen`, `firefox`, `librewolf`, `waterfox`, `floorp`) and launches with `--new-window`.
* **Desktop Generic Fallback:** Falls back to `xdg-open` if no specific browser binary is found.
* **Graceful Zero-Browser Handling:** If no web browser is installed, stages the selection crop to system clipboard via `wl-copy` and triggers a desktop notification via `notify-send` alerting the user that the selection was copied and no browser was found.
* **Configurable Settings:** `Settings.qml` defaults `lensBrowser: "auto"`. Users can override this to any custom browser binary in the Nilastia Nexus plugin settings.
* **Responsive 640px Layout:** Form launcher embeds `<meta name="viewport" content="width=device-width, initial-scale=1">` to force Google Lens visual search results to reflow into a clean 2-column mobile/tablet responsive layout without horizontal scrollbars.
* **Universal Niri Floating Rules:** In `30-window-rules.kdl`, regex `match app-id=r#"^(brave|chrome|chromium|google-chrome|vivaldi|microsoft-edge|opera)-.*(google\.com|cts-lens).*"#` ensures all Chromium variants open as floating, borderless side-drawers at 640x980 docked at top-right (`x=24 y=54`).

### How to Test / Run
```bash
# 1. Test auto-detection logic via CLI
python3 -c "
import sys; sys.path.insert(0, '/home/saravana/projects/nilastia-circle-to-search/backend')
import lens
print(lens.resolve_browser('auto'))
"

# 2. Test Lens upload pipeline with auto-detected browser
python3 /home/saravana/projects/nilastia-circle-to-search/backend/lens.py --image /tmp/cts-screen.png --crop "100,100,300,300" --no-launch
```

---

## Shell Blur Optimizations & Component Sub-Regions

### What Works
* **Simplified Shell Blur Settings:**
  - In Nexus -> Compositor, shell blur is controlled via a clean master toggle without redundant noise and saturation sliders.
  - Automatically enforces default `0.0` noise and `1.0` saturation.
* **Nexus X-Ray Blur Mode Toggle:**
  - Added dedicated "X-ray blur mode" toggle under "Window Background Blur" in Nexus -> Compositor.
  - Controls whether Niri samples live window content (`xray false`, default) or directly samples cached wallpaper blur (`xray true`, maximum performance) across both `30-window-rules.kdl` and `80-layer-rules.kdl`.
* **Zero IPC Flooding Blur Region:**
  - Changed `blurRegionRef` for the dashboard from dynamic animated height/y to a stationary target bounding box.
  - Quickshell issues `set_blur_region` once on open and once on close, eliminating 50+ Wayland IPC calls and damage invalidations per second during the slide.
* **Fluid Dashboard Tab Switching & Direct Scene Graph Rendering:**
  - Tab transitions (Dashboard, Media, Performance, Weather) use direct GPU scene graph node translation and opacity fades, completely avoiding FBO texture allocation stalls.
  - Removed container height and width morphing behaviors, achieving fluid 300ms/260ms OutCubic tab glides and smooth 280ms drawer slide-ins at native 144 FPS.
* **Taskbar & OSD Blur:**
  - Background blur now renders correctly behind the taskbar (`bar.implicitWidth`) while on the desktop.
  - Brightness/Volume OSD (`osdBg`) and Notifications (`notifsBg`) register dynamic blur regions when active.
  - Entire screen remains completely crisp; blur is strictly constrained to the component rectangles.

### How to Test / Run
```bash
# 1. Verify screen remains crisp on desktop with no full-screen blur:
grim /tmp/screen-verify.png && file /tmp/screen-verify.png

# 2. Test Dashboard tab switching smoothness:
quickshell -c niri-nilastia-shell ipc call drawers toggle dashboard
# Click between Dashboard, Media, Performance, and Weather tabs

# 3. Test volume/brightness OSD blur:
# Press brightness or volume keys and observe the OSD slider background blur

# 4. Test X-ray blur toggle:
# Open Nexus (Mod+N), navigate to Compositor -> Blur & Transparency, toggle "X-ray blur mode"

# 5. Test Circle to Search plugin:
# Press Super+S or run:
quickshell -c niri-nilastia-shell ipc call circletosearch open
```

---

## Multi-GPU Screen Recording with NVIDIA NVENC Offload

### What Works
* **Automatic NVIDIA dGPU Offload:**
  - `nilastia record` automatically probes `/dev/nvidia0` and offloads `gpu-screen-recorder` to the dedicated NVIDIA GeForce RTX 4050 using standard PRIME environment variables (`__NV_PRIME_RENDER_OFFLOAD=1`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`, `__VK_LAYER_NV_optimus=NVIDIA_only`).
  - Seamlessly captures from the Intel iGPU Wayland compositor via KMS DMA-BUF buffer sharing and encodes in hardware with NVENC (`h264_nvenc`).
  - Achieves zero-lag, continuous 144 FPS screen recording at 1080p.
* **Hardware Codec Support:**
  - Supports `--codec [h264|hevc|av1]` leveraging RTX 4050 dual NVENC architecture (including hardware AV1 encoding).
  - Supports `--quality [medium|high|very_high|ultra]`.
* **Automatic Graceful Fallback:**
  - When `--gpu auto` (default) is active, if the NVIDIA encoder fails to start, `nilastia record` automatically falls back to Intel VA-API without failing the user recording request.
  - Allows manual override via `--gpu intel` or `--gpu nvidia`.
* **Shell Quick Settings & Utilities Integration:**
  - Toggling recording from the Utilities drawer (`Record.qml` / `Recorder.qml`) automatically leverages NVIDIA NVENC hardware acceleration with desktop notification badges displaying the active encoder (`Recording (NVIDIA NVENC)...`).
  - Child processes started via Quickshell's `Quickshell.execDetached` run with sanitized Mesa/Intel driver variables (`CUDA_VISIBLE_DEVICES`, `NVIDIA_VISIBLE_DEVICES`, `__EGL_VENDOR_LIBRARY_FILENAMES`, `VK_DRIVER_FILES`, `LIBVA_DRIVER_NAME`, `VDPAU_DRIVER`), ensuring parity between CLI and GUI recording.

### How to Test / Run
```bash
# 1. Start full-screen recording with auto NVIDIA NVENC:
nilastia record

# Stop recording (run again):
nilastia record

# 2. Record with audio:
nilastia record -s

# 3. Record selected region:
nilastia record -r

# 4. Force Intel VA-API recording:
nilastia record --gpu intel

# 5. Record using hardware AV1 encoding:
nilastia record -k av1

# 6. Test recording from Quick Settings / Utilities drawer:
# Open Utilities drawer, select "Record fullscreen", verify notification shows "(NVIDIA NVENC)"
```

---

## Dashboard Media Tab Lyrics State Synchronization

### What Works
* **Responsive State Transitions:**
  - Transition between `loading`, `hasLyrics`, and `noLyrics` is driven by unified opacity animations (`Anim.DefaultEffects`).
  - Loading spinner reliably fades out when lyrics are fetched without getting stuck.
* **Click-Through Prevention:**
  - The lyrics list item view explicitly enforces `enabled: opacity > 0.05` and `visible: opacity > 0`, preventing touch/click events from passing through to underlying list delegates while the loading indicator is visible.
* **Reactive Property Signals:**
  - Corrected `Q_PROPERTY(bool hasLyrics ... NOTIFY hasLyricsChanged)` in the C++ plugin, ensuring that when lyrics are received over network or cache, the QML shell reacts immediately to update view states.

### How to Test / Run
```bash
# 1. Play music in a supported MPRIS media player (Brave, Spotify, mpv).
# 2. Open the Dashboard drawer:
quickshell -c niri-nilastia-shell ipc call drawers toggle dashboard
# 3. Click the Media tab:
# Observe the loading indicator transition cleanly to the scrollable lyrics view.
```

---

## Shell Layer Blur Persistence & Battery Monitor Decoupling

### What Works
* **User Blur Preference Preservation:**
  - Toggling "Enable blur on system layers" in Nexus -> Blur & Transparency saves the preference persistently into `~/.config/nilastia/shell.json` under `GlobalConfig.general.battery.preferredLayerBlur`.
  - Turning off shell blur stays off across reboots, shell restarts, charger connection changes, and adaptive blur toggles.
* **Non-Destructive Adaptive Blur:**
  - When "Adaptive compositor blur" is enabled, blur is temporarily disabled on battery power and restored strictly to the user's preferred state on AC power.
  - If the user prefers blur to be disabled, the battery monitor never forces it on.
  - Avoids redundant writes to `80-layer-rules.kdl` when the active state already matches user preferences.

### How to Test / Run
```bash
# 1. Check current layer blur rule in Niri:
cat ~/.config/niri/config.d/80-layer-rules.kdl

# 2. Toggle shell blur in Nexus:
# Open Nexus (Mod+N), navigate to Compositor -> Blur & Transparency, toggle "Enable blur on system layers".
# Verify that ~/.config/niri/config.d/80-layer-rules.kdl updates immediately.

# 3. Verify persistence across shell restart:
systemctl --user restart niri-nilastia-shell.service
# Verify in journalctl that [AdaptiveBlur] does not force blur on:
journalctl --user -u niri-nilastia-shell.service -g "AdaptiveBlur" --no-pager | tail -n 5
```

---

## Dual-Backend Screen Recording Architecture (NVIDIA NVENC & Intel VA-API)

### What Works
* **Artifact-Free NVIDIA NVENC Hardware Recording on Hybrid Graphics:**
  - On hybrid laptops where the display is physically wired to the Intel iGPU (`eDP-1`), `nilastia record` automatically selects `wf-recorder` (`wlr-screencopy-unstable-v1`) when recording with NVIDIA dGPU.
  - Completely eliminates pink/green zig-zag horizontal corruption lines caused by Intel DRM KMS DMA-BUF tiling modifier mismatches in `gpu-screen-recorder`.
  - Uses hardware NVENC encoding (`h264_nvenc`, `hevc_nvenc`, `av1_nvenc`) on the NVIDIA RTX 4050 GPU at native 144 FPS.
  - Generates crystal-clear 1080p MP4 output verified with extracted video frames and `nvidia-smi` active GPU memory usage.
* **Dual-Backend CLI & Configuration:**
  - Added `-b, --backend [auto|wf-recorder|gpu-screen-recorder]` to `nilastia record`.
  - `auto` mode smartly selects `wf-recorder` for NVIDIA dGPU and `gpu-screen-recorder` / `wf-recorder` for Intel iGPU.
* **Unified Quickshell Desktop Integration:**
  - `services/Recorder.qml` uses `SplitParser` and state query (`running`, `paused`, `stopped`) to seamlessly track active recording state, elapsed time, pause/resume, and stop actions from the Quick Settings / Utilities drawer card (`Record.qml`).
  - Preloaded `Recorder;` in `modules/ServiceLoader.qml` ensuring the singleton is alive from shell startup.
  - Implemented startup and stop grace timers (`startupGraceTimer` and `stopGraceTimer`) preventing UI controls from flickering or vanishing during process spawn/teardown.
  - Added explicit `--start` and `--stop` flags to `nilastia record` preventing accidental start/stop toggle loops.
  - Sanitizes Mesa/Intel-locking systemd environment variables (`CUDA_VISIBLE_DEVICES`, etc.) when launched from Quickshell.

### How to Test / Run
```bash
# 1. Start a recording via CLI or drawer card:
nilastia record --start

# 2. Check that the recording process is active on NVIDIA dGPU:
nvidia-smi

# 3. Stop the recording cleanly:
nilastia record --stop

# 4. Verify that the output video in ~/Videos/Recordings/ is clean and uncorrupted:
ls -lht ~/Videos/Recordings/ | head -n 3
ffprobe -v error -show_entries stream=codec_name,width,height,r_frame_rate ~/Videos/Recordings/recording_*.mp4
```

---

## Lock Screen Keybindings & CLI

### What Works
* **Universal Lockscreen Keybindings:**
  - Standard keybindings configured in `niri/config.d/70-binds.kdl` and `~/.config/niri/config.d/70-binds.kdl`:
    - `Ctrl+Alt+L`: Standard Linux/GNOME lockscreen keybind.
    - `Mod+Alt+L`: Nilastia default keybind.
    - `XF86ScreenSaver`: Hardware keyboard screen lock / sleep hotkeys.
  - All bindings include `allow-when-locked=true` ensuring immediate activation without conflicts.
* **CLI Subcommand (`nilastia lock`):**
  - Instant screen lock triggered from terminal, scripts, or application launchers via `nilastia lock`.
  - Communicates directly via Quickshell IPC: `quickshell -c niri-nilastia-shell ipc call lock lock`.

### How to Test / Run
```bash
# 1. Lock screen via CLI:
nilastia lock

# 2. Lock screen via hotkeys:
# Press Ctrl+Alt+L or Mod+Alt+L

# 3. Verify Niri keybindings:
niri validate
```

---

## Keep Awake (Caffeine / Idle Inhibition) Fix & Surface Mapping

### What Works
* **Complete Idle Prevention:**
  - When Keep Awake is enabled (via Quick Settings / Utilities card or `quickshell -c niri-nilastia-shell ipc call idleInhibitor enable`), the system completely inhibits:
    - Automatic screen lock (`lock`) after 180 seconds.
    - Display DPMS monitor power off (`dpms off`) after 300 seconds.
    - System sleep and suspend (`sleep`) after 600 seconds.
* **Dual Layer Inhibition Architecture:**
  - **Wayland Protocol Level:** Maps an invisible 1x1 `PanelWindow` to `eDP-1` via `Quickshell.screens[0]`, successfully activating `zwp_idle_inhibit_manager_v1` in Niri. Verified via `niri msg -j layers`.
  - **Systemd Sleep / Lid Inhibit:** Runs `systemd-inhibit --what=idle:sleep:handle-lid-switch` ensuring logind does not suspend the laptop.
* **Persistent State Across Restarts:**
  - Uses `PersistentProperties` with `reloadableId: "idleInhibitor"` backed by state file `~/.local/state/nilastia/keepawake`.
  - State survives Quickshell reloads, reboots, and session restarts without resetting or crashing.
* **Clean Process Lifecycle:**
  - Cleanly terminates any previous or orphaned `systemd-inhibit` instances on toggle and component destruction, preventing process leaks.

### How to Test / Run
```bash
# 1. Enable Keep Awake via IPC or UI:
quickshell -c niri-nilastia-shell ipc call idleInhibitor enable

# 2. Verify systemd inhibitor process:
pgrep -fl "systemd-inhibit.*Keep Awake"

# 3. Verify Wayland layer shell surface in Niri:
niri msg -j layers | grep -i "nilastia"

# 4. Verify state persistence file:
ls -l ~/.local/state/nilastia/keepawake

# 5. Disable Keep Awake:
quickshell -c niri-nilastia-shell ipc call idleInhibitor disable
```

---

## Screen Recording Quality Restoration & Bitrate Calibration

### What Works
* **Zero Quality Loss Recording:**
  - Recording initiated from either the desktop shell UI (Quick Settings / Utilities drawer) or CLI defaults to `very_high` quality preset.
  - Video output is crystal clear at 1080p 144 FPS with sharp subpixel text, no blur, and zero compression artifacts.
* **Standard BT.709 High Definition Colorimetry:**
  - Forces BT.709 color primaries, transfer characteristics, and matrix across both recording backends (`gpu-screen-recorder` and `wf-recorder`), eliminating washed-out colors and dull gray contrast.
* **Optimal Hybrid Laptop Architecture:**
  - In `auto` mode on hybrid laptops, uses `gpu-screen-recorder` on Intel display KMS (`eDP-1`), achieving 144 FPS direct scanout zero-copy capture with zero dGPU power consumption.
  - When `--gpu nvidia` is explicitly requested, uses `wf-recorder` with hardware NVENC under calibrated 35-50 Mbps VBR bitrates (`preset=p5`, `tune=hq`, `rc=vbr`, `cq=18`).

### How to Test / Run
```bash
# 1. Start a high-quality recording (default very_high preset):
nilastia record --start

# 2. Check running process and parameters:
ps aux | grep -E "(gpu-screen-recorder|wf-recorder)" | grep -v grep

# 3. Stop the recording:
nilastia record --stop

# 4. Verify that the recorded video is sharp with BT.709 color space:
ffprobe -v error -show_entries stream=codec_name,width,height,r_frame_rate,color_space,color_range,bit_rate ~/Videos/Recordings/recording_*.mp4 | tail -n 15
```

---

## Runtime Bug Fixes, Log Cleanliness, and Systemd Lifecycle Optimization

### What Works
* **Zero Orphan Processes via Systemd KillMode:**
  - Configured `KillMode=mixed` in `extras/niri-nilastia-shell.service` and user systemd service.
  - Ensures helper background processes (`nmcli monitor`, `systemd-inhibit`, `sleep`) are cleanly killed when the shell restarts.
* **Robust QSettings Migration to PersistentProperties:**
  - Migrated `services/Hotspot.qml` (`reloadableId: "hotspot"`) and `services/Time.qml` (`reloadableId: "desktopClock"`) from deprecated `QtCore.Settings` and `Qt.labs.settings` to native `PersistentProperties`.
  - Completely eliminated `QSettings: Status code is: 1` initialization errors.
* **Notification Dismissal Null-Safety:**
  - `modules/notifications/Notification.qml` safely handles model teardown via optional chaining (`modelData?.actions`, `modelData?.urgency`, `modelData?.body`, `modelData?.summary`).
  - Dismissing notifications no longer produces `TypeError: Cannot read property 'actions' of null`.
* **Lock Screen Resource Monitor Binding:**
  - Added `readonly property bool locked: lock?.locked ?? false` on `LockSurface.qml` and safe chaining in `Resources.qml`.
  - Eliminates `Unable to assign [undefined] to bool` during lockscreen initialization.
* **Log Silence & Performance:**
  - Removed debug console logging during drawer transitions and overview toggling in `ContentWindow.qml`, `Hypr.qml`, and `Background.qml`.
  - Resolved `xkbcommon: [XKB-679]` compose table warning by enforcing `export LC_CTYPE="en_IN.UTF-8"` in `run_shell.sh`.

### How to Test / Run
```bash
# 1. Verify journal logs have zero QSettings or xkb errors on startup:
journalctl --user -u niri-nilastia-shell.service -b --no-pager -n 30

# 2. Verify only 1 nmcli monitor instance is running:
ps aux | grep "nmcli monitor" | grep -v grep

# 3. Test sending and dismissing a notification:
notify-send -u normal "Nilastia Test" "Testing null safety"

# 4. Check journal logs to ensure zero warnings or errors were generated:
journalctl --user -u niri-nilastia-shell.service -b --no-pager -n 15
```

---

## Circle to Search Plugin Streamlining, Iridescent Gradient Tint, and Browser Dropdown

### What Works
* **Sub-200ms Instant Visual Search Overlay:**
  - Removed CPU-intensive Tesseract OCR daemon and batch translation engine.
  - Grim captures display and overlay presents immediately with zero incubation or processing lag.
* **Direct Google Lens HTTP Upload & Browser Launching:**
  - Implemented direct multipart POST upload to `https://lens.google.com/upload?ep=subb&hl=en` in [`backend/lens.py`](file:///home/saravana/projects/nilastia-circle-to-search/backend/lens.py).
  - Retrieves canonical search results URL (`https://www.google.com/search?vsrid=...`) in ~1.1s and launches a floating browser window (`--app=https://...`, 640x980) or `--new-window` on Firefox via `start_new_session=True`.
  - Bypasses modern browser cross-origin `file://` form submission restrictions.
* **Silky 144Hz SceneGraph Iridescent Shader:**
  - Replaced JavaScript 16ms timer with SceneGraph `NumberAnimation` on `shaderTime` in [`Overlay.qml`](file:///home/saravana/projects/nilastia-circle-to-search/Overlay.qml), eliminating CPU/main-thread wakeups and rendering smoothly at native 144Hz.
  - Re-implemented [`shaders/iridescent.frag`](file:///home/saravana/projects/nilastia-circle-to-search/shaders/iridescent.frag) with branchless periodic bell curves for the Google Lens chromatic palette, dual-center orbiting ambient liquid silk drift, traveling perimeter gleams, and photometrically correct premultiplied alpha compositing.
  - Recompiled with `/usr/lib/qt6/bin/qsb --qt6 -O` to `shaders/iridescent.qsb`.
* **Native Browser Selection Dropdown in Nexus:**
  - [`SettingsUi.qml`](file:///home/saravana/projects/nilastia-circle-to-search/SettingsUi.qml) uses native `SelectRow` and `MenuItem` controls in Nexus Settings.
  - Automatically probes system `PATH` for installed browsers (`brave`, `google-chrome-stable`, `firefox`, `chromium`, `zen-browser`, `librewolf`, `xdg-open`).
  - Seamlessly updates `settings.lensBrowser`.
* **Cropped Image Actions:**
  - Directly opens Google Lens on closed circle gestures.
  - Region selection provides instant "Search Image" via Lens and "Copy Image" to clipboard via `wl-copy`.

### How to Test / Run
```bash
# 1. Open Circle to Search overlay via IPC (or Super+S):
quickshell -c niri-nilastia-shell ipc call circletosearch open

# 2. Test direct upload and browser launch from terminal:
python3 /home/saravana/projects/nilastia-circle-to-search/backend/lens.py --image /tmp/cts-screen.png --crop 100,100,500,400 --browser auto

# 3. Close overlay via IPC:
quickshell -c niri-nilastia-shell ipc call circletosearch close

# 4. Open Nexus settings to view plugin browser dropdown:
quickshell -c niri-nilastia-shell ipc call nexus open
```

---

## BlueWire: Native Bluetooth Hands-Free Call Routing Plugin (`saravana/bluewire`)

### What Works
* **Zero-APK Bluetooth HFP Call Integration:**
  - Routes calls natively over Bluetooth HFP v1.8 Hands-Free profile (`org.pipewire.Telephony` and `org.bluez`).
  - No mobile companion application or local Wi-Fi pairing required; works purely with standard Bluetooth device pairing.
* **Compiled Rust Telephony Daemon:**
  - Fast standalone daemon binary at `bin/nilastia-bluewire-daemon` built with Tokio 1.37 and `zbus 5.19`.
  - Dispatches D-Bus method calls and property changes with <1ms latency and consumes only ~6MB RAM.
  - Exposes local UNIX domain socket listener at `$XDG_RUNTIME_DIR/nilastia-bluewire.sock` for zero-overhead client IPC, as well as stdin stream processing.
* **Automatic PipeWire Duplex Audio Loopback:**
  - Spawns `pw-loopback` instances (`-C <source> -P @DEFAULT_SINK@` and `-C @DEFAULT_SOURCE@ -P <sink>`, 30ms latency) upon call answer.
  - Routes mobile voice audio to laptop speakers/headphones and laptop mic to the caller.
  - Automatically terminates loopback processes upon hangup or disconnect.
* **Material 3 Floating Call HUD Overlay:**
  - Displays high-contrast caller card on Wayland `WlrLayer.Overlay`.
  - Pulsing border animation for incoming ringing state.
  - In-call duration timer updating every second during active calls.
  - Action buttons for Answer, Decline, Mic Mute/Unmute, and End Call.
* **Nexus Settings UI:**
  - Dynamically detects paired phones via `Quickshell.Bluetooth` reactive properties.
  - Real-time Connect/Disconnect toggle for paired mobile devices.
  - Persistent toggles for `autoConnectPhone`, `autoLoopback`, and `enableHud`.
  - Test Call Simulator button triggering the HUD overlay directly from Nexus.
* **Global Quickshell IPC Integration:**
  - Shell `IpcHandler` exposes target `bluewire` (with alias `calls`) with methods `getStatus`, `answer`, `hangup`, `toggleMute`, `dial`, `mock_incoming`, `mock_answer`, `mock_hangup`, `openWindow`, `closeWindow`, `toggleWindow`, `setTab`, `clearHistory`, and `getHistory`.
* **Standalone BlueWire Phone Application Window (`AppWindow.qml`):**
  - Dedicated floating application window with Material 3 styling (`implicitWidth: 420`, `implicitHeight: 640`).
  - Top header displaying connected mobile device name, address, and live battery percentage.
  - Active call sliding banner with real-time call duration timer, caller info, and quick mute/hangup buttons.
  - **Keypad Tab:** 3x4 dialer grid with letters/symbols, backspace, paste from clipboard, physical keyboard typing intercept, DTMF tone dispatch, Call/Redial button, and immediate "Calling..." transition with red End Call button.
  - **Contacts Tab:** Native Bluetooth PBAP contacts list with initials avatar badges, real-time live search filter, single-tap call buttons, contact count display, and PBAP sync refresh action button.
  - **Recents Tab:** 50-entry call history list with colored badges (incoming green, outgoing primary, missed red), relative timestamps ("2m ago", "1h ago"), call duration formatting, one-tap callback redial button, and number copy button.
  - **Audio & Device Tab:** Connected Bluetooth phone info, PipeWire input and output audio sliders (`StyledSlider` for Mic Gain and Speaker Volume), plugin preferences, and test simulator controls.
* **Native Bluetooth PBAP Contacts Synchronization:**
  - Extracts contacts over Bluetooth PBAP directly from paired phones without requiring an Android companion app.
  - Runs user-space `obexd` service (`~/.config/systemd/user/dbus-org.bluez.obex.service`) with `org.bluez.obex.PhonebookAccess1`.
  - Python sync backend at [`backend/sync_contacts.py`](file:///home/saravana/projects/nilastia-bluetooth-calls/backend/sync_contacts.py) parses vCard fields and writes cache to `~/.local/state/nilastia/contacts.json`.
  - Automatic caller name resolution across active calls, history, and dialer.
* **Duplex Audio Loopback & Bluetooth SCO Transport Activation:**
  - Automatically switches PipeWire card profile to `audio-gateway` via `pactl set-card-profile bluez_card.<MAC> audio-gateway`.
  - Activates `org.pipewire.Telephony.AudioGatewayTransport1` on `/org/pipewire/Telephony/ag1` to send `AT+BCC` and open SCO socket.
  - Implements dynamic node polling before establishing bidirectional `pw-loopback` routes.
* **Persistent Call History Storage:**
  - Call history automatically stored via Quickshell's `PersistentProperties` (`reloadableId: "bluewire-history"`).
  - Preserves call history across shell reloads and sessions.
* **Desktop Application Launcher & Niri Window Rule:**
  - Installed desktop file at `~/.local/share/applications/nilastia-bluewire.desktop` allows launching or toggling the dialer from application runners (Rofi, Walker, Fuzzel, Nexus).
  - Configured Niri window rule in `30-window-rules.kdl` to automatically open the window floating at 420x640 with minimum bounds 380x520.
* **Full PBAP Phonebook Extraction (All 718 Contacts Synced):**
  - Resolved missing contacts bug by passing `{"MaxListCount": dbus.UInt16(65535), "Format": "vcard30"}` and polling `org.bluez.obex.Transfer1.Status` until `"complete"`.
  - Implemented RFC 2426 vCard line unfolding for multi-line entries.
  - Successfully extracted all 718 contacts from connected phone into `~/.local/state/nilastia/contacts.json`.
* **Incoming Call HUD & Desktop Notification Alerts:**
  - Added D-Bus `AddMatch` rules in the daemon for WirePlumber telephony signals (`InterfacesAdded`, `CallAdded`, `PropertiesChanged`).
  - Expanded incoming call detection across `"incoming"`, `"waiting"`, and `"ringing"` states.
  - Automatically issues desktop notification via `notify-send` with caller info and action buttons on incoming calls.
  - Call HUD overlay provides Answer, Decline, Mute, and Open in App controls.
* **Floating Call HUD Idle Bubble Collapse:**
  - Added `isBubble` collapse mode in `CallPopup.qml`.
  - In bubble mode, morphs into a compact 138x52 pill showing phone icon, call duration timer, and expand button.
  - 6-second auto-collapse idle timer activates during active calls when not hovered.
  - Clicking bubble expands back to full HUD card; double-clicking opens full desktop application window.
  - Full-window hover detection handled by `HoverHandler`, preserving raw click events for action buttons.
* **Dedicated In-Call View (Tab 4) in Standalone App Window:**
  - Dynamic Tab 4 ("In Call") automatically appears and switches into view when a call starts, returning to Tab 0 on call completion.
  - 72x72 avatar circle with caller initials and animated ringing pulse ring.
  - Displays caller name, phone number, live duration timer, and Bluetooth device badge.
  - 6-tile Quick Action Grid: Mute (mic toggle), Keypad (DTMF dialpad), Hold (toggle hold state), Add Call (opens contacts), Audio (volume sliders), and Device info.
  - Full 3x4 in-call DTMF dialer with tones sent via daemon IPC.
  - Prominent green Answer button (for incoming calls) and red End Call button.

### How to Test / Run
```bash
# 1. Open or toggle the BlueWire application window:
quickshell -c niri-nilastia-shell ipc call bluewire openWindow
quickshell -c niri-nilastia-shell ipc call bluewire toggleWindow

# 2. Switch tabs programmatically (0: Keypad, 1: Contacts, 2: Recents, 3: Audio & Device, 4: In Call):
quickshell -c niri-nilastia-shell ipc call bluewire setTab 0
quickshell -c niri-nilastia-shell ipc call bluewire setTab 1
quickshell -c niri-nilastia-shell ipc call bluewire setTab 2
quickshell -c niri-nilastia-shell ipc call bluewire setTab 3

# 3. Synchronize phone contacts via Bluetooth PBAP (all 718 contacts):
quickshell -c niri-nilastia-shell ipc call bluewire syncContacts
quickshell -c niri-nilastia-shell ipc call bluewire getContacts

# Or run standalone PBAP contact sync script directly:
python3 /home/saravana/projects/nilastia-bluetooth-calls/backend/sync_contacts.py

# 4. Query call status and call history via IPC:
quickshell -c niri-nilastia-shell ipc call bluewire getStatus
quickshell -c niri-nilastia-shell ipc call bluewire getHistory

# 5. Simulate incoming and active calls to test banner, keypad, and HUD synchronization:
quickshell -c niri-nilastia-shell ipc call bluewire mock_incoming "+91 98765 43210" "Sarah Connor"
quickshell -c niri-nilastia-shell ipc call bluewire answer
quickshell -c niri-nilastia-shell ipc call bluewire toggleMute
quickshell -c niri-nilastia-shell ipc call bluewire hangup

# 6. Test In-Call Tab 4 directly during an active call:
# Notice that AppWindow automatically switches to Tab 4 ("In Call")
# Test the 6-tile Quick Action Grid (Mute, Keypad, Hold, Add Call, Audio, Device)
# Test DTMF tones by clicking Keypad and entering numbers

# 7. Test Call HUD bubble morphing:
# When a call is active, leave mouse idle off the CallPopup card for 6 seconds
# Verify it smoothly morphs into the compact 138x52 pill bubble
# Click the bubble to expand back to full card; double-click to open AppWindow

# 8. Dial a number directly:
quickshell -c niri-nilastia-shell ipc call bluewire dial "9876543210"

# 9. Clear call history:
quickshell -c niri-nilastia-shell ipc call bluewire clearHistory

# 11. Live Incoming Call Test Verification:
# An incoming call received on the paired phone is automatically detected by WirePlumber and nilastia-bluewire-daemon.
# The overlay HUD (CallPopup.qml) maps immediately to eDP-1:
# - Displays caller number and resolved PBAP contact name
# - Provides Answer, Decline, and Mute buttons
# - On answer, transitions to active call with live duration timer
# - On hangup, closes cleanly and logs the call to call history

# 12. Desktop Tiled Window Column Verification:
# Open BlueWire window and verify it opens tiled at 520px column width (matching Nexus Settings):
quickshell -c niri-nilastia-shell ipc call bluewire openWindow
niri msg -j windows | grep -i bluewire
# Output confirms: "is_floating": false, "tile_size": [520.0, 1042.0], "window_size": [520, 1042]
quickshell -c niri-nilastia-shell ipc call bluewire closeWindow

# 13. Three-Way Calling (Hold, Resume, Swap, and Merge):
# Test Hold / Resume toggle via IPC:
quickshell -c niri-nilastia-shell ipc call bluewire mock_incoming "+91 98765 43210" "Alice"
quickshell -c niri-nilastia-shell ipc call bluewire mock_answer
quickshell -c niri-nilastia-shell ipc call bluewire mock_hold
quickshell -c niri-nilastia-shell ipc call bluewire getStatus
# Returns: "call": {"id": "/mock/call/0", "state": "held", ...}
# Call mock_hold again to resume:
quickshell -c niri-nilastia-shell ipc call bluewire mock_hold
quickshell -c niri-nilastia-shell ipc call bluewire getStatus
# Returns: "call": {"id": "/mock/call/0", "state": "active", ...}
quickshell -c niri-nilastia-shell ipc call bluewire mock_hangup

# Test real D-Bus hold / swap / merge methods against WirePlumber native telephony:
quickshell -c niri-nilastia-shell ipc call bluewire hold
quickshell -c niri-nilastia-shell ipc call bluewire swap
quickshell -c niri-nilastia-shell ipc call bluewire merge

# 14. Contact Name Resolution Verification:
# Test that incoming calls with phonebook numbers automatically resolve to the contact's name:
quickshell -c niri-nilastia-shell ipc call bluewire mock_incoming "+918122971577" ""
quickshell -c niri-nilastia-shell ipc call bluewire getStatus
# Output verifies: "call": {"id": "/mock/call/0", "state": "incoming", "number": "+918122971577", "name": "Ammachii"}

# Verify that dummy "Test Caller" strings cannot override the real resolved name:
quickshell -c niri-nilastia-shell ipc call bluewire mock_incoming "+918122971577" "Test Caller"
quickshell -c niri-nilastia-shell ipc call bluewire getStatus
# Output verifies: "name": "Ammachii"

# Clean up call state:
quickshell -c niri-nilastia-shell ipc call bluewire mock_hangup
quickshell -c niri-nilastia-shell ipc call bluewire getStatus
# Output verifies: "call": null
```
