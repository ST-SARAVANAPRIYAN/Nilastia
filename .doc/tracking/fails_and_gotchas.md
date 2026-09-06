# Nilastia Gotchas, Lessons Learned & Failures Log

This document lists critical technical constraints, lessons learned, and historic failures to prevent regression during future agent sessions.

---

## 🔒 SDDM Greeter Constraints (Qt5 vs. Qt6)

### The Issue
*   Even on systems with Qt6 installed, the system-level `sddm-greeter` process is often compiled and linked against **Qt5 libraries** (`libQt5Quick.so` and `libQt5Qml.so`).
*   This makes it incompatible with the desktop shell's native Qt6 code.

### Critical Constraints
1.  **Strict Import Suffixes:**
    *   Do **NOT** use versionless imports (e.g., `import QtQuick`) in SDDM QML layouts. The Qt5 parser will fail with `Library import requires a version`.
    *   Use explicit versions instead:
        ```qml
        import QtQuick 2.15
        import QtQuick.Layouts 1.15
        import QtGraphicalEffects 1.15
        ```
2.  **Required Packages:**
    *   Since Qt5 does not have `QtQuick.Effects` (which was introduced in Qt6), layouts must fall back to using `QtGraphicalEffects`. This requires `qt5-graphicaleffects` to be installed on the host system.

---

## 📂 System User Permissions & Assets

### The Issue
*   The login manager (`sddm` user) runs in a separate system context before any user session is logged in.
*   Because user home directory paths (e.g. `/home/saravana/`) typically have restrictive permissions (`700` or `750`), the `sddm` user **cannot read any files** inside your home folder.

### Critical Constraints
*   Any image used for the SDDM theme background or profile face card **must be copied** to a public, world-readable folder (like `/usr/share/sddm/themes/nilastia/assets/`) and given `644` permissions.
*   Directly referencing user paths (like `~/.face` or local wallpapers in `/home/saravana/Pictures/`) will fail to render, causing a blank grey screen.

---

## 🖼️ Base64 Parallax Wallpapers (`.nilawall`)

### The Issue
*   Dynamic wallpapers in Nilastia can be formatted as `.nilawall` configurations. These are JSON files containing multiple image layers encoded directly as Base64 data strings.
*   Passing this JSON file or a raw base64 data stream directly to standard image widgets without decoding results in image rendering failures.

### Critical Constraints
*   To render dynamic wallpapers on a static lockscreen/login background, the script must parse the JSON config, locate the first image layer (`layers[0].source`), decode its Base64 byte array, and save the resulting file directly as a static image (PNG/JPEG) in the assets directory.

---

## 🔗 QML Bound Components Delegate Scoping

### The Issue
*   When using `pragma ComponentBehavior: Bound` in a QML file, the delegate items instantiated inside a `Repeater` or `ListView` cannot implicitly resolve context variables (like `modelData` or `index`) inside their root item property bindings or sub-components (such as `Loader` components).
*   This triggers `ReferenceError: modelData is not defined` or `ReferenceError: settingsObj is not defined`.

### Critical Constraints
1.  **Required Property Declarations:**
    *   Any delegate using `ComponentBehavior: Bound` **must** explicitly declare the context properties as `required` properties on its root item:
        ```qml
        required property string modelData
        required property int index
        ```
2.  **Explicit Loader Scoping Injection:**
    *   Sub-components loaded dynamically via `Loader` inside the delegate scope do not inherit the delegate's local property bindings. They must have matching target properties declared on their root components, and the `Loader`'s `onLoaded` signal handler must explicitly map/inject the properties to prevent `ReferenceError` crashes:
        ```qml
        onLoaded: {
            if (item) {
                if (item.hasOwnProperty("settingsObj")) item.settingsObj = settingsObj;
            }
        }
        ```

---

## 🎨 SDF Bleeding & Offscreen Panel Rendering

### The Issue
*   When panels (such as the Dashboard and Utilities) are closed, they sit just 5px offscreen (e.g. `y = -405` or `y = screen.height + 5`).
*   Because the custom C++ shader uses a smooth minimum (`smin`) blend radius (typically 12–24px) to round panel corners, offscreen shapes within the blend radius can bleed into the screen border frame (`BlobInvertedRect`), warping or drawing a thin line/strip artifact at the top and bottom of the screen.

### Critical Constraints
1.  **QML PanelBg Visibility Binding:**
    *   All window panel shapes (`PanelBg` components) must explicitly bind their visibility to their target panel's active state to prevent offscreen rendering:
        ```qml
        visible: panel ? (panel.visible && panel.opacity > 0) : false
        ```
2.  **C++ Shape Tracker Visibility Filters:**
    *   The C++ `BlobShape` tracker loop (in `blobshape.cpp`) must explicitly check and skip shapes that are not visible or fully transparent (`!other->isVisible() || other->opacity() <= 0.0`) to avoid passing their geometry/SDF fields to the fragment shader.

---

## 🎨 SDF Multi-Pass Boundary Double-Drawing Seam

### The Issue
* When a panel (like the Dashboard or Utilities) is open, both its own local shader pass (`PanelBg`) and the fullscreen border shader pass (`BlobInvertedRect`) evaluate the same boundary pixels where `mergedSdf` is near `0.0`.
* In multi-pass SDF rendering, to prevent gaps due to floating-point precision, the discard condition allows a tiny overlap (typically `fw * 1.5` pixels) where both shapes are drawn.
* However, because the screen frame border (`BlobInvertedRect`) is fullscreen and does not share a visual boundary with a panel in the middle of the screen (e.g. left edge of the utilities card at `x = width - 430`), allowing this overlap causes the border shader to double-draw the panel's outer boundaries in `root.surfaceColour`.
* Since the desktop shell draws transparent backgrounds that blend with the wallpaper, double-drawing these boundary pixels yields a higher opacity, manifesting as a thin 1px vertical or horizontal line/strip artifact matching the panel's edges.

### Critical Constraints
1. **Distance-Based Discard Check (`mySdf > smoothFactor`):**
   * Before checking the shared boundary overlap condition, the shader must evaluate its own local SDF (`mySdf` which is `dFrame` for the frame or `dArr[myIndex]` for other shapes).
   * If a renderer's own distance is greater than the blend radius (`smoothFactor`), it is completely outside the shape and does not contribute to the blend. It must be discarded immediately to prevent double-drawing other shapes' boundaries:
     ```glsl
     float mySdf = (myIndex == -1) ? dFrame : dArr[myIndex];
     if (mySdf > smoothFactor)
         discard;
     ```

