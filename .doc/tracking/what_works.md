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

---

## Panel Reveal Modes: Click-Edge ("Click to Show") vs. Hover

### What Works
*   **Unified Panel Reveal Modes:**
    *   Replaced rigid hover-only and drag-only mechanics with a flexible `revealMode` (`"hover"`, `"click"`, `"off"`) across all desktop panels:
        *   **Dashboard:** Reveal on hover, reveal on edge click, or shortcut only.
        *   **Taskbar:** Always visible (persistent), reveal on hover, reveal on edge click, or shortcut only.
        *   **Launcher:** Reveal on hover, reveal on edge click, or shortcut only.
        *   **Sidebar (Notification Center):** Reveal on hover, reveal on edge click, or shortcut only.
        *   **Quick Toggles (Utilities):** Reveal on hover, reveal on corner click, or shortcut only.
        *   **Volume & Brightness (OSD):** Hardware keys only (recommended), reveal on edge click, or reveal on hover.
*   **Click-to-Open and Hover-to-Close Mechanics:**
    *   In Click mode, resting or moving the cursor along the screen edge does not pop open panels, completely eliminating accidental triggers when switching browser tabs, closing maximized windows, or scrubbing video players.
    *   Clicking the top border reveals Dashboard.
    *   Clicking the bottom border reveals Launcher.
    *   Clicking the right border reveals Notification Center (Sidebar).
    *   Clicking the bottom-right corner reveals Quick Toggles (Utilities).
    *   Clicking the left border reveals Taskbar (when not persistent).
    *   **Auto-Close on Cursor Departure:** Once a panel is opened via click, moving the mouse cursor away from the panel area immediately closes it automatically without requiring outside clicks, matching user expectations for rapid drawer glances.
    *   Clicking outside any open panel or clicking the border itself also immediately dismisses it cleanly.
    *   **Persistent Shortcut Mode:** Panels opened via keyboard hotkeys (`Super+G`, `Mod+Space`, `Mod+N`) maintain persistent visibility until explicitly toggled or dismissed outside.
*   **Smart Corner Exclusion in Hover Mode:**
    *   Hover mode on the Dashboard excludes the top-right corner (window close button zone), preventing accidental Dashboard popups when closing or manipulating maximized application windows.
*   **Decoupled OSD Mouse Triggers:**
    *   The volume and brightness sliders no longer pop out unexpectedly when the cursor brushes past the right screen edge. Setting OSD to "Keys only" ensures sliders appear strictly when pressing physical hardware keys.
*   **Dynamic Nexus Settings UI:**
    *   Nexus Panels pages (`DashboardPanel.qml`, `TaskbarPanel.qml`, `LauncherPanel.qml`, `SidebarPanel.qml`, `UtilitiesPanel.qml`) provide native `SelectRow` controls with live preview and disk persistence.
    *   `PanelsPage.qml` dynamic subtexts reflect the active reveal mode ("Reveal on hover", "Reveal on click", "Always visible", "Shortcut only").

### How to Test / Run
1.  Open Nexus settings (`Super+N` or runner -> Nilastia Settings -> **Panels**).
2.  Navigate to **Dashboard** -> change **Reveal mode** to **Click**.
3.  Move mouse cursor to the top edge of the screen: verify the Dashboard does NOT open on hover.
4.  Left-click directly on the top screen border: verify the Dashboard slides open immediately.
5.  Move the mouse cursor down into the workspace away from the Dashboard: verify the Dashboard automatically slides closed!
6.  Navigate to **Utilities** -> change **Reveal mode** to **Click**.
7.  Click the bottom-right corner: verify Quick Toggles opens immediately.
8.  Move the mouse cursor away from the bottom-right corner card: verify Quick Toggles automatically slides closed!
9.  Press `Super+G` (Dashboard shortcut): verify the Dashboard stays open while moving the cursor across the screen until clicked outside.
10. Navigate to **Notifications** in Nexus Panels: verify Reveal mode options (Click, Hover, Drag / Shortcut only) and Drag threshold slider.
11. Navigate to **Volume & Brightness** in Nexus Panels: verify Master Enable, Reveal mode (Keys only, Click, Hover), Brightness toggle, Microphone indicator, and Auto-hide delay stepper.
12. Move cursor along the right screen edge: verify the volume/brightness sliders stay hidden when set to Keys only.
13. Press hardware volume up/down keys: verify the OSD slider displays smoothly.

---

## BlueWire Telephony Call Audio Routing & ALSA Restoration

### What Works
*   **Automatic Laptop Hardware Speaker Unmuting:** When a Bluetooth call connects, `nilastia-bluewire-daemon` automatically un-mutes the ALSA hardware `Speaker` channel on `PCH`/`0` and sets volume to 85%, ensuring sound is played through the physical laptop speakers even if headphone jack sensing is detected as active.
*   **Automatic Built-in Microphone Selection & Preamp Boost:** The daemon sets the source port to `analog-input-internal-mic`, enables ALSA `Capture` (`cap 85%`), and boosts gain via `Internal Mic Boost` (+10dB), ensuring outgoing voice is clear.
*   **Native PipeWire SCO Stream Bridging:** Detects active `bluez_input` and `bluez_output` nodes via `pw-dump Node` without polling obsolete PulseAudio short sinks/sources.

### How to Test / Run
1. Trigger a mock call via IPC:
   ```bash
   quickshell -c niri-nilastia-shell ipc call bluewire mock_incoming "+919876543210" "Tester"
   quickshell -c niri-nilastia-shell ipc call bluewire mock_answer
   ```
2. Verify hardware audio status:
   ```bash
   amixer -c PCH sget Speaker
   amixer -c PCH sget Capture
   pactl list sinks | grep "Active Port"
   pactl list sources | grep "Active Port"
   ```
3. Hangup:
   ```bash
   quickshell -c niri-nilastia-shell ipc call bluewire mock_hangup
   ```

---

## Desktop Clock Dragging, Resizing & Edge Interactivity

