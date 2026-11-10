"""
Subprocess and golden-file tests for POSIX shell scripts in scripts/:
- scripts/audio/poll-audio-state.sh
- scripts/notifications/claim-notification-bus.sh
"""

import os
import stat
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[4]
POLL_AUDIO_SCRIPT = REPO_ROOT / "src" / "app" / "scripts" / "audio" / "poll-audio-state.sh"
CLAIM_BUS_SCRIPT = REPO_ROOT / "src" / "app" / "scripts" / "notifications" / "claim-notification-bus.sh"
STREAM_CAVA_SCRIPT = REPO_ROOT / "src" / "app" / "scripts" / "audio" / "stream-cava-bars.sh"
TOGGLE_MENU_SCRIPT = REPO_ROOT / "commands" / "toggle-menu.sh"


def _write_executable(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")
    path.chmod(path.stat().st_mode | stat.S_IEXEC)


def test_poll_audio_state_golden_playing(tmp_path, fixtures_dir):
    """
    Golden-file test verifying the exact 3-line stdout contract that
    modules/audio-service.module.qml parses when audio is playing.
    """
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()

    _write_executable(
        bin_dir / "wpctl",
        """#!/usr/bin/env sh
if [ "$2" = "@DEFAULT_AUDIO_SINK@" ]; then
    echo "Volume: 0.65"
elif [ "$2" = "@DEFAULT_AUDIO_SOURCE@" ]; then
    echo "Volume: 0.50 [MUTED]"
fi
""",
    )
    _write_executable(
        bin_dir / "playerctl",
        """#!/usr/bin/env sh
echo "Playing"
""",
    )

    env = os.environ.copy()
    env["PATH"] = f"{bin_dir}:{env.get('PATH', '')}"

    res = subprocess.run(
        ["sh", str(POLL_AUDIO_SCRIPT)],
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )
    golden = (fixtures_dir / "poll_audio_playing.golden.txt").read_text(encoding="utf-8")
    assert res.stdout == golden


def test_poll_audio_state_playerctl_failure_fallback(tmp_path):
    """
    When playerctl fails (no active MPRIS players), poll-audio-state.sh must
    still exit 0 and print 'Stopped' on line 3.
    """
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()

    _write_executable(
        bin_dir / "wpctl",
        """#!/usr/bin/env sh
echo "Volume: 1.00"
""",
    )
    _write_executable(
        bin_dir / "playerctl",
        """#!/usr/bin/env sh
echo "No players found" >&2
exit 1
""",
    )

    env = os.environ.copy()
    env["PATH"] = f"{bin_dir}:{env.get('PATH', '')}"

    res = subprocess.run(
        ["sh", str(POLL_AUDIO_SCRIPT)],
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )
    lines = res.stdout.strip().splitlines()
    assert lines == ["Volume: 1.00", "Volume: 1.00", "Stopped"]


@pytest.mark.parametrize("pkill_exit_code", [0, 1])
def test_claim_notification_bus_exits_zero(tmp_path, pkill_exit_code):
    """
    claim-notification-bus.sh must stop swaync/mako/dunst and always exit 0
    even when none of those processes are running (pkill returns 1).
    """
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    log_file = tmp_path / "calls.log"

    _write_executable(
        bin_dir / "systemctl",
        f"""#!/usr/bin/env sh
echo "systemctl $*" >> "{log_file}"
exit {pkill_exit_code}
""",
    )
    _write_executable(
        bin_dir / "pkill",
        f"""#!/usr/bin/env sh
echo "pkill $*" >> "{log_file}"
exit {pkill_exit_code}
""",
    )

    env = os.environ.copy()
    env["PATH"] = f"{bin_dir}:{env.get('PATH', '')}"

    res = subprocess.run(
        ["sh", str(CLAIM_BUS_SCRIPT)],
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    assert res.returncode == 0
    calls = log_file.read_text(encoding="utf-8").splitlines()
    assert "systemctl --user stop swaync" in calls
    assert "pkill -x swaync" in calls
    assert "pkill -x mako" in calls
    assert "pkill -x dunst" in calls


@pytest.mark.parametrize(
    "args",
    [
        [],
        ["1", "60", "50"],  # bars < 2
        ["65", "60", "50"],  # bars > 64
        ["20", "5", "50"],  # framerate < 10
        ["20", "150", "50"],  # framerate > 144
        ["20", "60", "-1"],  # noise_reduction < 0
        ["20", "60", "101"],  # noise_reduction > 100
        ["notanumber", "60", "50"],
    ],
)
def test_stream_cava_bars_arg_validation(args):
    """stream-cava-bars.sh must reject invalid or missing arguments with exit code 2."""
    res = subprocess.run(
        ["sh", str(STREAM_CAVA_SCRIPT)] + args,
        capture_output=True,
        text=True,
        check=False,
    )
    assert res.returncode == 2
    assert "usage:" in res.stderr


def test_stream_cava_bars_missing_cava(tmp_path):
    """When cava is not found in PATH, stream-cava-bars.sh exits 127 with install advice."""
    fake_bin = tmp_path / "fake_bin"
    fake_bin.mkdir()
    (fake_bin / "sh").symlink_to("/bin/sh")
    (fake_bin / "cat").symlink_to("/bin/cat")

    env = os.environ.copy()
    env["PATH"] = str(fake_bin)

    res = subprocess.run(
        [str(fake_bin / "sh"), str(STREAM_CAVA_SCRIPT), "20", "60", "50"],
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    assert res.returncode == 127
    assert "cava not found in PATH" in res.stderr


def test_stream_cava_bars_runs_cava_with_generated_config(tmp_path):
    """
    stream-cava-bars.sh generates a valid cava config in $XDG_RUNTIME_DIR
    and execs cava with the -p flag.
    """
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    runtime_dir = tmp_path / "runtime"
    runtime_dir.mkdir()

    log_file = tmp_path / "cava.log"

    _write_executable(
        bin_dir / "cava",
        f"""#!/usr/bin/env sh
echo "cava $*" > "{log_file}"
cat "$2" >> "{log_file}"
echo "0;10;20;30;"
""",
    )

    env = os.environ.copy()
    env["PATH"] = f"{bin_dir}:{env.get('PATH', '')}"
    env["XDG_RUNTIME_DIR"] = str(runtime_dir)

    res = subprocess.run(
        ["sh", str(STREAM_CAVA_SCRIPT), "4", "30", "25"],
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )
    assert res.stdout.strip() == "0;10;20;30;"
    log_content = log_file.read_text(encoding="utf-8")
    assert f"cava -p {runtime_dir}/qs-topbar-cava.conf" in log_content
    assert "bars = 4" in log_content
    assert "framerate = 30" in log_content
    assert "noise_reduction = 25" in log_content
    assert "method = raw" in log_content


def test_toggle_menu_calls_qs_ipc(tmp_path):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    log_file = tmp_path / "qs.log"

    _write_executable(
        bin_dir / "qs",
        f"""#!/usr/bin/env sh
echo "$*" >> "{log_file}"
""",
    )

    env = os.environ.copy()
    env["PATH"] = f"{bin_dir}:{env.get('PATH', '')}"

    res = subprocess.run(
        ["bash", str(TOGGLE_MENU_SCRIPT)],
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )
    assert res.returncode == 0
    assert "ipc call menu toggle" in log_file.read_text(encoding="utf-8")


def test_toggle_menu_supports_action_arg(tmp_path):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    log_file = tmp_path / "qs.log"

    _write_executable(
        bin_dir / "qs",
        f"""#!/usr/bin/env sh
echo "$*" >> "{log_file}"
""",
    )

    env = os.environ.copy()
    env["PATH"] = f"{bin_dir}:{env.get('PATH', '')}"

    res = subprocess.run(
        ["bash", str(TOGGLE_MENU_SCRIPT), "open"],
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )
    assert res.returncode == 0
    assert "ipc call menu open" in log_file.read_text(encoding="utf-8")


def test_toggle_menu_fallback_quickshell(tmp_path):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    log_file = tmp_path / "quickshell.log"

    _write_executable(
        bin_dir / "quickshell",
        f"""#!/usr/bin/env sh
echo "$*" >> "{log_file}"
""",
    )
    (bin_dir / "bash").symlink_to("/bin/bash")
    (bin_dir / "sh").symlink_to("/bin/sh")
    (bin_dir / "dirname").symlink_to("/bin/dirname")

    env = os.environ.copy()
    env["PATH"] = str(bin_dir)

    res = subprocess.run(
        [str(bin_dir / "bash"), str(TOGGLE_MENU_SCRIPT), "close"],
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )
    assert res.returncode == 0
    assert "ipc call menu close" in log_file.read_text(encoding="utf-8")


def test_toggle_menu_clipboard_action(tmp_path):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    log_file = tmp_path / "qs.log"

    _write_executable(
        bin_dir / "qs",
        f"""#!/usr/bin/env sh
echo "$*" >> "{log_file}"
""",
    )

    env = os.environ.copy()
    env["PATH"] = f"{bin_dir}:{env.get('PATH', '')}"

    res = subprocess.run(
        ["bash", str(TOGGLE_MENU_SCRIPT), "clipboard"],
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )
    assert res.returncode == 0
    assert "ipc call menu clipboard" in log_file.read_text(encoding="utf-8")


def test_clipboard_menu_script(tmp_path):
    clip_script = REPO_ROOT / "commands" / "clipboard-menu.sh"
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    log_file = tmp_path / "qs.log"

    _write_executable(
        bin_dir / "qs",
        f"""#!/usr/bin/env sh
echo "$*" >> "{log_file}"
""",
    )

    env = os.environ.copy()
    env["PATH"] = f"{bin_dir}:{env.get('PATH', '')}"

    res = subprocess.run(
        ["bash", str(clip_script)],
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )
    assert res.returncode == 0
    assert "ipc call menu clipboard" in log_file.read_text(encoding="utf-8")


def test_clipboard_manager_cli(tmp_path):
    mgr_script = REPO_ROOT / "src" / "app" / "scripts" / "clipboard" / "clipboard-manager.py"
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()

    _write_executable(
        bin_dir / "cliphist",
        """#!/usr/bin/env sh
if [ "$1" = "list" ]; then
    printf '101\\tHello World\\n102\\tSecond Item\\n'
elif [ "$1" = "decode" ]; then
    cat
fi
""",
    )
    _write_executable(
        bin_dir / "wl-copy",
        """#!/usr/bin/env sh
cat > /dev/null
""",
    )

    env = os.environ.copy()
    env["PATH"] = f"{bin_dir}:{env.get('PATH', '')}"

    res = subprocess.run(
        ["python3", str(mgr_script), "list"],
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )
    assert res.returncode == 0
    import json

    data = json.loads(res.stdout)
    assert len(data) == 2
    assert data[0]["name"] == "Hello World"
    assert data[0]["desc"] == "Item #101 · 11 chars"
    assert data[1]["name"] == "Second Item"
    assert data[1]["desc"] == "Item #102 · 11 chars"

    res_copy = subprocess.run(
        ["python3", str(mgr_script), "copy", "101\tHello World"],
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )
    assert res_copy.returncode == 0
