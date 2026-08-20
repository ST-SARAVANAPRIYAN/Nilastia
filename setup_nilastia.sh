#!/usr/bin/env bash
set -e

echo "=== Building Nilastia Shell for Niri ==="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Build QML C++ Plugins
cmake -B build -DCMAKE_INSTALL_PREFIX=build/install -DVERSION=0.1.0
cmake --build build
cmake --install build

# Install Nilastia CLI Scripts
mkdir -p "$HOME/.local/bin"
cp "$SCRIPT_DIR/bin/nilastia" "$HOME/.local/bin/nilastia"
chmod +x "$HOME/.local/bin/nilastia"
cp "$SCRIPT_DIR/bin/nilastia-gpu-select" "$HOME/.local/bin/nilastia-gpu-select"
chmod +x "$HOME/.local/bin/nilastia-gpu-select"

# Install GPU Select Systemd Service
mkdir -p "$HOME/.config/systemd/user"
cp "$SCRIPT_DIR/systemd/nilastia-gpu-select.service" "$HOME/.config/systemd/user/nilastia-gpu-select.service"
systemctl --user daemon-reload
systemctl --user enable nilastia-gpu-select.service

# Link Quickshell Configuration
mkdir -p "$HOME/.config/quickshell"
ln -sfn "$SCRIPT_DIR/build/install/etc/xdg/quickshell/nilastia" "$HOME/.config/quickshell/niri-nilastia-shell"
ln -sfn "$SCRIPT_DIR/build/install/etc/xdg/quickshell/nilastia" "$HOME/.config/quickshell/niri-caelestia-shell"

echo "=== Nilastia Shell setup completed successfully! ==="
