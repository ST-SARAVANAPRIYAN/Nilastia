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
    *   *Audio Sync & Devices:* Fully featured configuration page matching Tauri options: includes an Overall Master switch, playback target devices selector (destination only vs both), fine-tuning sync delay offset slider (-30ms to +30ms), and a dedicated Start/Stop Syncing button. Displays a pairing QR Code containing auto-detected host connection details. Features robust mutual exclusion that automatically turns off Wi-Fi streaming when an active call is connected to avoid RF/routing conflict. Fixed the dropdown menus (SelectRow) not displaying/rendering by rewriting the Menu parent-window binding using safe vanilla JavaScript instead of TypeScript-style casts.

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