---

## 📶 Wi-Fi & Bluetooth Audio Coexistence & PipeWire Hijacks

### The Issue
* Wi-Fi and Bluetooth share the same 2.4 GHz physical antenna on many wireless cards. High-bandwidth audio streaming over Wi-Fi (Wi-Fi Speaker) conflicts directly with Bluetooth telephony call routing (RFCOMM SCO/HFP profile).
* When a phone call is routed, PipeWire/PulseAudio automatically overrides the system default audio sink to direct voice streams to the Bluetooth headset profile. If the Wi-Fi speaker is active, the race condition crashes/freezes the daemon's audio capture loop (`pactl` / `parec` commands).

### Critical Constraints
1. **Dynamic Active Call Exclusion:**
   * In `PlatypusLink.qml`, the background event stream listener must intercept active call state transitions (events other than `Disconnected` or null) and automatically set `wifi_speaker_active` to `false` in the daemon's audio configuration. This terminates loopbacks and captures before the Bluetooth voice profile starts.
2. **QML Parent Layout `enabled` Bindings:**
   * Avoid setting `enabled: win.audioSyncEnabled` on a parent layout container wrapping custom dropdown/menu rows (like `SelectRow` or `SliderRow`). Toggle-disabling a parent layout recursively mutates the event grab state of its children, which instantly closes active drop-down popup overlays. Assign the `enabled` properties to individual settings rows instead.

---

## 🔊 Dynamic Audio Stream Migration Loop & Numeric Sink IDs

### The Issue
* When Wi-Fi audio sync starts, WirePlumber/PipeWire may hijack newly started user-space application audio streams and route them to your hardware speakers (remembered preference) rather than the default `wifi_speaker` sink.
* Spawning a naive background monitoring thread to constantly migrate streams back to `"wifi_speaker"` can easily trigger an infinite CPU/pactl loop. `pactl list short sink-inputs` outputs the **numeric sink ID** (e.g. `280`) in the second column rather than the friendly sink name (`wifi_speaker`), so comparing `current_sink_str != "wifi_speaker"` will always evaluate to `true`, repeatedly firing `pactl move-sink-input` every cycle, flooding logs and freezing the compositor.

### Critical Constraints
1. **Dynamic Numeric ID Lookups:**
   * In the background monitoring thread (`wifi_speaker.rs`), query `pactl list short sinks` at each step to dynamically map the name `"wifi_speaker"` to its current numeric sink ID.
2. **Strict Exclusions:**
   * Prevent moving streams if the current target matches the numeric sink ID, `"wifi_speaker"`, or contains `"wifi_speaker"`.
   * Only migrate streams with a valid Client ID (checking that column 3 is not `"-"` to avoid capturing internal helper loopbacks).

---

## ☕ Wayland Idle Inhibitor Mapping Constraints

### The Issue
* Under Wayland (via `idle_inhibit_unstable_v1` protocol), the compositor only respects idle inhibitor requests if the associated surface/window is mapped and visible on an output.
* If a helper service window (like the one used for the `IdleInhibitor` in `IdleInhibitor.qml`) specifies size dimensions of `0x0` (`implicitWidth: 0`, `implicitHeight: 0`), the compositor decides that the surface has no visual layout and skips mapping it. As a result, the inhibitor remains completely inactive, and the screen continues to sleep/lock normally.

### Critical Constraints
1. **Direct In-Process Binding in `IdleMonitors.qml`:**
   * Quickshell's internal `IdleMonitor` instances listen directly to Wayland idle timer events. To ensure that "Keep Awake" prevents all timeouts reliably regardless of compositor protocol support, `IdleMonitors.qml` must explicitly check `if (IdleInhibitor.enabled) return false;` in its `root.enabled` property and `handleIdleAction` handler.
2. **System-Level Inhibit with `systemd-inhibit`:**
   * In `IdleInhibitor.qml`, spawn a background `systemd-inhibit` process (`--what=idle:sleep:handle-lid-switch`) while enabled so that systemd-logind will not suspend/sleep the hardware independently of the shell.
3. **Minimum Surface Dimensions (1x1 Pixel):**
   * The inhibitor's window must be configured with a minimum mapped size of at least `width: 1` and `height: 1`.
4. **Input Mask & Transparency:**
   * To keep the window completely invisible and click-through, set `color: "transparent"` and specify `mask: Region {}` to discard all input events on the 1x1 area, preventing it from hijacking clicks or rendering a visible pixel.
5. **Layer Shell Settings:**
   * Configure `WlrLayershell.layer: WlrLayershell.Background`, `WlrLayershell.keyboardFocus: WlrLayershell.None`, and `exclusionMode: PanelWindow.None` to keep the 1x1 surface on the lowest possible layer.

---

## 🖼️ Wayland Background Layer Input Restrictions

### The Issue
* Under Wayland layer shell protocols, many compositors (like Niri) configure the `WlrLayer.Background` layer to be completely click-through/non-interactive by default.
* If interactive widgets (like `DesktopClock.qml` which has drag and resize handles) are rendered inside the wallpaper window (which sits on `WlrLayer.Background`), mouse click and drag events will never reach the widget's MouseAreas.

### Critical Constraints
* Render interactive desktop widgets exclusively on `WlrLayer.Bottom` (e.g. inside the main widgets window `win`). 
* If a widget needs to sync its 3D depth position with a parallax wallpaper, expose the wallpaper's active parallax offsets (`globalParallaxX`/`globalParallaxY`) to the root of `Wallpaper.qml` and apply a `Translate` transform to the widget loader in `Background.qml` using the wallpaper's layers config.

---

## 🪵 Linux Command-Line Size Limit (`E2BIG`) on Base64

### The Issue
* The Linux kernel enforces a strict size limit (`ARG_MAX`, typically 2MB) on the size of arguments and environment variables passed to `execve()`.
* If a custom wallpaper has multiple base64-encoded image layers, the resulting JSON string can be 9+ MB. Passing this JSON directly to the `--layers` argument of `wallpaper_builder.py` fails with an `E2BIG` (Argument list too long) error, preventing the builder process from starting and locking the UI at "Building...".

### Critical Constraints
* Avoid passing large base64 data strings in command-line arguments.
* In the editing/loading flows, use a python subprocess (`wallpaper_builder.py --unpack <file.nilawall>`) to parse the JSON and write decoded base64 streams directly to small temporary local files (in `/tmp/`). Pass only the local file paths back to QML and command arguments.

