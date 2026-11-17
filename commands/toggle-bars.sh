#!/usr/bin/env bash
# ============================================================================
# File: commands/toggle-bars.sh
# Purpose: Toggle, hide, or show the Quickshell perimeter bars via IPC.
#
# Usage:
#   toggle-bars.sh         # Toggles bars hidden/shown
#   toggle-bars.sh hide    # Hides bars into idle edge strips
#   toggle-bars.sh show    # Restores bars to their original state
#
# Window Manager Bindings (e.g. in ~/.config/sway/config):
#   set $toggle_bars ~/.config/quickshell/commands/toggle-bars.sh
#   bindsym $mod+b exec $toggle_bars
#
# Direct Quickshell CLI alternative:
#   bindsym $mod+b exec qs ipc call bars toggle
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ACTION="${1:-toggle}"
case "$ACTION" in
    hide|show|toggle)
        ;;
    *)
        ACTION="toggle"
        ;;
esac

if command -v qs >/dev/null 2>&1; then
    qs ipc call bars "$ACTION" 2>/dev/null \
        || qs -p "$CONFIG_DIR" ipc call bars "$ACTION" 2>/dev/null
elif command -v quickshell >/dev/null 2>&1; then
    quickshell ipc call bars "$ACTION" 2>/dev/null \
        || quickshell -p "$CONFIG_DIR" ipc call bars "$ACTION" 2>/dev/null
else
    echo "Error: Neither 'qs' nor 'quickshell' found in PATH." >&2
    exit 1
fi