### What Works
* **Fluid Drag Moving with Full Widget Footprint:** Clicking and dragging anywhere on the desktop clock body translates its position across the desktop with 1:1 precision. Explicit `width: implicitWidth` and `height: implicitHeight` ensure the entire clock surface is covered by `dragArea`, preventing click misrouting.
* **Separation of Dragging vs Resizing:** Normal dragging across the clock body only translates position without altering scale. Resizing is strictly isolated to the compact 28x28px corner handle at the bottom-right corner.
* **Continuous Edge/Corner Interactivity & Safe Boundary Clamping:** The clock can be freely dragged near screen edges and corners without freezing or becoming non-draggable. Safe boundary clamping prevents the clock from ever encroaching into `nilastia-drawers`'s edge trigger zones, guaranteeing that mouse hover and click events remain 100% active.
* **Safe Bounds Clamping:** Clamping prevents the clock from sliding behind the taskbar or entering perimeter drawer masks.
* **Stable Corner Scale Handle:** Dragging the bottom-right corner resize handle (`28px`, `z: 10`) scales the clock smoothly between 0.5x and 3.0x using stable diagonal delta math (`(dx + dy) / 2.0`) without coordinate feedback loops or abnormal ballooning.
* **Dynamic Behavior Disabling:** Interactive resizing disables spring animations mid-drag for instant response, restoring smooth animation on mouse release or programmatic resets.
* **Lock Toggle & Reset:**
  - Right-click anywhere on the clock to toggle position locking on/off.
  - Hovering displays the lock pill button in the top-right corner with current lock status.
  - Double-clicking the lock pill or double-clicking the clock body resets the clock back to the exact screen center, resets scale to 1.0x, and unlocks it.
* **IPC Controls (`target: "clock"`):**
  - Reset to center: `quickshell -c niri-nilastia-shell ipc call clock reset`
  - Unlock: `quickshell -c niri-nilastia-shell ipc call clock unlock`
  - Lock: `quickshell -c niri-nilastia-shell ipc call clock lock`
  - Toggle lock: `quickshell -c niri-nilastia-shell ipc call clock toggleLock`
* **Parallax Synchronization:** The clock's translation follows parallax wallpaper movements, while touch/click targets and blur masks stay aligned via `actualX` and `actualY`.

### How to Test / Run
1. Go to an empty workspace or unoccupied desktop area.
2. Click and drag the clock across the screen: verify it moves cleanly without changing scale or size.
3. Drag the clock near the screen borders and corners: verify safe clamping prevents it from exiting or locking up.
4. Click and drag specifically on the bottom-right corner resize handle (`south_east` icon): verify it scales smoothly between 0.5x and 3.0x.
5. Right-click the clock to lock it (cursor becomes arrow; dragging is disabled). Right-click again to unlock.
6. Double-click the clock body or the top-right lock pill to reset to the screen center.
7. Alternatively, trigger reset via IPC:
   ```bash
   quickshell -c niri-nilastia-shell ipc call clock reset
   ```

---

## Natural-Language Configuration Plugin (Needle 2)

### What Works
*   **Offline Natural-Language Configuration:** Allows controlling desktop and system settings using plain natural English through the `nilastia config ask` command.
*   **Decoupled Architecture:** Needle 2 only selects structured tool calls; Nilastia handles validation, transactional backups, atomic replacement (`tempfile` + `os.replace`), live reloading, and instant rollback.
*   **29 Semantic Tool Schemas:** Strict parameter validation across:
    *   *Compositor Window Opacity:* `set_inactive_window_opacity` (0.0..1.0), `set_active_window_opacity` (0.0..1.0), `set_window_opacity` (0.0..1.0).
    *   *Compositor Window Geometry & Decorations:* `set_window_corner_radius` (0..64px), `set_window_gaps` (0..64px), `set_window_border` (enabled, width), `set_window_shadows` (enabled).
    *   *Theme Schemes & Flavours:* `set_theme_scheme` (15 palettes: catppuccin, dracula, nord, gruvbox, tokyonight, rosepine, etc.), `set_theme_mode` (`dark`/`light`), `set_theme_flavour` (`mocha`, `macchiato`, etc.).
    *   *Panels & Taskbar:* `set_bar_position` (`top`/`bottom`/`left`/`right`), `set_bar_reveal_mode`, `set_panel_reveal_mode` (dashboard, sidebar, launcher, utilities), `set_osd_reveal_mode` (`keys`, `click`, `hover`), `set_tray_enabled`.
    *   *Terminal & Displays:* `set_terminal_opacity`, `set_terminal_font_size`, `set_terminal_padding`, `set_terminal_blur`, `set_display_scale` (0.5..3.0), `set_adaptive_refresh_rate`.
    *   *Shell Desktop:* `set_shell_transparency`, `set_shell_blur`, `set_clock_format`, `set_clock_style`, `set_desktop_clock`, `set_audio_visualiser`, `set_animations`, `set_window_blur`.
*   **Atomic Niri KDL Rules Management:** Directly targets and mutates `~/.config/niri/config.d/30-window-rules.kdl` and `20-layout-and-overview.kdl`, invoking `niri msg action load-config-file` for instantaneous compositor reload.
*   **Opacity Discrimination:** Kitty terminal opacity is strictly isolated from Niri compositor window opacities (inactive vs active).
*   **Confidence Calibration & Percentage Grounding:** Grounding verification detects percentages (e.g. `85%` mapped to `0.85`), preventing token-splitting confidence drops.
*   **Multi-Domain Blur Handling:**
    *   *Backdrop / Shell Blur:* General queries ("turn on the blur", "turn of the blur", "turn on the blur effect") safely configure Nilastia shell backdrop blur (`shell.json`: `backdropEnabled = true`, `backdropBlurRadius = 32`).
    *   *Compositor Window Blur:* Explicit window blur queries ("turn on window blur") configure Niri compositor blur (`passes 4` in `~/.config/niri/config.kdl`).
    *   *Terminal Blur:* Terminal blur queries ("enable blur in kitty") configure `background_blur` in `kitty.conf`.