---

## 📂 QML URL Prefix (`file://`) and Python Paths

### The Issue
* When resolving paths in QML using standard URL values (like `Wallpapers.actualCurrent`), they are prefixed with `file://`.
* Passing a path starting with `file://` to Python's `pathlib.Path` results in it treating the string as a relative path containing `file://` characters. Consequently, `.is_file()` returns `False` and operations fail.

### Critical Constraints
* Always strip the `file://` prefix using `Paths.toLocalFile(url)` in QML before passing file paths to subprocesses.

---

## ⚡ QML Fullscreen Blur Performance & Thread Exhaustion

### The Issue
* Applying a full-resolution shader effect (like `MultiEffect`) to full-screen windows (like backgrounds and lockscreens) causes the GPU to run heavy Gaussian/fragment shaders over millions of pixels on every frame when things move. This causes a massive framerate drop (e.g. down to 40Hz) and drains laptop batteries.
* Similarly, having a `FrameAnimation` component run continuously inside persistent windows (like `Background.qml` to track FPS) prevents the Qt Quick Scene Graph from ever going to sleep, locking CPU threads at 100% and spamming syslog with console outputs.

### Critical Constraints
1. **Always Downscale Fullscreen Blurs:**
   * Configure the target `layer` properties to downscale the texture before rendering the blur shader:
     ```qml
     layer.enabled: true
     layer.textureSize: Qt.size(width / 4, height / 4) // 4x downscaling
     layer.smooth: true // bilinear filtering for smooth upscaling
     ```
2. **Never Run Continuous Frame Loops:**
   * Do not keep active `FrameAnimation` or short-interval repeating timers running in global desktop components. If dynamic FPS counting or animations are needed, bind them strictly to user interaction triggers or layout visibility checks to let the renderer sleep when the screen is static.

---

## 📶 Circular Bluetooth Profile Deadlock (HFP/HSP)

### The Issue
* When there is no active call, the daemon sets the Bluetooth card profile to `off` to prevent phone media from hijacking system audio.
* Under PipeWire, setting a Bluetooth card profile to `off` tears down the profile-level Bluetooth connection completely.
* The Android OS detects this profile disconnect and sends `UpdateBluetoothStatus` with `is_connected=false`.
* If the daemon deletes/clears the cached phone MAC address on `is_connected=false`, it will have `None` stored when an incoming call starts. Consequently, the daemon cannot switch the card profile back to headset HFP, and call routing fails.

### Critical Constraints
1. **Never Clear MAC Address on Transient Disconnects:**
   * Do NOT clear the cached phone MAC address in the WebSocket handler when `is_connected` is `false` if the MAC is still provided in the payload. The daemon must retain it so it knows which bluetooth card to switch back on when a call occurs.
2. **Setup Call Loops on Connected State Too:**
   * Trigger call audio routing setup on both `Ringing` and `Connected` states to handle outgoing calls placed directly from the phone or to handle rapid state updates.

---

## 📶 BlueZ / Kernel `PowerState: off-blocked` Deadlock

### The Issue
* When Bluetooth is powered off via BlueZ / D-Bus or Blueman, the Linux kernel and BlueZ transition the adapter (`hci0`) into `PowerState: off-blocked` (which sets soft block on rfkill).
* In this `off-blocked` state, executing `bluetoothctl power on` or setting `adapter.enabled = true` via D-Bus fails with `org.bluez.Error.Failed` because the kernel rfkill radio is blocked.
* Conversely, calling only `rfkill unblock bluetooth` unblocks the physical radio, but does NOT power on the BlueZ adapter unless `bluetoothctl power on` or D-Bus power is issued.
* If a UI switch executes only one of these actions, the state snaps back to disabled or fails silently.

### Critical Constraints
1. **Always Synchronize `rfkill` with `bluetoothctl`:**
   * Powering ON must execute: `rfkill unblock bluetooth && bluetoothctl power on`
   * Powering OFF must execute: `bluetoothctl power off && rfkill block bluetooth`
2. **Accurate State Detection:**
   * Check both `rfkill list bluetooth` (for soft block) and `bluetoothctl show` (for `Powered: yes`) to determine true power state.

---

## 🪟 QML Window Resolution & Parenting in Quickshell (`item.window` Gotcha)

### The Issue
* Standard QtQuick `Item` objects **do not have a `.window` property**. Attempting to write `item.window` in JavaScript returns `undefined`.
* In Quickshell, `QsWindow.window` or attached properties like `Window.window` can evaluate to `null` on dynamically created windows (such as `FloatingWindow` created for standalone Nexus panels).
* If a popup menu (like `Menu.qml` or `PopupRow.qml`) attempts `parent: { const win = item ? item.window : null; return win.interactionWrapper ? win.interactionWrapper : win.contentItem; }`, `win` is always `null`.
* As a result, `parent` evaluates to `null`. The menu becomes completely unparented, resulting in a 0x0 size item that never displays on screen when clicked.

### Critical Constraints
1. **Always Traverse Ancestor Items (`p.parent`):**
   * To find the window's root item for overlay menus or popups, traverse up using `while (p.parent) p = p.parent;`.
   * This is guaranteed to resolve the top-most root visual item (`ProxyWindowContentItem` / `contentItem`) across both `ContentWindow` and `FloatingWindow`.
2. **Check for Interaction Wrapper along the Chain:**
   * If an ancestor has `objectName === "interactionWrapper"` or `.interactionWrapper`, attach to it so hover/gestures in drawers function seamlessly. If none is found, attach directly to the top item.

---

## 📡 NetworkManager Hotspot (AP) vs. Station (Client) Mode Collisions

### The Issue
* When NetworkManager brings up a Wi-Fi Access Point (Hotspot) on an adapter (e.g. `wlan0`), `nmcli device wifi list` scans all visible SSIDs and flags the local Hotspot AP as `ACTIVE=yes` because its SSID matches the active connection profile on `wlan0`.
* NetworkManager commands do not distinguish whether the active Wi-Fi profile is an incoming station connection or an outgoing hosted AP.
* If a Wi-Fi client manager (like `Nmcli.qml`) parses `ACTIVE=yes` without checking connection mode, it reports the hosted AP as the active Wi-Fi network, causing the desktop to falsely claim it is "connected to its own hotspot".
* Furthermore, on a single-PHY wireless card, initiating AP mode on `wlan0` forces NetworkManager to tear down any existing station connection to the user's home Wi-Fi. Stopping the hotspot leaves the interface disconnected unless an explicit reconnection command (`nmcli con up id "$PREV_WIFI"`) is issued.

