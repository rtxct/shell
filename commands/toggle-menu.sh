#!/usr/bin/env bash
# ============================================================================
# File: commands/toggle-menu.sh
# Purpose: Toggle or open the Quickshell application menu via IPC.
#
# Usage:
#   toggle-menu.sh         # Toggles menu open/closed
#   toggle-menu.sh open    # Opens menu in focus
#   toggle-menu.sh close   # Closes menu
#
# Window Manager Bindings (e.g. in ~/.config/sway/config):
#   set $menu ~/.config/quickshell/commands/toggle-menu.sh
#   bindsym $mod+e exec $menu
#   bindsym Control+e exec $menu
#
# Direct Quickshell CLI alternative:
#   bindsym $mod+e exec qs ipc call menu toggle
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ACTION="${1:-toggle}"
case "$ACTION" in
    clipboard|clip|"\\")
        ACTION="clipboard"
        ;;
    open|close|toggle)
        ;;
    *)
        ;;
esac

if command -v qs >/dev/null 2>&1; then
    qs ipc call menu "$ACTION" 2>/dev/null \
        || qs -p "$CONFIG_DIR" ipc call menu "$ACTION" 2>/dev/null
elif command -v quickshell >/dev/null 2>&1; then
    quickshell ipc call menu "$ACTION" 2>/dev/null \
        || quickshell -p "$CONFIG_DIR" ipc call menu "$ACTION" 2>/dev/null
else
    echo "Error: Neither 'qs' nor 'quickshell' found in PATH." >&2
    exit 1
fi