*   **Boolean Grounding & Polarity Matching:** Fixed boolean argument calibration (`isinstance(v, bool)` evaluated before numeric checks), reliably identifying state changes (`on`/`enable`/`show` vs `off`/`of`/`disable`).
*   **Semantic Tool Grounding & Hallucination Suppression:** Enforces semantic keyword presence (`TOOL_SEMANTICS`) on model outputs, dropping confidence to 0.0 when tools are hallucinated (e.g. mapping "blur effect" to audio visualiser) and routing safely to deterministic fallbacks.
*   **Dry-Run Mode:** Running `nilastia config ask --dry-run "<request>"` previews proposed configuration diffs without writing to disk.
*   **Explain Mode:** Running `nilastia config ask --explain "<request>"` prints structured intent, tool name, parsed arguments, confidence score, and rationale.
*   **Confidence Gating:** Enforces configurable threshold (default `0.80`), rejecting ungrounded or low-confidence mutations.
*   **Ambiguity Guard:** Intercepts underspecified queries ("make it smaller", "make it darker") and presents candidate options rather than making assumptions.
*   **Negative Abstention:** Off-topic queries ("what is the weather?", "tell me a joke") produce zero tool calls and modify nothing.
*   **Test Suite & Benchmark:** 48 automated unit and integration tests passing (`pytest tests/`). Comprehensive benchmark tool (`benchmark.py`) on 37 test samples achieving 81.08% intent accuracy and 100% negative abstention.

### How to Test / Run
1. Test backdrop blur toggle:
   ```bash
   nilastia config ask "turn on the blur "
   nilastia config ask "turn of the blur "
   nilastia config ask "turn on the blur effect"
   ```
2. Test compositor window blur:
   ```bash
   nilastia config ask "turn on window blur"
   ```
3. Test inactive window opacity:
   ```bash
   nilastia config ask "set in-active window opacity to 85%"
   ```
2. Test window corner radius and gaps:
   ```bash
   nilastia config ask "set window corner radius to 16"
   nilastia config ask "set window gaps to 12"
   ```
3. Test theme scheme switching:
   ```bash
   nilastia config ask "switch to catppuccin theme"
   ```
4. Test taskbar position:
   ```bash
   nilastia config ask "move status bar to the bottom"
   ```
5. Test explain mode:
   ```bash
   nilastia config ask --dry-run --explain "set terminal font size to 14"
   ```
6. Test ambiguity rejection:
   ```bash
   nilastia config ask --dry-run "make it smaller"
   ```
7. Test off-topic query rejection:
   ```bash
   nilastia config ask --dry-run "what is the weather?"
   ```
8. Run the automated test suite:
   ```bash
   python3 -m pytest /home/saravana/projects/nilastia-needle/tests/ -v
   ```
9. Run the benchmark tool:
   ```bash
   python3 /home/saravana/projects/nilastia-needle/benchmark.py --dataset /home/saravana/projects/nilastia-needle/dataset/test.jsonl
   ```

---

## Desktop Clock Material 3 Overhaul & Reload Persistence

### What Works
*   **Static Non-Blinking Pill Colon:** Removed `SequentialAnimation on opacity` from both the desktop background and taskbar `Pill` clock styles. The colon is solid and static at 0.85 opacity without visual distraction.
*   **Cyber Style Removal:** Completely deleted Cyber clock styles from background and bar components. Previous configs using `cyber` safely fall back to `Default`.
*   **Material 3 Analog & Digital Clock Styles:**
    *   *M3 Analog (Classic) (`analog`):* Clean circular dial with rounded capsule pill hour and minute hands, 12/3/6/9 major numerals, minor hour tick dots, and integrated date chip.
    *   *M3 Analog (Flower) (`flower`):* Iconic 12-lobed flower/scallop contour (`MaterialShape.Cookie12Sided`), playful thick pill hands, and center day/date circular disc.
    *   *M3 Analog (Clover) (`clover`):* Soft 4-lobed cushion/clover dial (`MaterialShape.Cookie4Sided`) with petal hour numerals and date badge.
    *   *M3 Stacked (`stacked`):* Android lockscreen signature two-line bold stacked hours and minutes in ExtraBold typography with date capsule.
    *   *M3 Bento (`bento`):* Dual expressive rounded bento cards for hours and minutes with full-width date capsule.
*   **Full Disk Persistence Across Shell Reloads:** Custom clock positions (drag coordinates), custom scale (resize handle), and lock state are stored in `~/.local/state/nilastia/desktop_clock.json` via `FileView` in `services/Time.qml`. Position and scale are 100% preserved across shell reloads, restarts (`systemctl --user restart niri-nilastia-shell.service`), and reboots.
*   **Instant Flush on Mouse Release:** Position and scale changes are immediately committed to disk on mouse release during dragging or resizing.
*   **Smooth Fade-In:** Clock loader fades in after persistent state is loaded, preventing visual jumping on shell startup.

### How to Test / Run
1. Change clock style to any of the new Material 3 styles via Nexus:
   - Open Nexus Settings (`Super+N`) -> **Wallpaper & Style** -> **Clock style** dropdown.
   - Choose: `M3 Analog (Classic)`, `M3 Analog (Flower)`, `M3 Analog (Clover)`, `M3 Stacked`, or `M3 Bento`.
2. Or change clock style via natural language CLI:
   ```bash
   nilastia config ask "switch clock style to flower"
   nilastia config ask "use analog clock"
   nilastia config ask "switch clock style to stacked"
   ```
3. Test Pill clock non-blinking colon:
   - Switch clock style to `Pill`.
   - Observe the colon: verify it remains solid and static without blinking.
4. Test reload persistence:
   - Unlock the clock (right-click or click top-right lock icon).
   - Drag the clock to a new position on the desktop.
   - Drag the bottom-right corner resize handle to change the scale.
   - Reload/restart the shell:
     ```bash
     systemctl --user restart niri-nilastia-shell.service
     ```
   - Verify the clock remains at your custom position and scale without resetting!
5. Test reset:
   - Double-click the clock body or lock icon, or run:
     ```bash
     quickshell -c niri-nilastia-shell ipc call clock reset
     ```
   - Verify it resets cleanly to screen center and saves the reset state.

---

## Universal Shell & Window X-Ray Blur Architecture

