"""
Regression test: All 6 config/*.config.json files and their properties must be
wired end-to-end for live hot-reloading.

Bugs fixed:
1. modules/events-service.module.qml guarded `icsUrl` with `&& root.icsUrl === ""`
   so editing `icsUrl` in calendar.config.json was ignored after initial load, and
   did not cache `lastRawIcs` to re-evaluate `listDays`/`windowStartDays`/
   `windowEndDays`/`maxUpcoming` on config reload.
2. modules/weather-service.module.qml ignored changes to `defaultIndex` in
   weather.config.json after initial load (`!initialLoaded || index >= locations.length`).
3. modules/notification-overlay.module.qml hardcoded `maxVisibleCount: 4` and did not
   pass `defaultTimeoutMs` / `criticalTimeoutMs` from `notifications` to `NotificationCard`.
4. components/notification-card.component.qml hardcoded `5000` and `8000` instead of
   reading `defaultTimeoutMs` and `criticalTimeoutMs`.
5. modules/media-control-bar.module.qml and modules/floating-audio-panel.module.qml
   hardcoded `0.03` in wheel handlers instead of reading `audio.wheelStep`.
6. modules/workspaces-service.module.qml did not pass `pollIntervalMs` to
   `NiriWorkspaces`, and `modules/niri-workspaces.module.qml` hardcoded `interval: 1000`.
"""

import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]


def test_all_six_config_loaders_watch_and_reload_on_file_changed():
    """Every config consumer module must declare FileView with watchChanges: true and onFileChanged reload."""
    expected_watchers = [
        ("src/app/modules/bar.module.qml", "config/layout.config.json"),
        ("src/app/modules/audio-service.module.qml", "config/audio.config.json"),
        ("src/app/modules/events-service.module.qml", "config/calendar.config.json"),
        (
            "src/app/modules/notifications-service.module.qml",
            "config/notifications.config.json",
        ),
        ("src/app/modules/weather-service.module.qml", "config/weather.config.json"),
        (
            "src/app/modules/workspaces-service.module.qml",
            "config/workspaces.config.json",
        ),
        ("src/app/modules/screen-locker.module.qml", "config/wallpaper.config.json"),
    ]
    for rel_path, cfg_rel in expected_watchers:
        src = (REPO_ROOT / rel_path).read_text(encoding="utf-8")
        assert f'Quickshell.shellPath("{cfg_rel}")' in src, f"{rel_path} missing {cfg_rel} path"
        assert "watchChanges: true" in src, f"{rel_path} missing watchChanges: true"
        assert re.search(r"onFileChanged:\s*\w+\.reload\(\)", src), f"{rel_path} missing onFileChanged: <id>.reload()"


def test_events_service_hot_reloads_ics_url_and_cached_ics():
    """events-service.module.qml must update icsUrl on reload and re-parse lastRawIcs when horizons change."""
    src = (REPO_ROOT / "src/app/modules/events-service.module.qml").read_text(encoding="utf-8")
    assert 'root.icsUrl === ""' not in src, (
        'events-service.module.qml must not block icsUrl updates with `root.icsUrl === ""`'
    )
    assert "ServiceParsers.parseCalendarConfig" in src
    assert "lastRawIcs" in src


def test_weather_service_hot_reloads_default_index():
    """weather-service.module.qml must track lastDefaultIndex so editing defaultIndex hot-reloads."""
    src = (REPO_ROOT / "src/app/modules/weather-service.module.qml").read_text(encoding="utf-8")
    assert "lastDefaultIndex" in src
    assert "parsed.defaultIndex !== lastDefaultIndex" in src


def test_notifications_overlay_and_card_bind_config_properties():
    """NotificationOverlay and NotificationCard must bind maxVisibleCount, defaultTimeoutMs, and criticalTimeoutMs."""
    overlay_src = (REPO_ROOT / "src/app/modules/notification-overlay.module.qml").read_text(encoding="utf-8")
    assert "readonly property int maxVisibleCount: 4" not in overlay_src
    assert "root.notifications.maxVisibleCount" in overlay_src
    assert "root.notifications.defaultTimeoutMs" in overlay_src
    assert "root.notifications.criticalTimeoutMs" in overlay_src

    card_src = (REPO_ROOT / "src/app/components/notification-card.component.qml").read_text(encoding="utf-8")
    assert "var timeout = 5000" not in card_src
    assert "property int defaultTimeoutMs" in card_src
    assert "property int criticalTimeoutMs" in card_src
    assert "effectiveTimeout()" in card_src


def test_audio_wheel_step_is_bound_in_media_bar_and_floating_panel():
    """MediaControlBar and FloatingAudioPanel must use audio.wheelStep instead of hardcoded 0.03."""
    media_src = (REPO_ROOT / "src/app/modules/media-control-bar.module.qml").read_text(encoding="utf-8")
    assert "0.03 : -0.03" not in media_src
    assert "root.audio.wheelStep" in media_src

    float_audio_src = (REPO_ROOT / "src/app/modules/floating-audio-panel.module.qml").read_text(encoding="utf-8")
    assert "0.03 : -0.03" not in float_audio_src
    assert "root.audio.wheelStep" in float_audio_src


def test_workspaces_passes_poll_interval_to_niri():
    """Workspaces service must pass pollIntervalMs to NiriWorkspaces and NiriWorkspaces must bind Timer.interval."""
    ws_src = (REPO_ROOT / "src/app/modules/workspaces-service.module.qml").read_text(encoding="utf-8")
    assert "pollIntervalMs: root.pollIntervalMs" in ws_src

    niri_src = (REPO_ROOT / "src/app/modules/niri-workspaces.module.qml").read_text(encoding="utf-8")
    assert "property int pollIntervalMs: 1000" in niri_src
    assert "interval: root.pollIntervalMs" in niri_src


def test_hot_reload_module_is_registered_and_wired_in_shell():
    """
    Quickshell's built-in watcher ignores dotted filenames (*.style.qml, *.component.qml, *.module.qml).
    HotReload (modules/hot-reload.module.qml) must watch theme/, styles/, components/, and modules/
    and trigger Quickshell.reload(false).
    """
    hr_path = REPO_ROOT / "src/app/modules/hot-reload.module.qml"
    assert hr_path.is_file()
    hr_src = hr_path.read_text(encoding="utf-8")
    for folder in ("themes", "src/app/styles", "src/app/components", "src/app/modules"):
        assert f'Quickshell.shellPath("{folder}")' in hr_src
    assert "Quickshell.reload(false)" in hr_src

    qmldir_src = (REPO_ROOT / "src/app/modules/qmldir").read_text(encoding="utf-8")
    assert "HotReload 1.0 hot-reload.module.qml" in qmldir_src

    shell_src = (REPO_ROOT / "shell.qml").read_text(encoding="utf-8")
    assert "HotReload" in shell_src


def test_bar_panel_windows_do_not_bind_screen_to_null_on_teardown():
    """
    During Quickshell hot-reload, tearing down Scope while PanelWindow has a direct
    `screen: scope.modelData` binding calls `QWindow::setScreen(nullptr)` and segfaults.
    PanelWindow must assign `screen` via `Component.onCompleted: if (scope.modelData) screen = scope.modelData`.
    """
    bar_src = (REPO_ROOT / "src/app/modules/bar.module.qml").read_text(encoding="utf-8")
    assert "screen: scope.modelData" not in bar_src
    assert bar_src.count("Component.onCompleted: if (scope.modelData) screen = scope.modelData") == 6
