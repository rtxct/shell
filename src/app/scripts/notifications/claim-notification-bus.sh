#!/usr/bin/env sh
# ============================================================================
# File: scripts/notifications/claim-notification-bus.sh
# Purpose: Stops competing D-Bus notification daemons (swaync, mako, dunst)
#          so Quickshell's NotificationServer can cleanly claim
#          org.freedesktop.Notifications on startup.
# Dependencies: systemctl (optional), pkill
# ============================================================================
systemctl --user stop swaync 2>/dev/null
pkill -x swaync
pkill -x mako
pkill -x dunst || true