### What Works
* **Working X-Ray Mode on Shell Drawers:** "X-ray blur mode" in Nexus Compositor settings now works seamlessly across both workspace application windows (`30-window-rules.kdl`) and desktop shell panels (`nilastia-drawers` in `80-layer-rules.kdl`). When enabled, shell drawer panels (Dashboard, Sidebar, Launcher, Utilities, Session, Notifications) and the taskbar sample directly from the desktop wallpaper blur buffer for maximum GPU efficiency.
* **Sub-Region Offscreen Guarding:** An offscreen 1x1 anchor (`Region { x: -100; y: -100; width: 1; height: 1 }`) in `ContentWindow.qml` ensures `BackgroundEffect.blurRegion` is always registered with Quickshell while layer blur is active. Quickshell never unsets the Wayland blur region with `nullptr`, which completely prevents Niri from falling back to full-screen surface geometry blur.
* **Zero Window Erasure / Transparency Clashes:** Turning on both "X-ray blur mode" and "Shell Layer Blur" renders X-ray wallpaper blur strictly behind open drawer panels and the bar. Application windows across the entire rest of the desktop remain 100% visible, fully opaque, and untouched.
* **Idle Compositor Efficiency (144 FPS Preserved):** When all drawer panels are closed, Niri's `subregion.filter_damage` evaluates the offscreen anchor to an empty damage slice and returns immediately, skipping draw calls and GPU fill overhead completely.
* **Synchronized Configuration Writing:** Toggling `blur_xray` in Nexus or CLI synchronizes `xray true/false` across both `30-window-rules.kdl` and `80-layer-rules.kdl`.

### How to Test / Run
1. Open Nexus settings (`Super+N`) and navigate to **Compositor** -> **Blur & Transparency**.
2. Turn ON **Enable window background blur**.
3. Turn ON **X-ray blur mode** (under Window Background Blur).
4. Turn ON **Enable blur on system layers** (under Shell Layer Blur).
5. Open multiple windows (e.g. Brave browser, Kitty terminal, text editor) on the workspace.
6. Verify that all workspace windows remain **completely visible**!
7. Open any shell drawer (e.g. `Super+G` for Dashboard, `Super+A` for Launcher, or click Quick Settings):
   - Verify that the drawer has beautiful wallpaper X-ray blur behind it!
   - Verify that all windows beside or outside the drawer remain completely visible and sharp without disappearing!
8. Close the drawer:
   - Verify that workspace windows remain fully visible with zero artifacts or transparency issues.

---

## Streamlined 2D ColorPicker & Compositor Settings Overhaul

### What Works
* **Streamlined 2D ColorPicker (`components/controls/ColorPicker.qml`):**
  - Direct 2D Saturation-Value surface rendered with hardware-accelerated gradients. Instant, zero-lag 144 FPS touch and mouse reticle tracking without canvas redraw overhead.
  - Removed cumbersome color wheel and header switcher tabs per user feedback for a streamlined, direct interface.
  - Continuous rainbow Hue slider (0-360 degrees) and live checkerboard Opacity slider (0-100%).
  - Real-time split color swatch, hex input field, clipboard Copy button, and HSV/RGB numerical readouts.
  - Material 3 theme token swatches and curated accent chip presets.
* **Compositor Borders, Focus Ring & Shadows Settings (`modules/nexus/pages/CompositorBorders.qml`):**
  - Focus Ring: Added master enable toggle (`focus_ring_enabled`), width stepper, active focus ring color picker, and inactive focus ring color picker (clarified for multi-monitor setups).
  - Borders: Master enable toggle (`border_enabled`), width stepper, active window border color, and inactive window border color (applies to all unfocused windows on the current workspace).
  - Drop Shadows: Master toggle (`shadow_enabled`), softness (blur radius), spread, and color picker.
* **Working Niri Drop Shadows & Borders Synchronization (`compositorconfig.cpp`):**
  - Implemented `getToggleState()` and `setToggleState()` using explicit KDL `on` and `off` syntax for `shadow`, `border`, and `focus-ring`.
  - Fixes Niri drop shadows which previously remained disabled because Niri requires explicit `on` to activate shadows.
* **Zero Pure Black Text Across Compositor Settings:**
  - Added `import qs.services` to `CompositorBorders.qml` and `CompositorInput.qml`.
  - All hex code readouts, secondary subtexts, and status labels across `ToggleRow.qml`, `StepperRow.qml`, `SelectRow.qml`, `InfoRow.qml`, `SliderRow.qml`, and `PopupRow.qml` use `m3onSurfaceVariant` with dynamic luminance fallback (`Colours.getLuminance(c) < 0.35 ? Colours.palette.m3onSurface : c`), completely eliminating black text artifacts.

### How to Test / Run
1. Open Nexus settings (`Super+N`) and navigate to **Compositor** -> **Borders & Focus Ring**.
2. Verify that all color code readouts (e.g. `#FEDEFF`, `#94E2D5`, `#A679DD`) are rendered in crisp, high-contrast light text, **not black**.
3. Click any color row (e.g. **Active window border color**):
   - Verify that the streamlined 2D Color Area appears directly at the top with no header buttons or wheel.
   - Drag the 2D crosshair reticle: observe instantaneous, smooth color adjustment.
   - Drag the Hue and Opacity sliders.
   - Click a Material 3 preset token or copy hex to clipboard.
4. Test **Focus Ring vs Borders**:
   - Turn ON **Enable focus ring**: active window gets the focus ring outline.
   - Turn ON **Enable borders**: both active and inactive windows display their distinct border colors.
   - Verify that inactive windows on the workspace show the configured **Inactive window border color**.
5. Test **Drop Shadows**:
   - Turn ON **Enable drop shadows**.
   - Check `~/.config/niri/config.d/20-layout-and-overview.kdl` to confirm `shadow { on ... }` is written.
   - Observe real-time drop shadows beneath tiling windows.

---

## Shell Transparency & Layer Blur Nexus Consolidation

### What Works
* **Unified Visual Effects Management (`modules/nexus/pages/CompositorBlur.qml`):**
  * All shell opacity and blur options are organized under a single **Shell Transparency & Layer Blur** card.
  * **Master Shell Transparency Switch:** `GlobalConfig.appearance.transparency.enabled` toggles transparency for all shell windows, drawers, panels, and taskbar.
  * **Fine-Tuning Opacity Sliders:**
    - **Shell base opacity:** Adjusts primary shell container alpha (`Colours.transparency.base`).
    - **Shell layers opacity:** Adjusts child card, button, and surface overlay alpha (`Colours.transparency.layers`).
  * **Compositor Layer Blur:** `Compositor.layer_blur_enabled` enables hardware-accelerated Niri layer blur behind open shell drawers and panels. Includes contextual hint if shell transparency is disabled.
