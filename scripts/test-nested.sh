#!/usr/bin/env bash

# Exit on error
set -e

# Project root directory
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Nilastia Nested Shell Tester ==="
echo "Building the latest changes..."
cmake --build "$DIR/build"
cmake --build "$DIR/build" --target install

# Record existing Wayland sockets before launching
EXISTING_SOCKETS=$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name "wayland-*" | sort)

echo "Starting nested Niri window..."
# Run niri nested in background (it runs nested automatically when launched inside a GUI session)
niri > /tmp/niri-nested.log 2>&1 &
NIRI_PID=$!

# Cleanup function to kill background processes on exit
cleanup() {
    echo "Cleaning up nested processes..."
    kill "$NIRI_PID" 2>/dev/null || true
}
trap cleanup EXIT

# Wait for niri to create the new socket
echo "Waiting for nested Niri socket to initialize..."
NESTED_DISPLAY=""
for i in {1..50}; do
    CURRENT_SOCKETS=$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name "wayland-*" | sort)
    # Find which socket is new
    NEW_SOCKET=$(comm -13 <(echo "$EXISTING_SOCKETS") <(echo "$CURRENT_SOCKETS") | head -n 1)
    if [ -n "$NEW_SOCKET" ]; then
        NESTED_DISPLAY=$(basename "$NEW_SOCKET")
        break
    fi
    sleep 0.1
done

if [ -z "$NESTED_DISPLAY" ]; then
    echo "Error: Nested Niri failed to start or did not create a new Wayland socket."
    echo "Niri Log:"
    cat /tmp/niri-nested.log
    exit 1
fi

echo "Nested Niri is running on socket: $NESTED_DISPLAY"
echo "Launching Quickshell inside the nested session..."
echo "Press Ctrl+C in this terminal or close the nested window to exit."

export QML2_IMPORT_PATH="$DIR/build/install/lib/qt6/qml"
export WAYLAND_DISPLAY="$NESTED_DISPLAY"

# Launch quickshell
exec /usr/bin/quickshell -n -c niri-nilastia-shell
