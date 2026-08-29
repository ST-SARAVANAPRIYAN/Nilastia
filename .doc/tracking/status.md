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
