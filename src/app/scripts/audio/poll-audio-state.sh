#!/usr/bin/env sh
# ============================================================================
# File: scripts/audio/poll-audio-state.sh
# Purpose: Queries default PipeWire/WirePlumber sink & source volumes/mute
#          states and fallback playerctl playback status in a single call.
# Output Format (3 lines):
#   Line 1: wpctl get-volume @DEFAULT_AUDIO_SINK@   (e.g. "Volume: 0.65 [MUTED]")
#   Line 2: wpctl get-volume @DEFAULT_AUDIO_SOURCE@ (e.g. "Volume: 1.00")
#   Line 3: playerctl status                        (e.g. "Playing" or "Stopped")
# Dependencies: wpctl, playerctl
# ============================================================================
wpctl get-volume @DEFAULT_AUDIO_SINK@
wpctl get-volume @DEFAULT_AUDIO_SOURCE@
playerctl status 2>/dev/null || echo Stopped
