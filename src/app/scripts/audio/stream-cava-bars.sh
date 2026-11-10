#!/usr/bin/env sh
# ============================================================================
# File: scripts/audio/stream-cava-bars.sh
# Purpose: Streams a live FFT frequency spectrum of the default PipeWire sink
#          monitor using cava in raw ASCII mode, for the MediaControlBar
#          border visualizer.
# Usage:   stream-cava-bars.sh <bars> <framerate> <noise_reduction>
#            bars             number of frequency bands, 2..64 (bass -> treble)
#            framerate        frames per second, 10..144
#            noise_reduction  cava smoothing, 0..100 (lower = snappier)
# Output Format (one line per frame, values 0..1000, bass first):
#   "v0;v1;v2;...;vN;"
# Exit Codes:
#   0   cava exited normally
#   2   invalid arguments
#   127 cava is not installed
# Dependencies: cava (>= 0.10, PipeWire input)
# Notes:   The generated cava config is written to a fixed path under
#          $XDG_RUNTIME_DIR (tmpfs, cleared on logout) and overwritten on every
#          start, so no temp files accumulate. `exec` hands the PID to cava so
#          Quickshell's Process kill reaches cava directly.
# ============================================================================

bars="${1:-}"
framerate="${2:-}"
noise_reduction="${3:-}"

is_int_in_range() {
    case "$1" in
        '' | *[!0-9]*) return 1 ;;
    esac
    [ "$1" -ge "$2" ] && [ "$1" -le "$3" ]
}

if ! is_int_in_range "$bars" 2 64 \
    || ! is_int_in_range "$framerate" 10 144 \
    || ! is_int_in_range "$noise_reduction" 0 100; then
    echo "stream-cava-bars.sh: usage: stream-cava-bars.sh <bars 2..64> <framerate 10..144> <noise_reduction 0..100>" >&2
    exit 2
fi

if ! command -v cava >/dev/null 2>&1; then
    echo "stream-cava-bars.sh: cava not found in PATH; install it with 'sudo pacman -S cava' to enable the frequency visualizer" >&2
    exit 127
fi

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
config_path="$runtime_dir/qs-topbar-cava.conf"

cat >"$config_path" <<EOF
[general]
framerate = $framerate
bars = $bars
autosens = 1
lower_cutoff_freq = 40
higher_cutoff_freq = 12000

[input]
method = pipewire
source = auto

[output]
method = raw
channels = mono
mono_option = average
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 1000
bar_delimiter = 59
frame_delimiter = 10

[smoothing]
noise_reduction = $noise_reduction
monstercat = 0
waves = 0
EOF

exec cava -p "$config_path"
