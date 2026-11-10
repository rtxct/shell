"""Static verification that zero color literals exist outside theme/theme.style.qml."""

from __future__ import annotations

import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]
SCAN_TARGETS = [
    REPO_ROOT / "shell.qml",
    REPO_ROOT / "src" / "app" / "styles",
    REPO_ROOT / "src" / "app" / "components",
    REPO_ROOT / "src" / "app" / "modules",
]

HEX_RE = re.compile(r"#[0-9a-fA-F]{3,8}\b")
RGBA_RE = re.compile(r"Qt\.(?:rgba|hsla|hsva)\s*\(")
NAMED_COLOR_RE = re.compile(r'color\s*:\s*"(?:transparent|black|white|[a-zA-Z]+)"')


def collect_qml_files() -> list[Path]:
    files: list[Path] = []
    for target in SCAN_TARGETS:
        if target.is_file():
            files.append(target)
        elif target.is_dir():
            files.extend(sorted(target.rglob("*.qml")))
    return files


def scan_file_for_color_literals(path: Path) -> list[str]:
    violations: list[str] = []
    for lineno, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        # Strip line comments before matching so documentation comments don't false-positive
        code_part = raw_line.split("//", 1)[0]
        if HEX_RE.search(code_part) or RGBA_RE.search(code_part) or NAMED_COLOR_RE.search(code_part):
            rel = path.relative_to(REPO_ROOT)
            violations.append(f"{rel}:{lineno}: {raw_line.strip()}")
    return violations


def test_no_hardcoded_color_literals_outside_theme():
    all_violations: list[str] = []
    for qml_file in collect_qml_files():
        all_violations.extend(scan_file_for_color_literals(qml_file))
    assert all_violations == [], "Hard-coded color literals found outside theme/theme.style.qml:\n" + "\n".join(
        all_violations
    )


def test_color_scanner_detects_violations(tmp_path: Path):
    bad_file = tmp_path / "bad.component.qml"
    bad_file.write_text(
        'Rectangle { color: "#ff00aa"; border.color: Qt.rgba(1, 0, 0, 0.5) }\n',
        encoding="utf-8",
    )
    # Temporarily scan bad_file directly
    violations = []
    for lineno, raw_line in enumerate(bad_file.read_text(encoding="utf-8").splitlines(), start=1):
        code_part = raw_line.split("//", 1)[0]
        if HEX_RE.search(code_part) or RGBA_RE.search(code_part) or NAMED_COLOR_RE.search(code_part):
            violations.append(f"bad.component.qml:{lineno}")
    assert len(violations) == 1


def test_all_style_singleton_properties_are_used():
    """Verify every property declared in styles/*.style.qml is referenced in components/ or modules/."""
    styles_dir = REPO_ROOT / "src" / "app" / "styles"
    qmldir_text = (styles_dir / "qmldir").read_text(encoding="utf-8")

    singleton_map: dict[str, Path] = {}
    for line in qmldir_text.splitlines():
        parts = line.strip().split()
        if len(parts) == 4 and parts[0] == "singleton":
            singleton_map[parts[1]] = styles_dir / parts[3]

    consumer_files = sorted((REPO_ROOT / "src" / "app" / "components").rglob("*.qml")) + sorted(
        (REPO_ROOT / "src" / "app" / "modules").rglob("*.qml")
    )
    consumer_corpus = "\n".join(f.read_text(encoding="utf-8") for f in consumer_files)

    prop_re = re.compile(r"property\s+\w+\s+(\w+)\s*:")
    unused: list[str] = []

    for singleton_name, style_file in sorted(singleton_map.items()):
        for lineno, raw_line in enumerate(style_file.read_text(encoding="utf-8").splitlines(), start=1):
            code_part = raw_line.split("//", 1)[0]
            match = prop_re.search(code_part)
            if match:
                prop_name = match.group(1)
                token = f"{singleton_name}.{prop_name}"
                if not re.search(rf"\b{re.escape(token)}\b", consumer_corpus):
                    rel = style_file.relative_to(REPO_ROOT)
                    unused.append(f"{rel}:{lineno}: {token} is never referenced")

    assert unused == [], "Unused style properties found in styles/*.style.qml:\n" + "\n".join(unused)


def test_components_and_modules_use_style_singletons_not_theme_directly():
    """Verify components/ and modules/ read colors from *Style singletons rather than Theme.* directly."""
    consumer_files = sorted((REPO_ROOT / "src" / "app" / "components").rglob("*.qml")) + sorted(
        (REPO_ROOT / "src" / "app" / "modules").rglob("*.qml")
    )
    theme_ref_re = re.compile(r"\bTheme\.\w+")
    violations: list[str] = []

    for qml_file in consumer_files:
        if qml_file.name == "bar.module.qml":
            continue
        for lineno, raw_line in enumerate(qml_file.read_text(encoding="utf-8").splitlines(), start=1):
            code_part = raw_line.split("//", 1)[0]
            if theme_ref_re.search(code_part):
                rel = qml_file.relative_to(REPO_ROOT)
                violations.append(f"{rel}:{lineno}: {raw_line.strip()}")

    assert violations == [], (
        "Direct Theme.* references found in components/ or modules/ (use the component/module *Style singleton instead):\n"
        + "\n".join(violations)
    )
