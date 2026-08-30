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
1. **Minimum Dimensions (1x1 Pixel):**
   * The inhibitor's window must be configured with a minimum mapped size of at least `width: 1` and `height: 1`.
2. **Input Mask & Transparency:**
   * To keep the window completely invisible and click-through, set `color: "transparent"` and specify `mask: Region {}` to discard all input events on the 1x1 area, preventing it from hijacking clicks or rendering a visible pixel.
3. **Layer Shell Settings:**
   * Configure `WlrLayershell.layer: WlrLayershell.Background`, `WlrLayershell.keyboardFocus: WlrLayershell.None`, and `exclusionMode: PanelWindow.None` to keep the 1x1 surface on the lowest possible layer and prevent the compositor from grabbing focus or locking out input/gestures on desktop elements like the clock.

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


