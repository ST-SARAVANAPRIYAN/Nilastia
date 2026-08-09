# 🌌 Nilastia Shell

<div align="center">

**A Fluid, Morphing Desktop Shell Ported for the Niri Window Manager**

*Based on the aesthetic-driven [Caelestia Shell](https://github.com/caelestia-dots/shell) but adapted natively to run under Niri.*

---

[![GitHub last commit](https://img.shields.io/github/last-commit/ST-SARAVANAPRIYAN/Nilastia?style=for-the-badge&labelColor=101418&color=9ccbfb)](https://github.com/ST-SARAVANAPRIYAN/Nilastia)
[![GitHub Repo stars](https://img.shields.io/github/stars/ST-SARAVANAPRIYAN/Nilastia?style=for-the-badge&labelColor=101418&color=b9c8da)](https://github.com/ST-SARAVANAPRIYAN/Nilastia)

</div>

---

## 🚀 Overview

**Nilastia Shell** is a fully functional, highly polished desktop shell for the **Niri window manager**. It replicates the aesthetic experience of the original Caelestia Shell (originally built for Hyprland) using a custom **Niri translation layer**. 

Through an IPC event-stream parser and action translation mock, the shell interacts directly with Niri, giving you a fluid, animated bar, a detailed resource control center, dynamic screenshot utility, and automatic Material Design 3 color palette matching based on your desktop wallpaper.

---

## ✨ Features

- **Niri Workspace Indicators**: Workspace pills light up dynamically matching Niri's scrolling workspace ribbon.
- **Active Window Status**: Real-time display of focused window title and matching application icon.
- **Material You Dynamic Theming**: Automated color-palette generation from your desktop wallpaper using the `caelestia-cli` backend, saving colors directly to `scheme.json` and refreshing UI widgets on the fly.
- **Keyboard Layout Switcher**: Native Niri keyboard layout querying and switching via a clean bar popout.
- **Interactive Control Center (Dashboard)**: Includes CPU, RAM, GPU, storage, battery, network resource cards, and a Media controller with lyrics and circular cover visualizer.
- **Screenshot Area Picker**: Leverages Niri output dimensions to highlight and screenshot selected windows, screens, or custom regions.
- **Systemd User Service**: Starts automatically alongside your Niri graphical session.

---

## ⌨️ Niri Keybindings

The shell exposes standard IPC endpoints that can be mapped to your Niri configuration. You can bind these in your [`~/.config/niri/config.d/70-binds.kdl`](file:///home/saravana/.config/niri/config.d/70-binds.kdl):

```kdl
// Toggles the resource dashboard
Super+G { spawn "quickshell" "-c" "niri-caelestia-shell" "ipc" "call" "drawers" "toggle" "dashboard"; }

// Toggles the application launcher drawer
Mod+Space repeat=false { spawn "quickshell" "-c" "niri-caelestia-shell" "ipc" "call" "drawers" "toggle" "launcher"; }

// Toggles the session exit/lock drawer
Mod+Shift+Q { spawn "quickshell" "-c" "niri-caelestia-shell" "ipc" "call" "drawers" "toggle" "session"; }

// Triggers screenshot area picker
Mod+Shift+S { spawn "quickshell" "-c" "niri-caelestia-shell" "ipc" "call" "picker" "open"; }

// Lock screen
Mod+Alt+L allow-when-locked=true { spawn "quickshell" "-c" "niri-caelestia-shell" "ipc" "call" "lock" "lock"; }
```

---

## 🛠️ Graphical Settings UI ("Nexus")

Nilastia features a built-in control panel for configuring your desktop theme, borders, layout paddings, and background widgets. Open it by running:

```bash
quickshell -c niri-caelestia-shell ipc call nexus open
```

---

## 📦 Installation & Setup

### 1. Prerequisites (Arch Linux)
Ensure you have the required AUR packages installed:
```bash
# Install the Quickshell engine & Caelestia background helper
yay -S quickshell-git caelestia-cli-git
```

### 2. Build & Install Locally
Clone this repository to your projects folder, build the plugins, and install the QML assets:
```bash
# Clone the repository
git clone https://github.com/ST-SARAVANAPRIYAN/Nilastia.git ~/projects/calestia/shell
cd ~/projects/calestia/shell

# Build the C++ custom QML modules
cmake -B build -DCMAKE_INSTALL_PREFIX=build/install
cmake --build build
cmake --install build
```

### 3. Link named configuration
Create a symlink so that Quickshell identifies this shell by its configuration name (`niri-caelestia-shell`) for your keybindings:
```bash
ln -s ~/projects/calestia/shell/build/install/etc/xdg/quickshell/caelestia ~/.config/quickshell/niri-caelestia-shell
```

### 4. Enable Startup Service
The shell is launched via systemd. The active service configuration is located at [`~/.config/systemd/user/niri-caelestia-shell.service`](file:///home/saravana/.config/systemd/user/niri-caelestia-shell.service).

Start or restart the service to apply changes:
```bash
systemctl --user daemon-reload
systemctl --user restart niri-caelestia-shell.service
```

---

## 📁 File Structure

- [`services/Hypr.qml`](file:///home/saravana/projects/calestia/shell/services/Hypr.qml) - The compositor translation layer mocking Hyprland's IPC to execute Niri actions.
- [`services/ShellState.qml`](file:///home/saravana/projects/calestia/shell/services/ShellState.qml) - Screen-specific active workspace states.
- [`modules/bar/popouts/kblayout/KbLayoutModel.qml`](file:///home/saravana/projects/calestia/shell/modules/bar/popouts/kblayout/KbLayoutModel.qml) - Lists and switches layouts using Niri.
- [`run_shell.sh`](file:///home/saravana/projects/calestia/shell/run_shell.sh) - Service runner script setting up the library import paths.

---

## 💖 Credits & Acknowledgements

- **[Caelestia Shell](https://github.com/caelestia-dots/shell)**: The original fluid, morphing desktop shell and widgets designed and created by **[Soramane](https://github.com/Soramane)** and the **caelestia-dots** contributors.
- **[Quickshell](https://quickshell.outfoxxed.me)**: The powerful Wayland shell scripting engine developed by **[Outfoxxed](https://github.com/Outfoxxed)**.
- **[Nilastia Shell](https://github.com/ST-SARAVANAPRIYAN/Nilastia)**: Niri integration, compositor IPC mock mapping translation layer, and system setup adaptations by **[ST-SARAVANAPRIYAN](https://github.com/ST-SARAVANAPRIYAN)**.

