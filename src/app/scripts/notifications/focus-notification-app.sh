#!/usr/bin/env sh
# ============================================================================
# File: scripts/notifications/focus-notification-app.sh
# Purpose: Focuses the active window matching a notification's origin
#          (appName, desktopEntry, or appIcon) on Sway or Niri.
# Dependencies: swaymsg (for Sway) or niri + python3 (for Niri)
# ============================================================================

focus_sway() {
    target="$1"
    if swaymsg "[app_id=\"(?i)$target\"] focus" >/dev/null 2>&1; then
        return 0
    fi
    if swaymsg "[class=\"(?i)$target\"] focus" >/dev/null 2>&1; then
        return 0
    fi
    if swaymsg "[title=\"(?i)$target\"] focus" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

focus_niri() {
    target="$1"
    command -v python3 >/dev/null 2>&1 || return 1
    python3 -c "
import json, subprocess, sys
target = sys.argv[1].lower()
try:
    proc = subprocess.run(['niri', 'msg', '--json', 'windows'], capture_output=True, text=True, timeout=2)
    if proc.returncode == 0:
        windows = json.loads(proc.stdout)
        for w in windows:
            app_id = (w.get('app_id') or '').lower()
            title = (w.get('title') or '').lower()
            if target in app_id or target in title:
                subprocess.run(['niri', 'msg', 'action', 'focus-window', '--id', str(w['id'])], timeout=2)
                sys.exit(0)
except Exception:
    pass
sys.exit(1)
" "$target" >/dev/null 2>&1
}

# Detect active compositor environment
IS_SWAY=0
IS_NIRI=0

if [ -n "$SWAYSOCK" ] && command -v swaymsg >/dev/null 2>&1; then
    IS_SWAY=1
elif [ -n "$NIRI_SOCKET" ] && command -v niri >/dev/null 2>&1; then
    IS_NIRI=1
elif [ "$XDG_CURRENT_DESKTOP" = "sway" ] || [ "$XDG_SESSION_DESKTOP" = "sway" ]; then
    IS_SWAY=1
elif [ "$XDG_CURRENT_DESKTOP" = "niri" ] || [ "$XDG_SESSION_DESKTOP" = "niri" ]; then
    IS_NIRI=1
elif command -v swaymsg >/dev/null 2>&1; then
    IS_SWAY=1
elif command -v niri >/dev/null 2>&1; then
    IS_NIRI=1
fi

if [ "$IS_SWAY" -eq 0 ] && [ "$IS_NIRI" -eq 0 ]; then
    exit 0
fi

for raw in "$2" "$1" "$3"; do
    [ -n "$raw" ] || continue
    clean=$(printf '%s' "$raw" | sed 's/\.desktop$//; s/.*\.//; s/[^a-zA-Z0-9 _-]//g' | sed 's/^ *//; s/ *$//')
    [ -n "$clean" ] || continue

    if [ "$IS_SWAY" -eq 1 ]; then
        if focus_sway "$clean"; then
            exit 0
        fi
    elif [ "$IS_NIRI" -eq 1 ]; then
        if focus_niri "$clean"; then
            exit 0
        fi
    fi
done

exit 0
