"""Regression test: iPhone glass theme creation, preservation of default theme, and qmldir wiring."""

from __future__ import annotations

import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[4]
THEME_DIR = REPO_ROOT / "themes"
TEMPLATE_THEME = THEME_DIR / "template-theme.style.qml"
LEGACY_DEFAULT_THEME = THEME_DIR / "theme.style.qml"
GLASS_THEME = THEME_DIR / "glass-theme.style.qml"
QMLDIR = THEME_DIR / "qmldir"


def test_both_themes_exist_and_original_not_deleted():
    assert not LEGACY_DEFAULT_THEME.exists(), "Legacy theme.style.qml must be removed"
    assert TEMPLATE_THEME.is_file(), "template-theme.style.qml must exist"
    assert GLASS_THEME.is_file(), "New glass-theme.style.qml must exist"


def test_qmldir_registers_both_themes_and_applies_glass():
    content = QMLDIR.read_text(encoding="utf-8")
    lines = [line.strip() for line in content.splitlines() if line.strip() and not line.startswith("#")]

    # Theme must point to glass-theme.style.qml
    assert any(re.match(r"^singleton\s+Theme\s+1\.0\s+glass-theme\.style\.qml$", line) for line in lines), (
        "Theme singleton must be applied to glass-theme.style.qml"
    )

    # DefaultTheme must be removed and TemplateTheme must be registered in qmldir
    assert not any(re.search(r"\bDefaultTheme\b", line) for line in lines), (
        "DefaultTheme singleton must be removed from qmldir"
    )
    assert any(re.match(r"^singleton\s+TemplateTheme\s+1\.0\s+template-theme\.style\.qml$", line) for line in lines), (
        "TemplateTheme singleton must point to template-theme.style.qml in qmldir"
    )

    # GlassTheme must also be explicitly registered
    assert any(re.match(r"^singleton\s+GlassTheme\s+1\.0\s+glass-theme\.style\.qml$", line) for line in lines), (
        "GlassTheme singleton must be registered in qmldir"
    )


def test_glass_and_template_theme_token_parity_and_style_coverage():
    def extract_props(file_path: Path) -> set[str]:
        content = file_path.read_text(encoding="utf-8")
        props = set()
        for line in content.splitlines():
            line_code = line.split("//", 1)[0].strip()
            m = re.search(r"property\s+(?:color|real|int|string|var)\s+(\w+)\s*:", line_code)
            if m:
                props.add(m.group(1))
        return props

    template_props = extract_props(TEMPLATE_THEME)
    glass_props = extract_props(GLASS_THEME)

    assert template_props == glass_props, (
        f"Theme token mismatch: only_in_template={template_props - glass_props}, "
        f"only_in_glass={glass_props - template_props}"
    )

    styles_dir = REPO_ROOT / "src" / "app" / "styles"
    referenced_tokens = set()
    for style_file in styles_dir.glob("*.style.qml"):
        for m in re.finditer(r"\bTheme\.(\w+)\b", style_file.read_text(encoding="utf-8")):
            referenced_tokens.add(m.group(1))

    missing_in_themes = referenced_tokens - glass_props
    assert missing_in_themes == set(), f"Missing Theme tokens referenced by styles: {missing_in_themes}"


def test_glass_theme_uses_translucent_fills_and_specular_borders():
    content = GLASS_THEME.read_text(encoding="utf-8")

    # Background fills must be translucent Qt.rgba with alpha < 1.0
    assert re.search(r"backgroundPrimary:\s*Qt\.rgba\([^)]+,\s*0\.\d+\)", content), (
        "backgroundPrimary must have alpha < 1.0"
    )
    assert re.search(r"backgroundBlack:\s*Qt\.rgba\([^)]+,\s*0\.\d+\)", content), (
        "backgroundBlack must have alpha < 1.0"
    )
    assert re.search(r"borderWhite:\s*Qt\.rgba\([^)]+,\s*0\.\d+\)", content), (
        "borderWhite must be a translucent specular rim"
    )
    for token in (
        "glassSheenTop",
        "glassSheenMid",
        "glassSheenCore",
        "glassSheenBottom",
        "glassInnerBevel",
        "glassRimHighlight",
    ):
        assert re.search(rf"{token}:\s*Qt\.rgba\([^)]+,\s*0\.\d+\)", content), (
            f"GlassTheme {token} must be a non-zero translucent optical layer"
        )


def test_drop_renders_multistop_liquid_glass_shader_and_inner_bevel():
    drop_qml = (REPO_ROOT / "src" / "app" / "components" / "drop.component.qml").read_text(encoding="utf-8")
    assert "LinearGradient" in drop_qml, "Drop must render a LinearGradient specular sheen pass"
    assert "DropStyle.glassSheenTop" in drop_qml
    assert "DropStyle.glassSheenBottom" in drop_qml
    assert "DropStyle.glassInnerBevel" in drop_qml
    assert "DropStyle.bevelStrokeWidth" in drop_qml


def test_glass_theme_monochrome_black_surfaces():
    content = GLASS_THEME.read_text(encoding="utf-8")
    assert re.search(
        r"backgroundPrimary:\s*Qt\.rgba\(0(?:\.0+)?,\s*0(?:\.0+)?,\s*0(?:\.0+)?,\s*0\.\d+\)",
        content,
    ), "GlassTheme backgroundPrimary must be neutral translucent black glass"
    assert re.search(
        r"backgroundBlack:\s*Qt\.rgba\(0(?:\.0+)?,\s*0(?:\.0+)?,\s*0(?:\.0+)?,\s*0\.\d+\)",
        content,
    ), "GlassTheme backgroundBlack must be neutral translucent black glass"
    assert re.search(r'accent:\s*"#ffffff"', content), "GlassTheme accent must be high-contrast monochrome white"
    assert re.search(r'textOnAccent:\s*"#000000"', content), (
        "GlassTheme textOnAccent must be black for contrast against white accent"
    )
