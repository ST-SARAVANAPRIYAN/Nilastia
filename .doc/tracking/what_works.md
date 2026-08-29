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
    *   Parallax Wallpapers (`.nilawall` / `.json`): A JSON layout structure holding multi-layered images (base64 data URIs or relative filenames).

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