### Critical Constraints
1. **Always Filter Local AP from Client Scans:**
   * In `Nmcli.qml`, exclude `Hotspot.ssid` and `Hotspot.activeProfile` from `networks` and `parseNetworkOutput`.
   * In `refreshStatus`, ignore connections matching `Hotspot` or `Hotspot.ssid` when checking `isConnectedState`.
2. **Preserve & Aggressively Restore Previous Wi-Fi:**
   * Capture the active Wi-Fi connection profile in QML state before invoking AP activation.
   * On shutdown, execute `nmcli con up id "$PREV_WIFI"` and fire an immediate rescan timer (1.2s) so the shell reconnects to home Wi-Fi without manual intervention.

---

## 📄 QML Single-Item Default Property Overwrite (`PageBase.contentChild` Gotcha)

### The Issue
* `PageBase` defines a single-item default property: `default property Item contentChild`.
* If a page component declares more than one top-level visual Item under `PageBase` (for example, declaring both the main UI `ColumnLayout` and an overlay dialog `Rectangle { id: savePromptOverlay ... }`), QML assigns the items sequentially to `contentChild`.
* The last declared Item overwrites `contentChild`, completely unparenting/orphaning the preceding items (e.g. `ColumnLayout.parent` becomes `null`).
* Because the orphaned layout has no parent, bindings like `anchors.top: parent.top` throw `TypeError: Cannot read property 'top' of null`.
* Furthermore, if the second item is an invisible overlay (`visible: false`), the `VerticalFadeFlickable` in `PageBase` receives zero implicit height and empty content, resulting in a completely blank page.

### Critical Constraints
1. **Single Direct Visual Child in `PageBase`:**
   * A `PageBase` component must only contain **one** direct visual root item (typically a `ColumnLayout` or `GridLayout`).
2. **Move Modals, Dialogs, and Components to `resources`:**
   * Any full-page overlay dialogs, prompt rectangles, or `Component` definitions must be placed in `resources: [ ... ]`.
   * For overlay items that must render visually over the whole page, specify `parent: root`, `anchors.fill: parent`, and `z: 9999` inside `resources`. Items in `resources` are excluded from default property assignment, preserving the main layout as the true `contentChild`.

---

## 🖼️ Desktop Parallax Viewport & Window Deactivation Traps

### The Issue
1. **Viewport Resolution Scale Discrepancy:**
   * A fixed pixel displacement (e.g. 35px) appears 3.5× to 7× larger in a small preview box (~560px) than across a 1080p or 4K desktop monitor.
   * If preview translations do not downscale proportionally with the preview container (`dispX * (parent.width / 1920)`), presets that appear lively in the builder become nearly imperceptible on the actual desktop.
2. **Aggressive Windowed Deactivation (`Hypr.anyWindowVisible`):**
   * Setting `targetIntensity: Hypr.anyWindowVisible ? 0.0 : root.intensity` shuts down parallax motion completely whenever *any* client window is open on the workspace (even small tiled or floating windows that only cover a fraction of the screen).
3. **Linear Center Dead-Zones on Large Screens:**
   * Linear mouse coordinate normalization `(mouse.x - cx) / cx` on 1920px+ monitors requires dragging the mouse across 960 physical pixels to reach edge displacement. Subtle everyday mouse movement in the center third generates only 10–20% of max displacement, dropping shifts below visual thresholds.

### Critical Constraints
1. **Preserve Windowed Parallax:**
   * Only drop intensity to `0.0` when windows are truly fullscreen (`root.wallpaperCovered`). Retain at least 60–70% intensity during normal windowed multitasking.
2. **Apply Center-Boosted Response Curves:**
   * Calculate mouse input using non-linear curves (`Math.sign(tx) * Math.pow(Math.abs(tx), 0.7)`) to ensure natural cursor motion in the center of the display generates lively, responsive depth.
3. **Scaled Preview WYSIWYG:**
   * Scale preview displacement by `(previewWidth / 1920.0)` so that visual percentages in the builder precisely match real desktop movement.

---

## ⛅ Dashboard Card Text Overflows & Missing Boundary Clipping

### The Issue
* In `SmallWeather.qml`, concatenating primary values and dynamic metadata into a single string (`Weather.temp + " (" + Weather.city + ")"`) using a large headline font (`Tokens.font.headline.builders.medium.width(110).weight(Font.DemiBold).build()`) without specifying `width` or `elide: Text.ElideRight` caused text to extend beyond the 275px card container.
* Because the container `Rect` in `Dash.qml` did not have `clip: true`, the overflowing text painted on top of neighboring grid items (e.g. overlapping the User card).

### Critical Constraints
1. **Separate Value and Metadata into Vertical Rows:**
   * Do not concatenate primary metrics and location strings into a single large headline. Keep the headline focused on the metric (`37°C`) and place metadata (`Karur • Overcast`) on a secondary row.
2. **Always Enforce Width & Elide on Dynamic Strings:**
   * Dynamic text (such as user-configured cities, media titles, or system strings) must always have an explicit `width: Math.min(implicitWidth, maxAvailableWidth)` and `elide: Text.ElideRight`.
3. **Set `clip: true` on Grid Container Tiles:**
   * Dashboard tiles in `GridLayout` must declare `clip: true` to prevent rendering artifacts from breaching tile bounds into adjacent columns or rows.

---

## 🎧 Bluetooth Headset/Earbud Hijacking vs. Phone Audio Gateway

### The Issue
* Bluetooth audio listening devices (like CMF Buds, AirPods, or wireless headphones) register under PipeWire as `bluez_card` with `device.form_factor = "headset"`.
* When implementing Bluetooth call gateway routing, falling back to matching an arbitrary `bluez_card` when no phone MAC is provided causes the daemon to latch onto the user's personal headphones rather than their mobile phone.
* Consequently, setting the profile to `off` during call cleanup tears down the headphones audio sink (`a2dp-sink`), muting the user's desktop audio entirely.

### Critical Constraints
1. **Explicitly Filter Out Audio Headsets & Earbuds:**
   * Any Bluetooth card lookup for phone calls must explicitly inspect `device.form_factor`, `api.bluez5.icon`, `device.icon_name`, and `device.description`.
   * Cards containing `"headset"`, `"headphone"`, `"earbud"`, `"buds"`, or `"airpod"` must be protected and never returned as the target phone gateway card.
