#!/usr/bin/env sh
# ============================================================================
# File: scripts/notifications/focus-notification-app.sh
# Purpose: Focuses the Sway/Wayland window matching a notification's origin
#          (appName, desktopEntry, or appIcon) when a notification is clicked.
# Dependencies: swaymsg (optional)
# ============================================================================
if ! command -v swaymsg >/dev/null 2>&1; then
    exit 0
fi

for raw in "$2" "$1" "$3"; do
    [ -n "$raw" ] || continue
    clean=$(printf '%s' "$raw" | sed 's/\.desktop$//; s/.*\.//; s/[^a-zA-Z0-9 _-]//g' | sed 's/^ *//; s/ *$//')
    [ -n "$clean" ] || continue
    if swaymsg "[app_id=\"(?i)$clean\"] focus" >/dev/null 2>&1; then
        exit 0
    fi
    if swaymsg "[class=\"(?i)$clean\"] focus" >/dev/null 2>&1; then
        exit 0
    fi
    if swaymsg "[title=\"(?i)$clean\"] focus" >/dev/null 2>&1; then
        exit 0
    fi
done
exit 0
