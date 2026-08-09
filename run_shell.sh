#!/bin/bash
export PATH="$HOME/.local/bin:$PATH"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export QML2_IMPORT_PATH="$DIR/build/install/lib/qt6/qml"
exec /usr/bin/quickshell -n -c niri-nilastia-shell
