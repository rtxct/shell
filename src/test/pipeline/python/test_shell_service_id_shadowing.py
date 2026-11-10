"""
Regression test: shell.qml must pass the shared service instances into each Bar.

Bug fixed:
    shell.qml declared `Weather { id: weather }` (and events, workspaces, audio,
    sticknotes, notifications the same way) and then wired `Bar { weather: weather }`.
    Inside the Bar object the right-hand side `weather` resolves to Bar's OWN
    `weather` property (null), not to the service id, so every bar received null for
    all six services. Visible symptom: the weather card/view showed nothing.

    Fix: service ids use a distinct `*Svc` suffix (`weatherSvc`, ...), so no Bar
    property binding can be a self-reference.
"""

import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]
SHELL_QML = REPO_ROOT / "shell.qml"

SERVICE_PROPS = [
    "weather",
    "events",
    "workspaces",
    "audio",
    "sticknotes",
    "notifications",
]


def _bar_block(text: str) -> str:
    match = re.search(r"^\s*Bar\s*\{(.*?)\}", text, re.DOTALL | re.MULTILINE)
    assert match, "shell.qml must instantiate a Bar { ... } block"
    return match.group(1)


def test_bar_service_bindings_are_not_self_references():
    """`Bar { x: x }` binds a property to itself; the RHS must be a different identifier."""
    bindings = dict(
        re.findall(
            r"^\s*(\w+)\s*:\s*(\w+)\s*$",
            _bar_block(SHELL_QML.read_text()),
            re.MULTILINE,
        )
    )
    for prop in SERVICE_PROPS:
        assert prop in bindings, f"Bar must receive `{prop}` from shell.qml"
        assert bindings[prop] != prop, (
            f"Bar binding `{prop}: {bindings[prop]}` resolves to Bar's own property (null); "
            f"use a distinct service id such as `{prop}Svc`"
        )


def test_bar_service_bindings_reference_declared_ids():
    """Every identifier passed into Bar must be an id declared in shell.qml."""
    text = SHELL_QML.read_text()
    declared_ids = set(re.findall(r"\bid\s*:\s*(\w+)", text))
    bindings = dict(re.findall(r"^\s*(\w+)\s*:\s*(\w+)\s*$", _bar_block(text), re.MULTILINE))
    for prop in SERVICE_PROPS:
        assert bindings[prop] in declared_ids, (
            f"Bar binding `{prop}: {bindings[prop]}` does not reference a declared service id"
        )