* **Streamlined Wallpaper & Style (`modules/nexus/pages/WallpaperAndStyle.qml`):**
  * Removed redundant transparency controls.
  * Retained clean, focused **Theme Mode** section with dedicated Dark/Light theme toggle.

### How to Test / Run
1. Open Nexus settings (`Super+N`).
2. Navigate to **Wallpaper & style**:
   * Verify that the page ends cleanly with **Theme Mode** (Dark theme toggle) and **Background Components** (Desktop clock).
   * Confirm that the duplicate transparency toggle and opacity sliders are no longer present.
3. Navigate to **Compositor** -> **Blur & Transparency**:
   * Scroll to the **Shell Transparency & Layer Blur** section.
   * Turn ON **Enable shell transparency**: observe the smooth reveal of **Shell base opacity** and **Shell layers opacity** sliders.
   * Drag the opacity sliders: notice the immediate opacity response across open shell drawer panels and the bar.
   * Turn ON **Enable blur on system layers**: verify that compositor blur activates behind the transparent shell surfaces.

---

## Compositor Performance Settings Relocation & Subpage Retirement

### What Works
* **Adaptive Display Refresh Rate in Display Settings (`modules/nexus/pages/DisplayPage.qml`):**
  * Integrated **Adaptive display refresh rate** toggle into the Display Configuration card directly alongside Refresh Rate and VRR.
  * Toggling the switch updates `GlobalConfig.general.battery.adaptiveRefreshRate`.
  * Preserves bidirectional synchronization: selecting a manual refresh rate in the dropdown sets `adaptiveRefreshRate` to `false`, and toggling adaptive mode on immediately reflects in the dropdown subtext.
  * Ensures clean card rounding with `last: true` regardless of whether Variable Refresh Rate (VRR) is supported on the connected display.
* **Adaptive Compositor Blur in Blur & Transparency (`modules/nexus/pages/CompositorBlur.qml`):**
  * Added dedicated **Power Optimisation** section featuring the **Adaptive compositor blur** toggle (`GlobalConfig.general.battery.adaptiveBlur`).
  * Automatically coordinates with `BatteryMonitor.qml` to pause both window blur and layer blur on battery power to conserve GPU energy.
  * Included in `resetToRecommended()` default restore routine.
* **Streamlined Compositor Menu (`modules/nexus/pages/CompositorPage.qml`):**
  * Retired the redundant 2-item **Performance** subpage.
  * Unregistered `CompositorPerformance` from `modules/nexus/PageCompRegistry.qml`.
  * Removed dead file `modules/nexus/pages/CompositorPerformance.qml`.

### How to Test / Run
1. Open Nexus settings (`Super+N`).
2. Navigate to **Display**:
   * Verify the **Adaptive display refresh rate** toggle is present at the bottom of the Display Configuration card.
   * Toggle it ON: observe the Refresh Rate dropdown subtext change to `"Adaptive active (selecting manual rate overrides)"`.
   * Select a manual refresh rate (e.g. 144Hz): observe that the Adaptive toggle automatically turns OFF.
3. Navigate to **Compositor**:
   * Verify that **Performance** is no longer listed in the menu and **Blur & Transparency** cleanly caps the bottom of the card list.
4. Open **Blur & Transparency**:
   * Scroll down to verify the **Power Optimisation** card containing **Adaptive compositor blur**.
   * Toggle it ON/OFF and verify state persistence.

---

## Adaptive Full Opacity on Battery Power

### What Works
* **Nested Power Optimisation Sub-Option (`modules/nexus/pages/CompositorBlur.qml`):**
  * When **Adaptive compositor blur** is enabled, the **Full opacity on battery** sub-toggle (`GlobalConfig.general.battery.adaptiveOpacity`) is revealed with connected card rounding.
  * Toggling the switch updates `GlobalConfig.general.battery.adaptiveOpacity`.
* **Complete Opacity Overhaul on Battery (`modules/BatteryMonitor.qml`):**
  * When running on battery (`UPower.onBattery == true`) and `adaptiveBlur && adaptiveOpacity` is active:
    - Sets focused window opacity (`active_opacity`) to `1.0` (100% opaque).
    - Sets unfocused window opacity (`inactive_opacity`) to `1.0` (100% opaque).
    - Sets shell transparency (`GlobalConfig.appearance.transparency.enabled`) to `false` (100% solid shell surfaces).
    - Eliminates alpha blending overhead, wallpaper re-draws behind windows, and compositor blending passes.
* **Persistent Preference Retention:**
  * User preferences (`preferredActiveOpacity`, `preferredInactiveOpacity`, and `preferredShellTransparency`) are stored in `GeneralBattery` (`plugin/src/Nilastia/Config/generalconfig.hpp`).
  * Reconnecting to AC power or disabling the feature immediately restores the user's custom opacities and shell transparency state.

### How to Test / Run
1. Open Nexus settings (`Super+N`).
2. Navigate to **Compositor** -> **Blur & Transparency**.
3. Under **Power Optimisation**:
   * Turn ON **Adaptive compositor blur**.
   * Observe the **Full opacity on battery** sub-toggle appear directly below.
   * Turn ON **Full opacity on battery**.
4. Test Battery Transition:
   * Disconnect charger (simulate battery power via UPower or unplug):
     - All active windows, inactive windows, and shell panels immediately become 100% solid/opaque.
   * Reconnect charger:
     - Window opacities and shell transparency immediately restore to your configured values.

---

## Alpha-Aware Effective Luminance Contrast Engine

### What Works
* **Alpha-Blended Background Luminance Calculation (`services/Colours.qml`):**
  * Added `Colours.getEffectiveLuminance(c, bgLum)` which combines the RGB luminance of translucent surfaces with the container's background luminance according to the surface's alpha channel.
