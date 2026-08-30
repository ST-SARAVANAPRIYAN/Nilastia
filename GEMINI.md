# Nilastia Agent Guidelines & Rules

Welcome to the Nilastia pair-programming session! This repository contains the Nilastia desktop shell (rendered via Quickshell/Qt6), its Python CLI command utility (`nilastia`), and associated themes, configurations, and assets.

Since multiple agents work on this project across sessions, we maintain a **State & Tracking System** to prevent context loss, preserve working features, and avoid repeating past bugs.

---

## 🚨 Critical Agent Directives (Always On)

1. **Read Tracking Files First:**
   Before suggesting plans, changing code, or writing scripts, you **MUST** read the following tracking documents to understand the current state:
   - [.doc/tracking/status.md](file:///home/saravana/projects/calestia/nilastia/.doc/tracking/status.md): Active focus, component roadmap, and system state.
   - [.doc/tracking/what_works.md](file:///home/saravana/projects/calestia/nilastia/.doc/tracking/what_works.md): Detailed log of verified features and how to test them.
   - [.doc/tracking/fails_and_gotchas.md](file:///home/saravana/projects/calestia/nilastia/.doc/tracking/fails_and_gotchas.md): Critical runtime constraints, dependency quirks, and historical failures.

2. **Update the Tracking System:**
   Before completing a user task or wrapping up a session, you **MUST** update these tracking files:
   - Add new verified features or test commands to `what_works.md`.
   - Add newly discovered quirks, failures, or library constraints to `fails_and_gotchas.md`.
   - Update roadmaps and statuses in `status.md`.

3. **General Coding Guidelines:**
   - **Conciseness:** Keep reasoning and outputs direct, clean, and developer-oriented.
   - **Formatting:** Always create clickable links using `file://` scheme for modified files or key symbols (classes, functions, etc.).
   - **Git Management:** Stage all modifications cleanly. Do NOT commit or push changes unless explicitly asked by the user.

---

## 📁 Codebase Layout

*   `cli/`: Python code for the `nilastia` CLI tools, settings builders, and themes applying logic.
*   `modules/`: Quickshell QML modules (e.g., `lock/`, `nexus/`, `background/`, `windowinfo/`).
*   `services/`: Core logic modules and services (e.g., `Wallpapers.qml`, `Time.qml`).
*   `plugin/`: C++ helper plugins for Nilastia's configuration system.
*   `assets/`: Themes, fonts, default session desktop definitions, and static configurations.
*   `scripts/`: Automation scripts and helper targets.
