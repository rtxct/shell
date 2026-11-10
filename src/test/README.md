# Test Suite Documentation (`src/test/`)

This repository separates testing into **two strictly isolated test groups**:
1. **Pipeline Tests (`src/test/pipeline/`)**: Automated, deterministic, headless, fast (< 3 seconds total), requiring zero Wayland compositor, GPU, or network access. Run automatically on every push in `.github/workflows/ci.yml` and via `make test` / `make test-pipeline`.
2. **Manual Tests (`src/test/manual/smoke/`)**: Launches the real `quickshell` binary against a Wayland display (or headless `sway` / `weston`), triggers a live reload, and verifies runtime logs against `allowed-warnings.txt`. Run manually by a developer via `make test-manual` (`make smoke`); **never** run in CI.

---

## Directory Structure

```
src/test/
├── README.md                                                     # This guide
├── pipeline/                                                     # Automated CI pipeline tests
│   ├── python/                                                   # Layer 1: Python, shell script & architecture tests
│   │   ├── conftest.py                                           # Shared pytest fixtures & temp storage helpers
│   │   ├── test_sticknote_storage.py                             # Unit & CLI tests for sticknote-storage.py (96% coverage)
│   │   ├── test_shell_scripts.py                                 # Mocked-PATH tests for poll-audio-state.sh & claim-notification-bus.sh
│   │   ├── test_*.py                                             # Feature, IPC, theme, and behavior tests
│   │   └── fixtures/                                             # Golden outputs, sample .ics, and Open-Meteo JSON
│   ├── config/                                                   # Layer 2: Config file JSON Schema & hot-reload validation
│   │   ├── test_config_files.py                                  # Positive, completeness, negative, and default-sync tests
│   │   ├── test_config_hot_reload_wiring.py                      # End-to-end FileView hot-reload wiring tests
│   │   └── schemas/*.schema.json                                 # Draft 2020-12 JSON Schemas for all 6 config/*.config.json files
│   ├── qml/                                                      # Layer 3: Headless Qt Quick Test component & theme suite
│   │   ├── run-qml-tests.sh                                      # Runner invoking QT_QPA_PLATFORM=offscreen qmltestrunner
│   │   ├── test_qml_no_color_literals.py                         # Static check enforcing zero color literals outside themes/
│   │   └── tst_*.qml                                             # Headless QML TestCase files for components, styles, and modules
│   └── lint/                                                     # Layer 4: Static analysis & formatting checks
│       ├── run-lint.sh                                           # Runs qmldir check, qmllint, qmlformat AST check, ruff, shellcheck
│       └── baseline/                                             # Justified pre-existing qmllint / qmlformat baselines
└── manual/                                                       # Manual developer tests (NEVER run in CI)
    └── smoke/
        ├── run-shell-smoke.sh                                    # Launches quickshell -p . with live reload & log inspection
        ├── allowed-warnings.txt                                  # Justified benign environment warnings
        └── README.md                                             # Detailed manual smoke test guide
```

---

## Running Tests

### Run All Pipeline Tests (Default)
```bash
make test
# or explicitly:
make test-pipeline
```

### Run Individual Pipeline Layers
```bash
make test-python      # Layer 1: Python & shell script unit tests (with coverage)
make test-config      # Layer 2: Config JSON Schema & hot-reload validation
make test-qml         # Layer 3: Headless Qt Quick Test (qmltestrunner) + zero color literal check
make lint             # Layer 4: qmldir/import check, qmllint, qmlformat, ruff, bash -n / shellcheck
```

### Run a Single Test File
```bash
# Single Python test file:
pytest src/test/pipeline/python/test_sticknote_storage.py

# Single QML TestCase file (headless):
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner \
  -import . -import themes -import src/app/styles -import src/app/components \
  -input src/test/pipeline/qml/tst_drop_and_strip.qml
```

### Run Manual Shell Smoke Test (Local Machine Only)
```bash
make test-manual
# or:
make smoke
```
See [`src/test/manual/smoke/README.md`](./manual/smoke/README.md) for full details.

---

## How to Add New Tests

1. **Adding a Python / Shell Script Test**:
   - Add a `test_<name>.py` file in `src/test/pipeline/python/` using fixtures from `conftest.py` (`tmp_path`, `fixtures_dir`).
   - Never touch `~/.cache/sticknote` or make live network/compositor calls; pass `storage_dir=tmp_path` or prepend a mock `bin/` directory to `PATH`.
2. **Adding a Config File & Schema**:
   - When adding `config/<domain>.config.json`, create `src/test/pipeline/config/schemas/<domain>.schema.json` and add default-value assertions in `src/test/pipeline/config/test_config_files.py`.
   - `test_every_config_has_matching_schema` will fail automatically if a config file is added without a schema.
3. **Adding a QML Component Test**:
   - Create `src/test/pipeline/qml/tst_<component>.qml` using `import QtQuick` and `import QtTest`.
   - `src/test/pipeline/qml/run-qml-tests.sh` automatically discovers and executes all `tst_*.qml` files with `QT_QPA_PLATFORM=offscreen`.
