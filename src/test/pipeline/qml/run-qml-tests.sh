#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

# Locate Qt6 qmltestrunner (Arch Linux /usr/bin/qmltestrunner is symlinked to qt5; Qt6 lives in /usr/lib/qt6/bin/qmltestrunner)
QMLTESTRUNNER=""
for candidate in \
    "${QMLTESTRUNNER_BIN:-}" \
    "/usr/lib/qt6/bin/qmltestrunner" \
    "/usr/lib64/qt6/bin/qmltestrunner" \
    "$(command -v qmltestrunner6 2>/dev/null || true)" \
    "$(command -v qmltestrunner 2>/dev/null || true)"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
        QMLTESTRUNNER="$candidate"
        break
    fi
done

if [ -z "$QMLTESTRUNNER" ]; then
    echo "SKIP: qmltestrunner not found. Install 'qt6-declarative' on Arch Linux (provides /usr/lib/qt6/bin/qmltestrunner)."
    exit 0
fi

# Locate pytest for static color-literal check
PYTEST_BIN=""
for candidate in \
    "${PYTEST:-}" \
    "$(command -v pytest 2>/dev/null || true)" \
    "${REPO_ROOT}/.venv/bin/pytest"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
        PYTEST_BIN="$candidate"
        break
    fi
done

echo "==> Running Qt Quick Test suite via ${QMLTESTRUNNER} (QT_QPA_PLATFORM=offscreen)"
for tst_file in "${SCRIPT_DIR}"/tst_*.qml; do
    echo "  -> $(basename "$tst_file")"
    QT_QPA_PLATFORM=offscreen "$QMLTESTRUNNER" \
        -import "${REPO_ROOT}" \
        -import "${REPO_ROOT}/themes" \
        -import "${REPO_ROOT}/src/app/styles" \
        -import "${REPO_ROOT}/src/app/components" \
        -input "$tst_file"
done

if [ -n "$PYTEST_BIN" ]; then
    echo "==> Running static QML color-literal verification"
    "$PYTEST_BIN" -q "${SCRIPT_DIR}/test_qml_no_color_literals.py"
fi

echo "==> All QML component & theme tests passed."
