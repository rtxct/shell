#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
ALLOWED_WARNINGS="${SCRIPT_DIR}/allowed-warnings.txt"
SMOKE_SECONDS="${SMOKE_SECONDS:-8}"

if ! command -v quickshell >/dev/null 2>&1; then
    echo "SKIP: quickshell binary not found. Install 'quickshell' on Arch Linux to run the manual smoke test."
    exit 0
fi

LOG_FILE="$(mktemp -t qs-smoke-XXXXXX.log)"
SWAY_CFG=""
COMPOSITOR_PID=""
QS_PID=""

cleanup() {
    if [ -n "$QS_PID" ] && kill -0 "$QS_PID" 2>/dev/null; then
        kill -TERM "$QS_PID" 2>/dev/null || true
        for _ in 1 2 3 4 5; do
            kill -0 "$QS_PID" 2>/dev/null || break
            sleep 0.2
        done
        kill -KILL "$QS_PID" 2>/dev/null || true
    fi
    if [ -n "$COMPOSITOR_PID" ] && kill -0 "$COMPOSITOR_PID" 2>/dev/null; then
        kill -TERM "$COMPOSITOR_PID" 2>/dev/null || true
        wait "$COMPOSITOR_PID" 2>/dev/null || true
    fi
    [ -n "$SWAY_CFG" ] && rm -f "$SWAY_CFG"
    rm -f "$LOG_FILE"
}
trap cleanup EXIT

# Check WAYLAND_DISPLAY or launch a headless compositor if needed
if [ -z "${WAYLAND_DISPLAY:-}" ]; then
    if command -v sway >/dev/null 2>&1; then
        echo "==> No active WAYLAND_DISPLAY; starting headless sway compositor..."
        SWAY_CFG="$(mktemp -t qs-sway-headless-XXXXXX.cfg)"
        echo "# minimal headless sway config" >"$SWAY_CFG"
        WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 sway -c "$SWAY_CFG" >/dev/null 2>&1 &
        COMPOSITOR_PID=$!
        sleep 1
        # Discover the newly created wayland socket in XDG_RUNTIME_DIR
        if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
            LATEST_SOCK="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -type s -name 'wayland-*' -printf '%T@ %f\n' 2>/dev/null | sort -nr | awk 'NR==1{print $2}')"
            if [ -n "$LATEST_SOCK" ]; then
                export WAYLAND_DISPLAY="$LATEST_SOCK"
            fi
        fi
    elif command -v weston >/dev/null 2>&1; then
        echo "==> No active WAYLAND_DISPLAY; starting headless weston compositor..."
        weston --backend=headless-backend.so >/dev/null 2>&1 &
        COMPOSITOR_PID=$!
        sleep 1
    else
        echo "SKIP: No active WAYLAND_DISPLAY and no headless Wayland compositor (sway, cage, weston) found."
        echo "      Install 'sway' or run inside an active Wayland session."
        exit 0
    fi
fi

echo "==> Launching quickshell -p ${REPO_ROOT} for ${SMOKE_SECONDS}s (WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-unset})"
quickshell -p "$REPO_ROOT" >"$LOG_FILE" 2>&1 &
QS_PID=$!

HALF_WAIT=$(( SMOKE_SECONDS / 2 ))
if [ "$HALF_WAIT" -lt 1 ]; then
    HALF_WAIT=1
fi
sleep "$HALF_WAIT"

# Verify quickshell has not exited prematurely before SIGTERM
if ! kill -0 "$QS_PID" 2>/dev/null; then
    wait "$QS_PID" || EXIT_CODE=$?
    echo "FAIL: quickshell exited prematurely (exit code ${EXIT_CODE:-unknown}) before SIGTERM." >&2
    cat "$LOG_FILE" >&2
    exit 1
fi

# Trigger live reload on both config/*.config.json and a dotted style file (styles/middle-bar.style.qml)
echo "==> Triggering live reload on config/*.config.json and styles/middle-bar.style.qml..."
python3 - "${REPO_ROOT}" <<'PY'
from pathlib import Path
import sys

repo = Path(sys.argv[1])
for cfg in (repo / "config").glob("*.config.json"):
    cfg.write_text(cfg.read_text(encoding="utf-8"), encoding="utf-8")

style_file = repo / "src/app/styles/middle-bar.style.qml"
style_file.write_text(style_file.read_text(encoding="utf-8"), encoding="utf-8")
PY

REMAINING=$(( SMOKE_SECONDS - HALF_WAIT ))
if [ "$REMAINING" -lt 1 ]; then
    REMAINING=1
fi
sleep "$REMAINING"

if ! kill -0 "$QS_PID" 2>/dev/null; then
    wait "$QS_PID" || EXIT_CODE=$?
    echo "FAIL: quickshell exited prematurely after live reload (exit code ${EXIT_CODE:-unknown})." >&2
    cat "$LOG_FILE" >&2
    exit 1
fi

# Stop quickshell cleanly with SIGTERM
kill -TERM "$QS_PID" 2>/dev/null || true
for _ in 1 2 3 4 5 6 7 8 9 10; do
    kill -0 "$QS_PID" 2>/dev/null || break
    sleep 0.2
done
if kill -0 "$QS_PID" 2>/dev/null; then
    kill -KILL "$QS_PID" 2>/dev/null || true
fi
wait "$QS_PID" 2>/dev/null || true
QS_PID=""

# Inspect captured log for fatal errors and unapproved warnings
python3 - "$LOG_FILE" "$ALLOWED_WARNINGS" <<'PY'
from pathlib import Path
import re
import sys

ansi_re = re.compile(r"\x1b\[[0-9;]*[a-zA-Z]")
raw_log = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
log_text = ansi_re.sub("", raw_log)
allowed_lines = Path(sys.argv[2]).read_text(encoding="utf-8").splitlines()
allowed_patterns = [
    re.compile(line.strip())
    for line in allowed_lines
    if line.strip() and not line.strip().startswith("#")
]

fatal_regex = re.compile(
    r"(?:Segmentation fault|core dumped|\bERROR\b|QML Component: Component is not ready|"
    r"ReferenceError|TypeError|Cannot assign to non-existent property|"
    r"Unable to assign \[undefined\]|file not found)",
    re.IGNORECASE,
)

failures = []
if "Configuration Loaded" not in log_text:
    failures.append("Missing expected 'INFO: Configuration Loaded' startup log line.")

for line in log_text.splitlines():
    if fatal_regex.search(line):
        failures.append(f"Fatal log entry: {line}")
    elif "WARN" in line:
        if not any(p.search(line) for p in allowed_patterns):
            failures.append(f"Unallowed warning: {line}")

if failures:
    print("FAIL: Shell smoke test detected errors/warnings:", file=sys.stderr)
    for f in failures:
        print("  - " + f, file=sys.stderr)
    print("\n--- Full Log Excerpt ---", file=sys.stderr)
    print(log_text, file=sys.stderr)
    sys.exit(1)

print("PASS: Quickshell smoke test succeeded (startup + live reload verified with 0 unexpected warnings/errors).")
PY
