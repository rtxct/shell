#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
BASELINE_FILE="${SCRIPT_DIR}/baseline/qmllint-baseline.txt"

cd "$REPO_ROOT"

# 1. Verify qmldir registrations and local import paths in all QML files
echo "==> [1/5] Verifying qmldir registrations and QML import paths"
python3 - <<'PY'
from pathlib import Path
import re
import sys

repo = Path.cwd()
errors = []

# Check qmldir completeness in theme, styles, components, modules
for folder_name in ("themes", "src/app/styles", "src/app/components", "src/app/modules"):
    folder = repo / folder_name
    qmldir = folder / "qmldir"
    if not qmldir.is_file():
        errors.append(f"Missing qmldir in {folder_name}/")
        continue
    registered_files = set()
    for line in qmldir.read_text(encoding="utf-8").splitlines():
        parts = line.strip().split()
        if not parts or parts[0].startswith("#"):
            continue
        target_file = parts[-1]
        registered_files.add(target_file)
        if not (folder / target_file).is_file():
            errors.append(f"{folder_name}/qmldir references non-existent file '{target_file}'")
    for qml_file in sorted(folder.glob("*.qml")):
        if qml_file.name not in registered_files:
            errors.append(f"{folder_name}/{qml_file.name} is not registered in {folder_name}/qmldir")

# Check relative directory and JS imports in all QML files
import_re = re.compile(r'^\s*import\s+"([^"]+)"')
all_qml = [repo / "shell.qml"]
for d in ("themes", "src/app/styles", "src/app/components", "src/app/modules", "src/test/pipeline/qml"):
    p = repo / d
    if p.is_dir():
        all_qml.extend(sorted(p.rglob("*.qml")))

for qml_path in all_qml:
    for lineno, line in enumerate(qml_path.read_text(encoding="utf-8").splitlines(), start=1):
        code = line.split("//", 1)[0]
        m = import_re.match(code)
        if m:
            rel_target = m.group(1)
            resolved = (qml_path.parent / rel_target).resolve()
            if not resolved.exists():
                errors.append(f"{qml_path.relative_to(repo)}:{lineno}: broken import path \"{rel_target}\"")

if errors:
    for err in errors:
        print(f"ERROR: {err}", file=sys.stderr)
    sys.exit(1)
PY

# 2. Run qmllint with -I themes -I src/app/components -I src/app/styles -I src/app/modules
QMLLINT_BIN=""
for candidate in \
    "${QMLLINT:-}" \
    "/usr/lib/qt6/bin/qmllint" \
    "/usr/lib64/qt6/bin/qmllint" \
    "$(command -v qmllint6 2>/dev/null || true)" \
    "$(command -v qmllint 2>/dev/null || true)"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
        QMLLINT_BIN="$candidate"
        break
    fi
done

if [ -n "$QMLLINT_BIN" ]; then
    echo "==> [2/5] Running qmllint (${QMLLINT_BIN})"
    shopt -s nullglob
    QML_FILES=(shell.qml themes/*.qml src/app/styles/*.qml src/app/components/*.qml src/app/modules/*.qml src/test/pipeline/qml/*.qml)
    shopt -u nullglob
    QMLLINT_OUT="$(mktemp)"
    trap 'rm -f "$QMLLINT_OUT"' EXIT

    if ! "$QMLLINT_BIN" -I themes -I src/app/components -I src/app/styles -I src/app/modules "${QML_FILES[@]}" >"$QMLLINT_OUT" 2>&1; then
        cat "$QMLLINT_OUT" >&2
        echo "ERROR: qmllint failed with syntax or compile errors." >&2
        exit 1
    fi

    # Filter Warning: lines against baseline regexes
    python3 - "$QMLLINT_OUT" "$BASELINE_FILE" <<'PY'
from pathlib import Path
import re
import sys

out_text = Path(sys.argv[1]).read_text(encoding="utf-8")
baseline_lines = Path(sys.argv[2]).read_text(encoding="utf-8").splitlines()
patterns = [
    re.compile(line.strip())
    for line in baseline_lines
    if line.strip() and not line.strip().startswith("#")
]

unexpected = []
for line in out_text.splitlines():
    if line.startswith("Warning:"):
        if not any(p.search(line) for p in patterns):
            unexpected.append(line)

if unexpected:
    print("ERROR: Unexpected qmllint warnings not in baseline:", file=sys.stderr)
    for w in unexpected:
        print("  " + w, file=sys.stderr)
    sys.exit(1)
PY
else
    echo "SKIP: [2/5] qmllint not found (install qt6-declarative)."
fi

# 3. Run qmlformat AST/format check
QMLFORMAT_BIN=""
for candidate in \
    "${QMLFORMAT:-}" \
    "/usr/lib/qt6/bin/qmlformat" \
    "/usr/lib64/qt6/bin/qmlformat" \
    "$(command -v qmlformat6 2>/dev/null || true)" \
    "$(command -v qmlformat 2>/dev/null || true)"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
        QMLFORMAT_BIN="$candidate"
        break
    fi
done

if [ -n "$QMLFORMAT_BIN" ]; then
    echo "==> [3/5] Verifying QML AST formatting compatibility (${QMLFORMAT_BIN})"
    for qf in "${QML_FILES[@]}"; do
        "$QMLFORMAT_BIN" "$qf" >/dev/null
    done
else
    echo "SKIP: [3/5] qmlformat not found (install qt6-declarative)."
fi

# 4. Run Python linters (ruff check + ruff format --check)
RUFF_BIN=""
for candidate in \
    "${RUFF:-}" \
    "$(command -v ruff 2>/dev/null || true)" \
    "${REPO_ROOT}/.venv/bin/ruff"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
        RUFF_BIN="$candidate"
        break
    fi
done

if [ -n "$RUFF_BIN" ]; then
    echo "==> [4/5] Running ruff check and ruff format --check"
    "$RUFF_BIN" check src/app/scripts/ src/test/
    "$RUFF_BIN" format --check src/app/scripts/ src/test/
else
    echo "SKIP: [4/5] ruff not found (install via: pip install ruff or pacman -S ruff)."
fi

# 5. Run shell syntax check + shellcheck
echo "==> [5/5] Checking shell scripts"
mapfile -t SH_FILES < <(find install.sh commands src/app/scripts src/test -type f -name "*.sh" | sort)
for shf in "${SH_FILES[@]}"; do
    bash -n "$shf"
done

if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "${SH_FILES[@]}"
else
    echo "SKIP: shellcheck is not installed (install via: sudo pacman -S shellcheck); bash -n syntax check passed for ${#SH_FILES[@]} scripts."
fi

echo "==> All static lint checks passed."
