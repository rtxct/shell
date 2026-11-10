# Shell

A fluid and practical [Quickshell](https://quickshell.outfoxxed.me/) configuration for Wayland.

## Why

The idea behind this setup is straightforward: keep everyday tools within mouse reach—checking the calendar, glancing at the weather, jotting down a quick note, switching audio outputs, or toggling Wi-Fi and night light—without needing to open a browser tab or spawn separate utility window, while keeping the interface visually consistent and out of the way when idle.

## What's Inside

The shell runs per-monitor edge bars and corner controls that expand on hover or click and can be detached into floating panels:

- **Top Center (Clock, Calendar & Weather):** Displays time and date on the top bar; expands into a monthly calendar synced with an `.ics` feed alongside current weather and a 7-day forecast (via Open-Meteo).
- **Top Wings (Media, Audio & Notifications):**
  - Left wing: Media playback controls (`playerctl`), Cava audio spectrum visualizer, volume/mic sliders, and per-device/per-stream audio routing (PipeWire/PulseAudio).
  - Right wing: Notification center with history, urgency filtering, and pop-up toast overlays.
- **Right Edge (Stick Notes):** Slide-out drawer for quick persistent notes stored locally in `~/.cache/sticknote`.
- **Corner Circles:**
  - **Top-Left:** Wi-Fi manager (`nmcli`), Bluetooth pairing/device manager, and Night Light (`wlsunset`) controls.
  - **Bottom-Left:** App launcher trigger, battery/power profile status (`powerprofilesctl`), and live CPU/RAM/GPU/process monitor.
- **App Menu, Clipboard & Quick Commands:** Searchable application launcher, `cliphist` clipboard history, and built-in utility commands (screenshots via `grim`/`slurp`/`satty`, color picker via `hyprpicker`, power actions).
- **Workspaces:** Bottom workspace indicator supporting both `sway` and `niri`.
- **Screen Locker:** Wayland session lock (`ext-session-lock-v1`) with PAM authentication and `awww` wallpaper integration.

## Requirements

Targeted at Arch Linux. All runtime system dependencies are listed in [`requirements.txt`](./requirements.txt):

```bash
grep -vE '^\s*(#|$)' requirements.txt | sudo pacman -S --needed -
```

## Usage & Installation

To run directly from the repository inside a Wayland session:

```bash
quickshell -p .
```

To install into `~/.config/quickshell` (backs up any existing configuration first):

```bash
./install.sh
qs
```

## Window Manager Bindings

The shell exposes IPC handlers for window manager shortcuts (or via the helper scripts in [`commands/`](./commands/)):

```bash
# App menu
qs ipc call menu toggle
# or: ~/.config/quickshell/commands/toggle-menu.sh

# Clipboard history
qs ipc call clipboard toggle
# or: ~/.config/quickshell/commands/clipboard-menu.sh

# Screen locker
qs ipc call lock lock
# or: ~/.config/quickshell/commands/lock-screen.sh
```

## Configuration

Settings live in [`config/`](./config/) and are hot-reloaded automatically when saved:

| File | Purpose |
| :--- | :--- |
| [`config/workspaces.config.json`](./config/workspaces.config.json) | Compositor backend (`"sway"` or `"niri"`), workspace count, and poll interval. |
| [`config/weather.config.json`](./config/weather.config.json) | Locations (`name`, `latitude`, `longitude`), default index, and refresh interval. |
| [`config/calendar.config.json`](./config/calendar.config.json) | Private `.ics` URL (or set `QS_ICS_URL` in your environment) and sync window. |
| [`config/sunset.config.json`](./config/sunset.config.json) | Night light coordinates and day/night color temperatures. |
| [`config/audio.config.json`](./config/audio.config.json) | Max volume, scroll step, and Cava spectrum settings. |
| [`config/notifications.config.json`](./config/notifications.config.json) | Popup timeouts and max visible count. |
| [`config/layout.config.json`](./config/layout.config.json) | Bar dimensions, gaps, and screen margins. |
| [`config/wallpaper.config.json`](./config/wallpaper.config.json) | Fallback wallpaper path for the screen locker when `awww` is not running. |

QML files under `themes/`, `src/app/styles/`, `src/app/components/`, and `src/app/modules/` are also watched for live reload during development.

## Testing

Automated pipeline tests (Python unit tests, JSON schema validation, headless Qt Quick tests, and static linters) run without a compositor or network access:

```bash
python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt
PATH=$PWD/.venv/bin:$PATH make test
```

See [`src/test/README.md`](./src/test/README.md) for details on the test suite and manual smoke tests.