2. **Never Touch Audio Devices Without Phone MAC Confirmation:**
   * If the phone MAC address is not provided or confirmed, do not attempt to toggle card profiles.
3. **Preserve Listening Devices as `@DEFAULT_SINK@`:**
   * The user's headphones function as the system's default audio sink (`@DEFAULT_SINK@`). Leaving them untouched allows call audio loopbacks (`source=phone, sink=@DEFAULT_SINK@`) to naturally route phone conversation directly through their headphones.

---

## 🧩 Nilastia Duplicate Plugin ID Conflict

### The Issue
* `Plugins::rescan` scans all subdirectories under `~/.local/share/nilastia/plugins/`.
* If a directory or symlink (e.g. `saravana.platypuslink` pointing to `saravana.platypus`) shares the exact same plugin ID (`saravana/platypus`) with another directory in the root, Nilastia treats it as a duplicate plugin conflict.
* As a result, Nilastia moves both manifests to `m_conflictingPlugins` and fails to load either of them.

### Critical Constraints
* Do not leave symlinks or copies with identical plugin IDs in the `~/.local/share/nilastia/plugins/` directory. Each folder in the plugins search root must have a unique ID.

---

## ⚙️ Quickshell `Process` Stopping Syntax (`running = false` vs `.terminate()`)

### The Issue
* In Quickshell QML, the `Process` item is a declarative property wrapper around a sub-process. It does not provide a `.terminate()` or `.kill()` JavaScript method.
* Attempting to call `daemonProcess.terminate()` throws `TypeError: Property 'terminate' of object Process is not a function`.

### Critical Constraints
* To stop a running process in Quickshell, set `process.running = false`.

---

## ⚙️ Quickshell Sub-process Launcher Pipeline Gotcha (`exec cmd | tee`)

### The Issue
* In wrapper shell scripts launched by Quickshell `Process` items (such as `run_daemon.sh`), using a pipeline `exec "$DAEMON_BIN" "$@" 2>&1 | tee -a "$LOG_FILE"` executes the pipeline commands inside child subshells.
* The parent bash script process immediately finishes with exit code `0` as soon as the pipeline forks.
* Quickshell tracks the parent script PID and interprets its completion as daemon termination (`onExited: 0`), immediately triggering automatic relaunch timers (e.g. `interval: 5000`).
* If the launcher script contains startup cleanup logic (e.g., `killall -9 platypusd-core`), this induces an endless 5-second restart cycle: terminating the running daemon, respawning it, exiting the wrapper script, and restarting again.

### Critical Constraints
1. **Direct Process Replacement:**
   * Always invoke background services in launcher scripts using a direct, pipeline-free `exec "$DAEMON_BIN" "$@"`.
   * This guarantees that the spawned process directly replaces the shell wrapper, keeping the tracked PID alive in the foreground for the lifetime of the service.
2. **Stream Logs Declaratively via Quickshell:**
   * Capture `stdout` and `stderr` directly in QML using Quickshell's `SplitParser` and maintain an in-memory buffer (`daemonLogs`), writing to disk or clipboard on demand.

---

## 🧩 Plugin Clean Uninstallation & Persistent Sub-process Traps

### The Issue
* If a plugin declares background `Process` items (such as `client.js` or daemons with restart timers), killing the process via `pkill` in bash while the plugin is still enabled causes Quickshell to instantly respawn the process because the QML declarative component remains instantiated in memory.

### Critical Constraints
1. **Remove from Configuration First:**
   * Always remove the plugin ID from `~/.config/nilastia/plugins.json` (both `enabled` array and `settings` map) and remove the directory from `~/.local/share/nilastia/plugins/`.
   * This triggers the C++ plugin manager file watcher to unload the QML engine's scope and destroy its `Process` items before sending termination signals.
2. **Clean Background Processes:**
   * Issue `pkill -9` on any orphaned background daemons or Node helpers and remove corresponding `.desktop` launchers and temporary state files.

---

## 🎮 Hybrid Laptop Multi-GPU EGL & GBM Allocation Traps

### The Issue
* On hybrid laptops (e.g. Intel UHD iGPU + NVIDIA RTX dGPU), the internal laptop screen (`eDP-1`) is physically wired to the Intel GPU (`card1`).
* Setting `__EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json` restricts libglvnd to only NVIDIA's driver, which strips client extensions (`EGL_EXT_device_query`, `EGL_EXT_device_enumeration`) needed by Smithay/Niri to query DRM devices.
* Similarly, setting `GBM_BACKEND=nvidia-drm` globally forces the NVIDIA GBM backend on the Intel display adapter, which causes `gbm_create_device` on `/dev/dri/card1` to fail with `no allocator available for device`.
* Consequently, Niri fails to allocate a scanout buffer for the internal screen (`no output for new layer surface`), leaving the display stuck on the TTY console even while the compositor process runs.

### Critical Constraints
1. **Never Restrict libglvnd or Force GBM_BACKEND on Hybrid Systems:**
   * Let libglvnd and Mesa's dynamic GBM loader (`/usr/lib/gbm/dri_gbm.so` and `nvidia-drm_gbm.so`) discover and allocate devices automatically.
2. **Rely on Niri's Native `render-drm-device`:**
   * To direct rendering to the dGPU on hybrid systems, configure `debug { render-drm-device "/dev/dri/by-path/pci-0000:01:00.0-render"; }` in `config-gpu.kdl` without setting invasive global EGL/GBM environment variables.

---

## ⚡ Hybrid Laptop dGPU Performance State P8 & 16 FPS PCIe Throttle

### The Issue
* On hybrid laptops where the display panel (`eDP-1`) is wired to the integrated Intel GPU, rendering the desktop on the dedicated NVIDIA GPU requires DMA-buf frame transfers over the PCIe bus to the iGPU for display scanout.
* Because 2D desktop compositors do not trigger heavy 3D compute or CUDA workloads, NVIDIA PowerMizer leaves the GPU in its deepest low-power idle state: **P8** (Core Clock = **315 MHz**, Memory Clock = **405 MHz**, PCIe Link = **Gen 1.1 @ 2.5 GT/s**).
* At PCIe Gen 1.1 with 315 MHz core and 405 MHz memory, transferring a 1080p frame buffer across PCIe takes ~60 milliseconds.
* This caps maximum desktop refresh rate at exactly **16 FPS (~62.5ms frame time)**, causing severe input lag, cursor jitter, and libinput timer expiry errors (`scheduled expiry is in the past (-342ms)`).

