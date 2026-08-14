#!/usr/bin/env bash

# Exit on error
set -e

# Project root directory
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Nilastia Nested Shell Tester ==="
echo "Building the latest changes..."
cmake --build "$DIR/build"
cmake --build "$DIR/build" --target install

# Find an unused wayland display socket name
NESTED_DISPLAY=""
for i in {1..9}; do
    if [ ! -S "$XDG_RUNTIME_DIR/wayland-$i" ]; then
        NESTED_DISPLAY="wayland-$i"
        break
    fi
done

if [ -z "$NESTED_DISPLAY" ]; then
    echo "Error: No free Wayland sockets found."
    exit 1
fi

echo "Starting nested Niri window on socket $NESTED_DISPLAY..."
# Run niri nested in background
niri --nested --wayland-socket-name "$NESTED_DISPLAY" > /tmp/niri-nested.log 2>&1 &
NIRI_PID=$!

# Cleanup function to kill background processes on exit
cleanup() {
    echo "Cleaning up nested processes..."
    kill "$NIRI_PID" 2>/dev/null || true
}
trap cleanup EXIT

# Wait for socket to appear
echo "Waiting for nested Niri socket to initialize..."
for i in {1..20}; do
    if [ -S "$XDG_RUNTIME_DIR/$NESTED_DISPLAY" ]; then
        break
    fi
    sleep 0.1
done

if [ ! -S "$XDG_RUNTIME_DIR/$NESTED_DISPLAY" ]; then
    echo "Error: Nested Niri failed to start or socket was not created."
    cat /tmp/niri-nested.log
    exit 1
fi

echo "Nested Niri is running!"
echo "Launching Quickshell inside the nested session..."
echo "Press Ctrl+C in this terminal or close the nested window to exit."

export QML2_IMPORT_PATH="$DIR/build/install/lib/qt6/qml"
export WAYLAND_DISPLAY="$NESTED_DISPLAY"

# Launch quickshell
exec /usr/bin/quickshell -n -c niri-nilastia-shell
