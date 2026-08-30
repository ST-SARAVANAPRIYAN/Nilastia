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