* **Guaranteed High Contrast in SplitButton Dropdowns (`components/controls/SplitButton.qml`):**
  * Evaluates contrast difference between text color and effective background luminance.
  * When translucent primary pill buttons become dark on screen due to shell transparency layers, the system detects low contrast (`< 0.40`) and dynamically applies `m3onSurface` (light off-white in dark mode, crisp dark in light mode).
  * Automatically propagates to the dropdown arrow (`expandIcon`) and hover/active ripple state layers.
  * Eliminates dark-on-dark text across all `SelectRow` delegates (Resolution, Refresh Rate, Scaling, Audio, Network).

### How to Test / Run
1. Open Nexus settings (`Super+N`).
2. Navigate to **Display**:
   * Observe the dropdown selectors for **Resolution**, **Refresh Rate**, and **Scaling**.
   * Verify that the selected option text and dropdown arrows render in bright, high-contrast, perfectly legible text regardless of whether shell transparency is set to high, medium, low, or disabled.
3. Navigate to **Compositor** -> **Blur & Transparency**:
   * Drag the **Shell layers opacity** and **Shell base opacity** sliders across their full range (from 10% to 100%).
   * Verify that dropdown text across the shell remains sharp, bright, and legible at all opacity settings.

---

## Shell Blur at 100% Opacity Fullscreen Window Disappearance Fix

### What Works
* **Guaranteed Subregion Protection (`modules/drawers/ContentWindow.qml`):**
  * `BackgroundEffect.blurRegion` is permanently and unconditionally bound to `blurRegionRef`.
  * Because `blurRegionRef` contains an offscreen anchor (`[-100, -100, 1, 1]`), Quickshell never unsets the Wayland blur region with `nullptr` regardless of whether the shell is translucent or 100% opaque.
  * Completely prevents Niri from falling back to fullscreen 1920x1080 surface geometry blur/X-ray when shell opacity is at 100%.
  * All workspace application windows remain 100% visible and interactive at all opacity levels when shell blur is enabled.
* **Proper Layer Blur in Compositor Config:**
  * Added `blur true` to `nilastia-drawers` in `setLayerRuleBlur()` in `compositorconfig.cpp` and `80-layer-rules.kdl`.

### How to Test / Run
1. Open Nexus settings (`Super+N`).
2. Navigate to **Compositor** -> **Blur & Transparency**.
3. Under **Shell Transparency & Layer Blur**:
   * Set **Shell transparency** switch to OFF (or set opacity to 100%).
   * Toggle ON **Enable blur on system layers** (`layer_blur_enabled`).
4. Look at the desktop with multiple workspace windows open:
   * Verify that all open application windows remain completely visible and crisp.
   * Verify that no fullscreen wallpaper or X-ray effect covers the workspace windows.

---

## Hybrid Shell Drop Shadows

### What Works
* **Nexus Shell Shadow Toggle (`modules/nexus/pages/CompositorBorders.qml`):**
  * Added **Enable shell drop shadows** (`ToggleRow`) under **Compositor** -> **Borders & Focus Ring** -> **Drop Shadows**.
  * Binds to `GlobalConfig.appearance.shellShadow.enabled` with automatic persistence in `~/.config/nilastia/shell.json`.
* **Hardware-Accelerated Drawer Shadows (`modules/drawers/ContentWindow.qml`):**
  * Each active drawer panel (Dashboard, Launcher, Sidebar, Utilities, OSD, Notifications, Clipboard, Session, Popouts) dynamically casts a hardware-accelerated `RectangularShadow` onto workspace windows.
  * The expanded taskbar (`BarWrapper`) casts a clean drop shadow along its right edge onto the workspace when revealed.
  * Shadows smoothly adapt to `Compositor.shadow_softness`, `Compositor.shadow_spread`, and `Compositor.shadow_color`.
  * In fullscreen applications, shell shadows fade away smoothly via `root.shadowOpacity`.
* **Synchronized Elevation on Floating Elements (`components/effects/Elevation.qml`):**
  * Floating context menus, dropdowns, and popout dialogs inherit the configured `Compositor.shadow_color` when shell drop shadows are enabled.

### How to Test / Run
1. Open Nexus settings (`Super+N`).
2. Navigate to **Compositor** -> **Borders & Focus Ring**.
3. Under **Drop Shadows**:
   * Toggle ON **Enable shell drop shadows**.
   * Adjust **Shadow softness** (e.g. 30px) and **Shadow spread** (e.g. 5px).
   * Pick a custom **Shadow color** via the ColorPicker.
4. Open the Launcher (`Super+Space`), Dashboard, or hover over the taskbar:
   * Observe the soft drop shadow cast behind the drawer panels over workspace windows.
   * Open a context menu or dropdown: observe the synchronized elevation shadow.

---

## Direct KMS Screen Recording Calibration (60 FPS Locked Stability)

### What Works
* **Portal Bypass via Direct KMS:** `nilastia record` captures directly from the Linux Kernel Mode Setting (`KMS`) display scanout (`-w eDP-1` via `/dev/dri/card1` and `gsr-kms-server`), eliminating the low-FPS bottleneck (19-26 FPS) associated with `xdg-desktop-portal` and PipeWire.
* **Locked 60 FPS Framerate:** Default framerate is calibrated to 60 FPS, maintaining consistent 60.0-61.0 FPS update rates without dropping frames or causing desktop stutter.
* **CLI Framerate Control:** Added `-f, --fps` to `nilastia record` so users can target specific framerates (e.g., `-f 60` or `-f 144`).
* **Calibrated High Quality:** Default quality preset is calibrated to `high` with `-c mp4` container format, providing sharp clarity and optimal encoder performance.
* **Hybrid GPU Architecture:** Intel iGPU captures and encodes display scanout via VA-API without stealing compute/graphics resources or power from the discrete NVIDIA RTX 4050.

### How to Test / Run
```bash
# 1. Start direct KMS recording at locked 60 FPS (default):
nilastia record --start

# 2. Check the active recording log to confirm direct KMS connection and locked 60 FPS:
cat ~/.local/state/nilastia/record/recorder.log | grep -E "(KMS|update fps)" | tail -n 10

# 3. Stop the recording:
nilastia record --stop

# 4. Verify recorded video in ~/Videos/Recordings/:
ffprobe -v error -show_entries stream=codec_name,width,height,r_frame_rate ~/Videos/Recordings/$(ls -t ~/Videos/Recordings/ | head -n 1)
```

