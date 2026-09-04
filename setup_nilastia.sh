#!/usr/bin/env bash
set -e

echo "=== Building Nilastia Shell for Niri ==="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Build QML C++ Plugins
cmake -B build -DCMAKE_INSTALL_PREFIX=build/install -DVERSION=0.1.0
cmake --build build
cmake --install build

# Install Nilastia CLI Script
mkdir -p "$HOME/.local/bin"
chmod +x "$SCRIPT_DIR/bin/nilastia"
chmod +x "$SCRIPT_DIR/cli/bin/nilastia"
ln -sfn "$SCRIPT_DIR/bin/nilastia" "$HOME/.local/bin/nilastia"

# Link Quickshell Configuration
mkdir -p "$HOME/.config/quickshell"
ln -sfn "$SCRIPT_DIR/build/install/etc/xdg/quickshell/nilastia" "$HOME/.config/quickshell/niri-nilastia-shell"
ln -sfn "$SCRIPT_DIR/build/install/etc/xdg/quickshell/nilastia" "$HOME/.config/quickshell/niri-caelestia-shell"

# Check optional Wi-Fi Hotspot repeater requirements
if ! command -v hostapd >/dev/null 2>&1 || ! command -v create_ap >/dev/null 2>&1; then
    echo "Notice: 'hostapd' and 'linux-wifi-hotspot-bin' (create_ap) are recommended for simultaneous Wi-Fi Hotspot support."
    echo "Install via: paru -S --needed hostapd linux-wifi-hotspot-bin"
fi

echo "=== Nilastia Shell setup completed successfully! ==="