### Critical Constraints
1. **Elevate Clocks Upon GPU Session Start:**
   * In `niri-session-gpu`, elevate minimum graphics and memory clocks before starting Niri:
     ```bash
     sudo -n nvidia-smi -pm 1
     sudo -n nvidia-smi -lgc 600,2100
     sudo -n nvidia-smi -lmc 5000,8001
     ```
   * This forces the PCIe bus into Gen 3/4, dropping frame transfer latency below 1ms and delivering a smooth, tear-free 144 FPS desktop.
2. **Always Restore Clocks on Exit:**
   * Execute `nvidia-smi -rgc`, `-rmc`, and `-pm 0` in an automated bash trap on session exit and at the start of `niri-session` so the dGPU cleanly powers down into D3cold low-power idle when not needed.

---

## 🖥️ Niri Output Mode Switching & Inotify Config Traps

### The Issue
* Modifying `config.kdl` on disk changes the configuration file, but Niri does not immediately re-apply output modes to active display connectors solely from inotify reloads unless an explicit runtime IPC command is sent.
* If a helper tool only writes to disk, display settings appear non-functional or frozen.
* Furthermore, laptops may dynamically enumerate the internal display connector as `eDP-1` or `eDP-2` depending on initialization order. If configuration blocks only define one connector name, switching to a session that probes the other connector drops the display back to fallback 60Hz.

### Critical Constraints
1. **Always Issue Runtime IPC Commands:**
   * When changing display configuration, immediately dispatch `niri msg output <name> mode <mode>`, `scale <scale>`, and `vrr on/off`.
2. **Keep Multi-eDP Blocks Synchronized:**
   * When persisting settings to `config.kdl` or `config-gpu.kdl`, ensure sibling connector definitions (`eDP-1` and `eDP-2`) are updated with identical mode and scale definitions.
3. **Decouple Settings UI from Power Monitors:**
   * Do not disable manual UI controls based on active battery profiles. If a user manually changes refresh rate in the display settings, automatically switch the adaptive profile off so the manual setting is preserved.

---

## 🪟 QML JS Array Models in Repeater vs. In-Place Slider Mutation (`layersListChanged` Gotcha)

### The Issue
* When a `Repeater` binds its `model` to a plain JavaScript Array property (e.g. `property var layersList: []`), any assignment or call to `layersListChanged()` signals to Qt Quick that the entire model has been replaced.
* Consequently, Qt Quick destroys all instantiated delegates and re-creates them from scratch.
* If a slider inside a delegate calls a helper function that fires `layersListChanged()` on every move or scroll event, the `StyledSlider` and its `MouseArea` are destroyed mid-drag, breaking user mouse grabs, flickering, disrupting page scroll offsets, and triggering continuous image reloads in the preview.
### Critical Constraints
1. **Represent Dynamically Mutated Items as `QtObject` Instances:**
   * Instantiate array elements as `QtObject` items (using a `Component` in `resources`).
   * Because `QtObject` properties (like `depth` and `sensitivity`) have standard QML NOTIFY signals (`depthChanged`), modifying `layersList[index].depth = newDepth` triggers reactive bindings and preview translations directly without calling `layersListChanged()`.
   * This keeps the `Repeater`'s model intact and completely prevents delegate recreation.
2. **Handle Mouse Wheel Events Locally:**
   * Wrap sliders in `CustomMouseArea` with an `onWheel` handler to absorb wheel inputs and apply fractional increments (`0.05`), preventing the parent flickable view from intercepting wheel events and jittering.

---

## 🖱️ Wayland `WlrLayer.Background` Non-Interactivity & Desktop Clock Dragging

### The Issue
* In Wayland Layer Shell protocol, surfaces registered on `WlrLayer.Background` cannot receive pointer/keyboard focus or mouse button events.
* If interactive desktop widgets (like `DesktopClock`) are rendered within `Wallpaper.qml` (which runs on `WlrLayer.Background`), mouse events are rejected by the compositor, completely preventing clicking, dragging, and resizing.

### Critical Constraints
1. **Host Interactive Widgets on `WlrLayer.Bottom`:**
   * Interactive elements must be hosted on `WlrLayer.Bottom` (e.g. `Background.qml`).
   * When parallax movement is active, apply parallax displacement using a `transform: Translate` matrix on `WlrLayer.Bottom` rather than instantiating non-interactive duplicate items on `WlrLayer.Background`.
2. **Default `lockPosition` to Unlocked:**
   * Default `lockPosition` in `Time.qml` to `false` so dragging works immediately without obscure settings digging. Provide direct hover and right-click toggle controls on the widget itself.

---

## 🖼️ High-Res Base64 Data URIs in `CachingImage` (Memory & Frame Drops)

### The Issue
* By default, `Image` in QML decodes base64 data URIs (`data:image/...;base64,...`) synchronously on the main thread if `asynchronous` is disabled for `data:` schemes.
* Omitting `sourceSize` on data URIs causes Qt to decode the raw image at 100% native resolution (e.g., 4K/8K bitmaps), causing massive GPU memory allocations (hundreds of megabytes) and texture fill bottlenecks on high-refresh rate displays.

### Critical Constraints
1. **Always Enforce `asynchronous: true` and `mipmap: true`:**
   * Never bypass background thread decoding for data URIs.
   * Enable `mipmap: true` so the GPU samples pre-filtered textures during parallax translation.
2. **Bound Decoded Raster Dimensions via `sourceSize`:**
   * Set `sourceSize: Qt.size(Math.ceil(width * 1.15 * dpr), Math.ceil(height * 1.15 * dpr))` across all image formats including data URIs, letting the decoder downsample images before uploading to VRAM.

---

## 🔍 `pgrep -f` in `/bin/sh -c` Shell Commands (Self-Matching Gotcha)

### The Issue
* Running `pgrep -f "pattern"` inside a `/bin/sh -c "..."` script matches the `/bin/sh -c` process itself because the process's command line string contains the pattern text.
* In background status probes (e.g. `Hotspot.qml`), this causes `pgrep -f "create_ap"` to evaluate to `0` (true) constantly, erroneously reporting that the daemon is active even when it is completely shut down, causing toggle state flapping and failure to turn off.

