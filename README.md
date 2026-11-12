## Overview

The idea is simple: keep the things you use every day close at hand, without having to open a browser tab or launch another application.

The interface stays consistent and fluid, while remaining out of the way when not in use. Everything is integrated directly into edge bars and floating panels. Why not have something that is practical and yet beautiful?


https://github.com/user-attachments/assets/c84c8a68-f76d-4cd6-954a-f784688a8d30


## What's Inside

The shell organizes its controls around the perimeter of the screen.

### Top Bar

| Section | Description |
| :--- | :--- |
| **Center Island**<br>Clock, Calendar & Weather | Shows time and date. Expands on click into a monthly calendar synced with an `.ics` feed, alongside current weather and a 7-day forecast (via Open-Meteo). |
| **Left Wing**<br>Process Monitor | A btop-style active process list with real-time text filtering and column sorting by Name, CPU, GPU, or Memory usage. |
| **Right Wing**<br>Hardware Performance | Live CPU, GPU, and Memory gauges with temperatures and click-to-expand telemetry breakdowns. |

### Left Bar & Circles

**Workspace Island**

Central workspace indicators (supports both `sway` and `niri`) that expand into a workspace navigation view.

**Top Circles: Connectivity & Comfort**

| Control | Features |
| :--- | :--- |
| **Wi-Fi** | Network scanner, signal strength, connection status, password prompts |
| **Bluetooth** | Device discovery, pairing, battery indicators, connect/disconnect toggles |
| **Night Light** | Gamma temperature controls, toggle, coordinate adjustments |

**Bottom Circles: Power & Battery**

| Control | Features |
| :--- | :--- |
| **Power Profiles** | Quick toggle between Performance, Balanced, and Power Saver |
| **Battery Diagnostics** | Real-time percentage, time to empty/full, health, cycle count |
| **Session Actions** | Quick triggers for Reboot, Power Off, Sleep, and Lock |

### Bottom-Left Corner: App Menu & Clipboard

| Feature | Description |
| :--- | :--- |
| **App Launcher** | Fast search for desktop applications and terminal commands. Features persistent sorting modes (**Alphabetical** vs. **Most Used** via launch frequency tracking), a live cache storage monitor with a one-click prune action, and immediate top-item selection on open for instant `Enter` key launching. |
| **Clipboard** | Searchable clipboard history manager with quick copy and item removal. |
| **Utilities** | Built-in screenshot capture triggers and screen color picker. |

### Notification Center

A tab drawer at the bottom center of the screen that slides up into notification history, with Do-Not-Disturb and clear-all controls.

### Media & Audio

Located at the bottom right, with music playback controls (`playerctl`), a Cava spectrum visualizer, volume/mic buttons that morph into unified sliders on click, and audio stream routing.

### Right Edge

**Stick Notes**

A perimeter drawer for quick scratchpad notes with swipe gestures, saved locally to `~/.cache/sticknote`.

### Window Management & Locker

| Feature | Description |
| :--- | :--- |
| **Detachable Floating Windows** | Panels can be detached from the bar into floating, draggable windows. |
| **Screen Locker** | Wayland session lock (`ext-session-lock-v1`) with PAM authentication and wallpaper integration (`awww`). |


## Requirements

Targeted at **Arch Linux**. Runtime system packages are listed in [`requirements.txt`](./requirements.txt):

```bash
grep -vE '^\s*(#|$)' requirements.txt | sudo pacman -S --needed -
```

## Installation

**Run directly from the repo** inside an active Wayland session:

```bash
quickshell -p .
```

**Install into `~/.config/quickshell`** (backs up any existing configuration first):

```bash
./install.sh
qs
```

## Window Manager Keybindings

The shell exposes IPC handlers for window manager shortcuts or custom scripts.

**Application menu**

```bash
qs ipc call menu toggle
# or: ~/.config/quickshell/commands/toggle-menu.sh
```

**Clipboard history**

```bash
qs ipc call clipboard toggle
# or: ~/.config/quickshell/commands/clipboard-menu.sh
```

**Screen locker**

```bash
qs ipc call lock lock
# or: ~/.config/quickshell/commands/lock-screen.sh
```

## Configuration

Settings live in [`config/`](./config/) as JSON files and **hot-reload on save**.

| File | Purpose |
| :--- | :--- |
| [`workspaces.config.json`](./config/workspaces.config.json) | Compositor backend (`"sway"` or `"niri"`), workspace count, and poll interval. |
| [`weather.config.json`](./config/weather.config.json) | Location coordinates, default city, and refresh timer. |
| [`calendar.config.json`](./config/calendar.config.json) | Private `.ics` calendar URL (or `QS_ICS_URL` env variable) and fetch horizons. |
| [`sunset.config.json`](./config/sunset.config.json) | Night light coordinates and day/night color temperatures. |
| [`audio.config.json`](./config/audio.config.json) | Volume steps, limits, and Cava spectrum settings. |
| [`notifications.config.json`](./config/notifications.config.json) | Popup display timeouts and max visible toast count. |
| [`layout.config.json`](./config/layout.config.json) | Bar thickness, gaps, margins, and placement coordinates. |
| [`wallpaper.config.json`](./config/wallpaper.config.json) | Fallback wallpaper path for the screen locker. |

## Testing

Headless automated pipeline checks: Python tests, config schemas, QML component tests, and linters.

```bash
python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt
PATH=$PWD/.venv/bin:$PATH make test
```