---

## On-Demand VRR Display Calibration (144 Hz Desktop Lock During Recording)

### What Works
* **On-Demand VRR (`variable-refresh-rate on-demand=true`):** Prevents the 144 Hz display refresh rate from dropping down to 60 Hz during direct KMS recording (`-f 60`) or video playback.
* **Locked 144 Hz Desktop:** During normal desktop usage, browser interaction, and screen recording, the panel remains strictly locked at `144.002 Hz`.
* **Gaming FreeSync/G-Sync:** When a fullscreen game matching a VRR window rule launches, Niri dynamically activates VRR to prevent screen tearing.
* **CLI & Nexus Synchronization:** Toggling VRR in Nexus (**Display** page) or via `nilastia output eDP-1 --vrr` writes `variable-refresh-rate on-demand=true` and dispatches live runtime IPC `niri msg output eDP-1 vrr --on-demand on`.

### How to Test / Run
```bash
# 1. Check current Niri output state:
niri msg -j outputs | jq '.[].vrr_enabled'
# Expected output: false (on desktop, confirming panel is locked at 144 Hz)

# 2. Start a screen recording:
nilastia record --start

# 3. Check output state during recording:
niri msg -j outputs | jq '.[].vrr_enabled'
# Expected output: false (still 144 Hz, no refresh rate drop)

# 4. Stop recording:
nilastia record --stop
```

---

## Zero-Lag 144 FPS Direct KMS Recording Pipeline

### What Works
* **Zero-Copy KMS Capture via `gpu-screen-recorder`:** Hardware-level direct DMA-BUF capture on Intel KMS (`/dev/dri/card1`) avoiding the 100%+ CPU saturation caused by Wayland socket copying in `wf-recorder`.
* **Native 144 FPS Cadence:** Captures at locked 144 FPS, synchronizing with Niri's vertical presentation intervals without pageflip delays or refresh rate downclocking.
* **Low CPU Overhead (~25%):** Uses Intel QuickSync VA-API hardware acceleration, keeping CPU overhead under 25% for fluid desktop interaction, gaming, and multitasking.
* **Persistent 144 Hz Display:** With `variable-refresh-rate on-demand=true`, the display panel remains strictly locked at `144.002 Hz`.

### How to Test / Run
```bash
# 1. Start recording (automatically targets 144 FPS with direct KMS hardware acceleration):
nilastia record --start

# 2. Verify active process is gpu-screen-recorder running at ~25% CPU:
ps aux | grep gpu-screen-recorder | grep -v grep

# 3. Check live capture framerate in log:
cat ~/.local/state/nilastia/record/recorder.log | grep "update fps" | tail -n 5

# 4. Verify Niri output remains locked at 144 Hz without refresh rate drops:
niri msg -j outputs | jq '.[].modes[0]'

# 5. Stop recording:
nilastia record --stop

# 6. Check metadata of the recorded video in ~/Videos/Recordings/:
ffprobe -v error -show_entries stream=codec_name,width,height,r_frame_rate,avg_frame_rate ~/Videos/Recordings/$(ls -t ~/Videos/Recordings/ | head -n 1)
```

---

## Shell Outer Ring Cutout Shadow Behind Windows & Ghost Shadow Elimination