### Critical Constraints
1. **Use `pgrep -x` or Network Interface / File Checks:**
   * Match exact process executable names via `pgrep -x <binary>` rather than `-f`.
   * Cross-verify with interface state (e.g. `ip link show ap0`) or PID directory files rather than arbitrary command-line strings.
2. **Apply Optimistic UI Updates & Guard Busy States:**
   * Immediately flip UI toggle state on user interaction (`root.enabled = true/false`) and guard periodic polling callbacks (`if (root.busy) return;`) so async probe results do not prematurely overwrite active state changes.

---

## 🚫 QML `PageBase` Root Items Type Mismatch & Resource Scoping

### The Issue
* `PageBase` declares a `default property Item contentChild`.
* If non-visual QML objects (such as `Connections`, `Timer`, etc.) are declared directly as root children of `PageBase`, Qt's QML engine attempts to assign the `QObject` to the default `contentChild` property (which requires a `QQuickItem*`), causing a fatal startup error:
  `Cannot assign object of type "Connections" to property of type "QQuickItem*" as the former is neither the same as the latter nor a sub-class of it.`

### Critical Constraints
1. **Enclose Non-Visual Objects in `resources: [ ... ]`:**
   * Any non-visual object at the page root must be placed inside `resources: [ Connections { ... } ]`.
2. **Or Declare Inside the Page's Visual Container:**
   * Place non-visual objects as children of the visual container (`ColumnLayout`) which natively accepts `QObject` elements without overriding the page's root `contentChild`.

---

## 🛑 Quickshell `Process` Cancellation (`.running = false` vs `.kill()`)

### The Issue
* In Quickshell, `Quickshell.Io.Process` is a custom Qt C++ wrapper, not a Node.js ChildProcess or Qt QProcess instance.
* Calling `proc.kill()` raises `TypeError: Property 'kill' of object Process(...) is not a function`, terminating JavaScript execution immediately and aborting sequential commands.

### Critical Constraints
* To terminate or cancel a running Quickshell process, assign `proc.running = false`.
* Check process liveness with `if (proc.running) proc.running = false;`.

---

## 🔤 `IconButton` Property API (`font` vs `fontStyle`)

### The Issue
* `MaterialIcon` uses `fontStyle` for specifying icon typography tokens (e.g. `Tokens.font.icon.small`).
* In contrast, `IconButton` is a `ButtonBase` derivative which exposes `property alias font: label.font`.
* Assigning `fontStyle` to `IconButton` results in `Cannot assign to non-existent property "fontStyle"`.

### Critical Constraints
* Always use `font: Tokens.font.icon.small` when customizing an `IconButton`.

---

## 🖼️ Wayland Layer Shell Z-Ordering & Sandwiched Virtual Clock Depth

### The Issue
* Wayland layer shell protocol renders `WlrLayer.Bottom` strictly in front of `WlrLayer.Background`.
* If a parallax wallpaper defines a virtual clock layer in the middle of its layers (e.g. index 2 with foreground layers at index 3 and 4), rendering the clock on `WlrLayer.Bottom` (needed for pointer click/drag interactivity) while all wallpaper image layers are rendered inside `Wallpaper.qml` on `WlrLayer.Background` causes the clock to be drawn on top of all layers, completely breaking foreground occlusion.
* Furthermore, bundling `hasOpenWindows` directly into `wallpaperCovered: isFullscreen || hasOpenWindows` causes `wallpaperCovered` to become `true` whenever any window is open on the workspace, which in turn zeros out `targetIntensity` and hides `parallaxContainer`, completely freezing and killing parallax motion during normal windowed multitasking.

### Critical Constraints
1. **Split Layer Rendering Across Layer Shell Surfaces:**
   * Layers preceding `virtual://clock` (`index < clockLayerIndex`) must be rendered in `Wallpaper.qml` on `WlrLayer.Background`.
   * The interactive `DesktopClock` must be rendered on `WlrLayer.Bottom` in `Background.qml`.
   * Foreground layers succeeding the clock (`index > clockLayerIndex`) must be rendered on `WlrLayer.Bottom` directly above `DesktopClock` in `foregroundLayersContainer`.
2. **Set `enabled: false` on Foreground Layers:**
   * Overlay image layers on `WlrLayer.Bottom` must declare `enabled: false` so they remain completely click-through, ensuring mouse clicks and drag gestures reach `DesktopClock` beneath.
3. **Decouple `hasOpenWindows` from `wallpaperCovered`:**
   * Keep `wallpaperCovered` bound solely to `isFullscreen`.
   * Retain 65% depth motion during windowed multitasking (`targetIntensity: wallpaperCovered ? 0.0 : (hasOpenWindows ? intensity * 0.65 : intensity)`), reserving windowed pause exclusively for video/GIF wallpapers (`videoPaused`).

---

## 🧩 Nilastia Plugin Development & Qt QML Quirks

### 1. Symlinked Plugin Directories & `File name case mismatch`
* **The Issue:** When a plugin directory under `~/.local/share/nilastia/plugins/author.name` is a symlink pointing to another directory (such as `/home/saravana/projects/nilastia-plugin`), Qt's `QQmlTypeLoader` verifies path casing by comparing `QFileInfo(resolvedPath).canonicalFilePath()` to `resolvedPath`. Because `canonicalFilePath()` follows symlinks, the paths differ, causing Qt to fail loading custom component types with `File name case mismatch`.
* **Critical Constraint:** Never make the installed plugin directory a symlink. Use a real directory, or use hardlink cloning (`cp -al <source-repo> ~/.local/share/nilastia/plugins/<plugin>`) so files share identical inodes and live edits reflect immediately without triggering Qt's symlink canonical path mismatch.

### 2. Quickshell `Process` Stdio & Input
* **The Issue:** `Quickshell.Io` provides `StdioCollector` for stdout/stderr, but does not provide a `StdioWriter` type. Attempting to declare `stdin: StdioWriter {}` results in `StdioWriter is not a type`.
* **Critical Constraint:** For batch data passing, pass file arguments (e.g. `--batch-file /tmp/data.json`) or CLI argument strings rather than relying on stdin QML components.

### 3. `StyledWindow` Property Bindings
* **The Issue:** `StyledWindow` extends `PanelWindow` and does not expose an `active` property. Referencing `win.active` in child items (such as `Shortcut { enabled: win.active }`) assigns `undefined`, triggering `Unable to assign [undefined] to bool`.
* **Critical Constraint:** Bind `Shortcut.enabled` directly to the plugin's state property (e.g. `root.active`).

