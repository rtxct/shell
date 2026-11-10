# Manual Shell Smoke Test (`tests/manual/smoke/`)

## Purpose & Separation Policy
This directory contains the **manual** Quickshell runtime smoke test (`run-shell-smoke.sh`).
- **When to run**: Run manually on a developer machine before merging changes that touch `shell.qml`, Wayland `PanelWindow` / `LayerShell` surfaces (`modules/bar.module.qml`, `modules/floating-window-manager.module.qml`), or Quickshell service modules (`modules/*-service.module.qml`).
- **Never run in CI**: This test launches the real `quickshell` binary against a Wayland display (or a headless Wayland compositor). It is intentionally excluded from `.github/workflows/ci.yml` and `make test-pipeline` (`make test`).

## Prerequisites
- Arch Linux packages:
  - `quickshell` (`/usr/sbin/quickshell`)
  - `qt6-declarative`, `qt6-shadertools`
  - An active Wayland session (`$WAYLAND_DISPLAY` set) **or** `sway` / `weston` installed for automatic headless fallback (`WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 sway`).

## How to Run
From the repository root:
```bash
make test-manual
# or alias:
make smoke
# or directly with a custom duration (default is 8 seconds):
SMOKE_SECONDS=4 ./tests/manual/smoke/run-shell-smoke.sh
```

## Environment Variables
| Variable | Default | Description |
|---|---|---|
| `SMOKE_SECONDS` | `8` | Total seconds to keep `quickshell -p .` running (touches `shell.qml` halfway through to verify live reload). |
| `WAYLAND_DISPLAY` | current session | Wayland socket to connect to. If unset, `run-shell-smoke.sh` spawns an isolated headless `sway` or `weston` instance and cleans it up on exit. |

## How to Interpret Results
- **`PASS`**: `quickshell` loaded `shell.qml` (`INFO: Configuration Loaded`), stayed alive for the full duration, survived a live reload triggered by `touch shell.qml`, exited cleanly on `SIGTERM`, and emitted zero fatal log patterns or unallowed warnings.
- **`FAIL`**: Printed to `stderr` with the exact offending log lines and full log excerpt. The script fails on:
  - Premature exit before `SIGTERM` or crash/segfault
  - `ERROR`, `QML Component: Component is not ready`, `ReferenceError`, `TypeError`
  - `Cannot assign to non-existent property`, `Unable to assign [undefined]`, `file not found`
  - Any `WARN` line not matched by a regex in `allowed-warnings.txt`

## Policy for `allowed-warnings.txt`
- Never add a pattern to `allowed-warnings.txt` to silence a real QML binding, type, or component error.
- Only environment-specific warnings outside the repository's control (such as third-party `.desktop` files referencing missing system icon theme names) may be added, and every entry **must** include a comment explaining why it is benign.
