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
*   **Triggering & Overlay Activation:** Pressing **`Super+S`** (`Mod+S` in Niri) triggers `quickshell -c niri-nilastia-shell ipc call circletosearch open`. Instantly captures screen snapshot via `grim`, displays fullscreen overlay on `WlrLayer.Overlay` with `WlrKeyboardFocus.Exclusive`, and starts asynchronous background OCR.
*   **Google Lens Quad-Palette Shimmer:** Real-time Vulkan/GLSL fragment shader (`shaders/iridescent.qsb`) runs along screen perimeter edges interpolating the Google Lens 4-color palette (`#4285F4`, `#EA4335`, `#FBBC05`, `#34A853`) with a soft atmospheric glow.
*   **Intelligent Gesture Differentiation:**
    *   **Circle / Loop Gesture:** Drawing a closed loop around any visual region (`isLoop`) immediately launches Google Lens search on the selected area without needing extra menu button taps.
    *   **Line Swipe Text Selection:** Drawing a stroke across text words invokes `selectWordsIntersectingStroke(pts)`, selecting all intersected words and showing Android teardrop draggable handles at start and end.
    *   **Single-Tap Word Selection:** Tapping a word selects it and displays start/end teardrop handles.
    *   **Interactive Teardrop Drag Handles:** Dragging the teardrop handles smoothly expands or contracts the text selection range in real time.
    *   **Freeform Region Selection:** Drawing arbitrary shapes over images or empty space frames the selection with `SelectionBox.qml`.
*   **Browser-Native Form POST Google Lens Integration:**
    *   Generates an auto-submitting local HTML launcher (`/tmp/cts-lens.html`) embedding the cropped selection as base64 and populating a form with `DataTransfer` targeting `https://lens.google.com/upload?ep=subb&hl=en`.
    *   Launches Brave with `--app=file:///tmp/cts-lens.html`, executing the POST within the browser's own session and cookies.
    *   Completely eliminates Google's bot detection, session mismatches, and the permanent "Expired visual search" / infinite skeleton loading screens.
    *   Stages selection crops automatically to the system clipboard (`wl-copy --type image/png`).
*   **Docked & Resizable Niri Window Rules:**
    *   Niri window rule (`match app-id=r#"^brave-.*(google\.com|cts-lens).*"#`) docks the window to the top-right corner (`x=24, y=54, width=480, height=980`) with `min-width 360` and `max-width 1200`.
    *   Freely resizable via `Mod + Right Click Drag` or `Mod + Minus / Equal` (`set-column-width`).
*   **Multilingual Deep-Learning OCR Engine (13 Languages):**
    *   Configured user-space `TESSDATA_PREFIX=~/.local/share/tessdata` with fast integer-quantized LSTM models (`tessdata_fast`): English, Japanese, Tamil, Hindi, Spanish, French, German, Simplified Chinese, Korean, Russian, Arabic, Italian, and Portuguese.
    *   Runs simultaneous multi-script detection (`-l eng+spa+fra+deu+jpn+tam+hin+chi_sim+kor+rus+ara+ita`) with zero root/sudo requirements, recognizing Latin, CJK, Devanagari, and Dravidian scripts in milliseconds.
*   **Enhanced Live In-Place Translation:**
    *   `backend/translate.py` performs line deduplication and non-alphanumeric noise filtering.
    *   `LiveTranslateOverlay.qml` enforces bounded text wrapping (`targetW: Math.max(modelData.w + 16, Math.min(transText.implicitWidth + 36, 420))`), avoiding circular sizing loops, with clean vertical centering and hover-to-copy interactions.
*   **Material 3 Floating Action Menu:**
    *   Presents `Copy`, `Web Search`, `Translate`, and `Google Lens` actions using Material Design tokens and `MaterialIcon` symbols with zero emojis.
*   **Live Translation with Dynamic Language Selector:**
    *   Clicking `Live Translate` on the bottom bar displays floating frosted-glass cards directly over each original text line on screen.
    *   Language selector pill `[Auto-detect] -> [Target Language ▾]` opens an M3 popup menu with popular languages (English, Spanish, French, German, Tamil, Hindi, Japanese, etc.), updating translations dynamically on selection.
*   **Quick Dismissal:** Pressing `Escape` or clicking Close instantly dismisses overlay and restores desktop focus.

### How to Test / Run
```bash
# 1. Trigger via keyboard shortcut:
# Press Super+S

# 2. Or trigger via IPC:
quickshell -c niri-nilastia-shell ipc call circletosearch open

# 3. Direct Circle to Lens test:
# - Draw a closed circle or loop around any image or area on screen
# - The overlay immediately closes and Brave opens docked to the right edge with active Google Lens search results (no "Expired visual search" error)!
# - Resize the window freely by holding Mod and dragging with the Right Mouse Button, or pressing Mod+Minus / Mod+Equal.

# 4. Text selection & teardrop handle test:
# - Press Super+S
# - Swipe a line across words (or tap any word)
# - The text highlights and start/end Android teardrop handles appear
# - Drag either teardrop handle left or right to expand/contract selection
# - Click Copy in the floating action menu to copy to clipboard

# 5. Multilingual Live Translate test:
# - Open any page with foreign text (Japanese, Tamil, Hindi, Spanish, etc.)
# - Press Super+S
# - Click "Live Translate" on the bottom bar
# - Screen text is translated in-place into English (or your chosen target language)
# - Click the target language dropdown (e.g. "English ▾") and select another language
# - Translations refresh dynamically in the chosen target language!
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




