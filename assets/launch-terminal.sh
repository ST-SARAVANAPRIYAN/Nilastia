#!/usr/bin/env bash
# Launch the configured terminal emulator from nilastia shell.json configuration
# Reads from nilastia config, falls back to foot

CONFIG_FILE="$HOME/.config/nilastia/shell.json"

if [[ -f "$CONFIG_FILE" ]] && command -v jq &>/dev/null; then
    TERMINAL=$(jq -r '.general.apps.terminal[0] // empty' "$CONFIG_FILE")
fi

TERMINAL="${TERMINAL:-foot}"

if command -v "$TERMINAL" &>/dev/null; then
    exec "$TERMINAL" "$@"
fi

# Fallback chain: foot first, then popular alternatives
for fallback in foot kitty ghostty alacritty wezterm konsole xterm; do
    if command -v "$fallback" &>/dev/null; then
        exec "$fallback" "$@"
    fi
done

echo "No terminal emulator found" >&2
exit 1