### What Works
* **Zero Ghost Shadows from Closed Panels:**
  - In [`modules/drawers/ContentWindow.qml`](file:///home/saravana/projects/calestia/nilastia/modules/drawers/ContentWindow.qml), `sessionBg` and `osdBg` bind visibility directly to `panels.session.visible && panels.session.opacity > 0` and `panels.osd.visible && panels.osd.opacity > 0`.
  - `PanelShadow` delegates declare `active: (root.screenState.osd || panels.osd.visible) && panels.osd.offsetScale < 0.99`, completely preventing retracted off-screen panels from casting blur shadows onto the right screen edge.
* **Volume, Microphone, and Brightness Sliders Restoration:**
  - Preserved original layout and interaction hierarchies for `osdWrapper` and `sessionWrapper` in [`modules/drawers/Panels.qml`](file:///home/saravana/projects/calestia/nilastia/modules/drawers/Panels.qml), ensuring hover hit zones, edge triggers, and volume/brightness key responsiveness function cleanly.
* **Dedicated Multi-Stop Physical Cutout Shadow:**
  - Implemented analytical physical cutout shadow on `WlrLayer.Background` with Niri rule `place-within-backdrop true` in [`modules/background/Background.qml`](file:///home/saravana/projects/calestia/nilastia/modules/background/Background.qml) using compiled GLSL shader [`modules/background/shaders/shell_cutout_shadow.frag.qsb`](file:///home/saravana/projects/calestia/nilastia/modules/background/shaders/shell_cutout_shadow.frag.qsb).
  - **Singular Static Overall Shadow:** Rendered in `wallpaperWin` (`namespace="nilastia-background-wallpaper"`), which Niri pins to the display backdrop behind all workspaces. When switching or sliding workspaces, the cutout shadow remains completely stationary, acting as a singular overall screen shadow anchored to the physical frame.
  - **Strictly Behind Windows:** Because `place-within-backdrop true` sits behind all workspace windows, open workspace client windows sit cleanly on top of the shadow, obscuring it without artifacts.
  - **Cutout Edge Origin & Zero Gap:** The shadow originates strictly at the cutout rim ($d = 0$) and extends 1.5px under the shell border to eliminate light slivers and anti-aliasing gaps. Beyond 1.5px ($d > 1.5$), it discards completely, preventing shadow bleeding to the monitor edge.
  - **Multi-Stop Lighting:** Tight contact shadow (quartic falloff, 0..contactSize px) providing deep occlusion at the bezel seam, combined with smooth ambient atmospheric diffusion (quartic bell curve, 0..softness px).
  - **Micro-Chamfer Specular Lip:** 1px metallic/beveled highlight lip along the inner rim ($u \in [0, 2.2]$ px) delivering the look of a precision-machined hardware bezel (0 bytes memory overhead, negligible GPU overhead).
  - **Smooth Rounded Corners:** Features polynomial smooth-max distance calculation `sdSmoothRoundedBox` that eliminates sharp 45-degree diagonal creases, delivering concentric circular curves matching `Config.border.rounding`.
  - **Dedicated Configuration:** Managed independently via `AppearanceCutoutShadow` (`Config.appearance.cutoutShadow.*`) in `shell.json` and configurable in Nexus Settings (Compositor -> Borders & Focus Ring -> Shell Cutout Shadow).

### How to Test / Run
```bash
# 1. Verify that the right screen edge has zero ghost shadow blobs when drawers are closed:
grim /tmp/edge-verify.png

# 2. Verify volume and brightness OSD sliders pop out on trigger:
quickshell -c niri-nilastia-shell ipc call drawers toggle osd
grim /tmp/osd-verify.png

# 3. Test shell cutout shadow configuration in Nexus:
# Super+N -> Compositor -> Borders & Focus Ring -> Shell Cutout Shadow
# Toggle "Enable cutout shadow", adjust softness, contact size, opacity, and micro-chamfer
grim /tmp/cutout-verify.png

# 4. Verify singular static shadow across workspace switches:
# Switch workspaces (Mod+Down / Mod+Up) and verify the shadow stays static on screen
niri msg action focus-workspace-down && sleep 0.5 && grim /tmp/cutout_ws2.png && niri msg action focus-workspace-up
```

---

## Dashboard Transition Fluidity & Rest Shadow Gating

### What Works
* The dashboard drawer (`Mod+D`) slides down smoothly at native 144 FPS with shell blur active.
* Content items translate along linear GPU coordinates without non-affine matrix shear or text distortion.
* Drop shadows on drawer panels (`PanelShadow`) are gated to activate only when panels reach rest (`offsetScale < 0.05`), avoiding concurrent Gaussian blur calculations while in motion.

### How to Test / Run
```bash
# 1. Trigger dashboard toggle via Quickshell IPC
quickshell -c niri-nilastia-shell ipc call drawers toggle dashboard

# 2. Verify smooth 144 FPS opening transition and absence of stutter
# Toggle again to close
quickshell -c niri-nilastia-shell ipc call drawers toggle dashboard
```

---

## Hollow Exterior-Only Shell Edge Drop Shadows

### What Works
* Drawer panels (Dashboard, Utilities, Launcher, Session, Sidebar, OSD, Notifications, Popouts) and the Left Bar render an exterior-only drop shadow via signed distance field shader (`panel_edge_shadow.frag.qsb`).
* Discards all interior pixels under the component body (`d < -1.5`), ensuring translucent frosted glass panels are 100% hollow inside without black underlays dulling or darkening their appearance.
* Incorporates a 1.5px sub-pixel seam lock (`-1.5 <= d <= 0.0`) under the perimeter edge, preventing light gaps or anti-aliasing slivers along panel boundaries.
* Dual-layer falloff combines crisp contact occlusion (0..6px) with soft ambient diffusion (0..shadowSoftness px).
* Elevation component wraps shadow colors with controlled alpha (`Qt.alpha(..., 0.35)`), preventing opaque black bleeding through menus, sliders, and notification cards.

### How to Test / Run
```bash
# 1. Open the dashboard drawer
quickshell -c niri-nilastia-shell ipc call drawers toggle dashboard

# 2. Capture screenshot and observe that the dashboard body is vibrant and translucent,
# with the drop shadow strictly projecting outward along the exterior edges:
grim /tmp/test_dashboard_shadow.png

# 3. Close the dashboard drawer
quickshell -c niri-nilastia-shell ipc call drawers toggle dashboard

# 4. Open the utilities drawer
quickshell -c niri-nilastia-shell ipc call drawers toggle utilities

# 5. Capture screenshot and verify the utilities card remains clean and translucent
# with shadow projecting outward to the left:
grim /tmp/test_utilities_shadow.png

# 6. Close the utilities drawer
quickshell -c niri-nilastia-shell ipc call drawers toggle utilities
```

---

## Rest-State Shell Shadows & Clean Blur Deactivation

### What Works
* All panel drop shadows (`dashBg`, `launcherBg`, `utilsBg`, `clipboardBg`, `sessionBg`, `sidebarBg`, `osdBg`) are gated to activate strictly when panels reach resting state (`offsetScale < 0.05`).
* Panel shadows include smooth opacity transitions (`Behavior on opacity { Anim {} }`), smoothly fading in when the drawer lands and instantly fading out when closing starts, eliminating any moving blurred shadows or silhouettes behind sliding panels.
* Compositor layer rules in `80-layer-rules.kdl` explicitly enforce `background-effect { blur false; }` for `nilastia-drawers` and third-party namespaces when `layer_blur_enabled` is disabled, preventing Niri from defaulting to protocol-level blur requests.
* `BackgroundEffect.blurRegion` is permanently bound to `blurRegionRef` with its offscreen 1x1 anchor (`[-100, -100, 1, 1]`), ensuring Quickshell never sends `set_blur_region(nullptr)` (which prompts Niri to fall back to fullscreen blur).
* When `layer_blur_enabled` is `false` or during drawer motion (`offsetScale >= 0.05`), all panel blur subregions evaluate to `0` width and `0` height, completely eliminating Wayland IPC damage flooding and preventing static blur boxes from appearing ahead of moving drawers.

### How to Test / Run
```bash
# 1. Turn off shell blur in Nexus or check shell.json:
jq .general.battery.preferredLayerBlur ~/.config/nilastia/shell.json
# Should return false

# 2. Verify Niri layer rules contain explicit blur false:
grep -A 5 "nilastia-drawers" ~/.config/niri/config.d/80-layer-rules.kdl

# 3. Toggle utilities drawer and capture screenshot mid-transition:
quickshell -c niri-nilastia-shell ipc call drawers toggle utilities && sleep 0.15 && grim /tmp/test_utils_slide.png && sleep 0.5 && quickshell -c niri-nilastia-shell ipc call drawers toggle utilities

# 4. Inspect /tmp/test_utils_slide.png: verify the sliding panel has a clean edge with zero shadow silhouette or blurred rectangle dragging behind it
```


