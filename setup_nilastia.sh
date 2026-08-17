#!/usr/bin/env bash
set -e

echo "=== Building Nilastia Shell for Niri ==="
cd "$HOME/Nilastia"

# Build QML C++ Plugins
cmake -B build -DCMAKE_INSTALL_PREFIX=build/install -DVERSION=0.1.0
cmake --build build
cmake --install build

# Install Nilastia CLI Script
mkdir -p "$HOME/.local/bin"
cp "$HOME/Nilastia/bin/nilastia" "$HOME/.local/bin/nilastia"
chmod +x "$HOME/.local/bin/nilastia"

# Link Quickshell Configuration
mkdir -p "$HOME/.config/quickshell"
ln -sfn "$HOME/Nilastia/build/install/etc/xdg/quickshell/nilastia" "$HOME/.config/quickshell/niri-nilastia-shell"
ln -sfn "$HOME/Nilastia/build/install/etc/xdg/quickshell/nilastia" "$HOME/.config/quickshell/niri-caelestia-shell"

echo "=== Nilastia Shell setup completed successfully! ==="