### 4. Google Lens "Expired Visual Search" & Bot Detection vs Browser-Native Form POST
* **The Issue:** Automated uploads to `https://lens.google.com/upload` or `/v3/upload` using Python `urllib.request` or `requests` generate server-side visual search requests (`vsrid` and `gsessionid`) that Google flags with anti-bot challenge or ties to ephemeral cookies (`NID`, `__Secure-STRP`). Even if `&lns_vfs=e` is stripped, when the redirected URL is subsequently launched in an external browser (Brave), the browser's separate session lacks the upload cookies. Google rejects the request, permanently displaying "Expired visual search" and freezing on skeleton loading ("Thinking a little longer").
* **Critical Constraint:** Never execute Google Lens image uploads from standalone Python subprocesses. Instead, generate an automated local HTML launcher (`/tmp/cts-lens.html`) embedding the selection image as base64, synthesize a `File` object via standard HTML5 `DataTransfer`, and auto-submit a hidden form targeting `https://lens.google.com/upload?ep=subb&hl=en`. Launch Brave pointing to `file:///tmp/cts-lens.html`. This forces the upload POST to originate directly from Brave's own network stack and origin, using the user's real browser profile cookies. Google Lens immediately returns valid visual matches without expiration errors.

### 5. `Tokens.font.icon` Token Availability
* **The Issue:** In Nilastia, `Tokens.font.icon` only defines `small`, `medium`, `large`, and `extraLarge`. Declaring non-existent tokens like `Tokens.font.icon.extraSmall` passes JS parsing at runtime but evaluates to `undefined`, causing QML property warnings (`Unable to assign [undefined] to QFont`).
* **Critical Constraint:** Always check `Tokens.font.icon` for valid sizes (`small`, `medium`, `large`, `extraLarge`) or use the builder syntax: `Tokens.font.icon.size(12).build()`.

### 6. Qt6 QML `Font` Weight Enums (`Font.DemiBold` vs `Font.SemiBold`)
* **The Issue:** In Qt6 QML `Font`, there is no `Font.SemiBold` enum; the enum is named `Font.DemiBold` (value 63). Using `Font.SemiBold` throws `Unable to assign [undefined] to int`.
* **Critical Constraint:** Always specify `font.weight: Font.DemiBold`.

### 7. QML Anchoring to Non-Parent / Non-Sibling Descendants
* **The Issue:** In Qt Quick, `Item.anchors` can only anchor to sibling items or the direct parent item. Attempting to anchor a popup (child of `root`) to an item deeply nested inside child layout rows (`RowLayout -> RowLayout -> targetLangBtn`) produces `Cannot anchor to an item that isn't a parent or sibling`.
* **Critical Constraint:** Anchor popups to their immediate parent or sibling, or map coordinates dynamically using `mapToItem()`.

### 8. Tesseract Multilingual OCR & User-Space `TESSDATA_PREFIX`
* **The Issue:** Default Tesseract installations on Linux only include English (`eng`), `osd`, and occasionally Spanish (`spa`). Invoking `tesseract` without `-l` defaults strictly to English, producing complete gibberish or empty text when attempting to read CJK (Japanese/Chinese), Indic (Tamil/Hindi), Cyrillic (Russian), or Arabic characters. Furthermore, installing system language packs via `pacman -S` requires root privileges (`sudo`).
* **Critical Constraint:** Do not require root privileges. Store language models in user-space at `~/.local/share/tessdata/` and configure `TESSDATA_PREFIX=~/.local/share/tessdata`. Use official `tessdata_fast` 8-bit quantized integer LSTM models (identical to modern Android on-device models), and invoke Tesseract with `-l eng+spa+fra+deu+jpn+tam+hin+chi_sim+kor+rus+ara+ita` for simultaneous script detection.

### 10. Tesseract CLI Options Order & Configfile Position
* **The Issue:** In Tesseract CLI syntax, options (`-l`, `--oem`, `--psm`) must strictly precede any output configfile (`tsv`). Passing `tsv` before `--oem` or `--psm` causes Tesseract to misparse arguments or treat flags as input files, resulting in silent syntax failures and 0 detected words.
* **Critical Constraint:** Always place `tsv` as the very last argument: `["tesseract", image_path, "stdout", "-l", lang_arg, "--oem", "1", "--psm", "3", "tsv"]`.

### 11. UEFI NVRAM Bootloader Aliasing (rEFInd Masquerade)
* **The Issue:** When rEFInd is installed alongside Windows, some installers create or rename the NVRAM entry to `"Windows Boot Manager"` (`\EFI\refind\refind_x64.efi`) to prevent aggressive UEFI firmware from bypassing Linux. In BIOS setup, this presents as two duplicate "Windows Boot Manager" entries with no visible CachyOS or GRUB entry.
* **Critical Constraint:** When registering direct Linux boot options into BIOS priority, run `grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=cachyos --recheck`. This creates a clean `Boot000X* cachyos` entry in UEFI NVRAM and sets it as the primary entry in `BootOrder`.

### 12. Browser-Agnostic Web App Windows & Floating Niri Side-Drawers
* **The Issue:** Hardcoding `brave` as the browser binary causes `FileNotFoundError` or silent failures on Linux installations where Brave is not installed (e.g. users running Chrome, Chromium, Firefox, Zen, Vivaldi, or minimal setups). Furthermore, Gecko/Firefox browsers do not support `--app=<URL>` (which strips URL bars and tabs to create a desktop app drawer), and WebKit2GTK standalone webviews trigger Google anti-bot verification and 403 Forbidden due to missing user profile cookies.
* **Critical Constraint:** Implement prioritized automatic browser resolution:
  1. Chromium-based browsers (`brave`, `google-chrome-stable`, `chromium`, `vivaldi`, `microsoft-edge`) support `--app=<URL> --window-size=640,980` for native floating drawer presentation.
  2. Gecko-based browsers (`zen-browser`, `firefox`, etc.) fallback to `--new-window <URL>`.
  3. Generic systems fallback to `xdg-open <URL>`.
  4. Systems with zero browsers must gracefully copy the image crop to the system clipboard via `wl-copy` and dispatch a desktop alert via `notify-send` without crashing.
  5. In Niri compositor rules, expand the `app-id` matching regex to cover all Chromium variants (`r#"^(brave|chrome|chromium|google-chrome|vivaldi|microsoft-edge|opera)-.*(google\.com|cts-lens).*"#`) so any installed Chromium browser automatically floats at 640px docked to the screen edge.




