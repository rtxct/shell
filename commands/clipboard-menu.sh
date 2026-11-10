#!/usr/bin/env bash
# ============================================================================
# File: commands/clipboard-menu.sh
# Purpose: Open the Quickshell application menu in clipboard history mode ("\").
#
# Usage:
#   clipboard-menu.sh
#
# Window Manager Bindings (e.g. in ~/.config/sway/config):
#   set $clipboard ~/.config/quickshell/commands/clipboard-menu.sh
#   bindsym $mod+BackSpace exec $clipboard
#
# Direct Quickshell CLI alternative:
#   bindsym $mod+BackSpace exec qs ipc call menu clipboard
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/toggle-menu.sh" clipboard "$@"
