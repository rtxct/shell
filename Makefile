.PHONY: test test-pipeline test-python test-config test-qml lint test-manual smoke

PYTEST := $(shell if command -v pytest >/dev/null 2>&1; then command -v pytest; elif [ -x .venv/bin/pytest ]; then echo .venv/bin/pytest; else echo pytest; fi)

# Default target: runs ONLY automated pipeline tests (never runs test-manual)
test: test-pipeline

test-pipeline: test-python test-config test-qml lint

test-python:
	@echo "==> [Pipeline] Running Python & script unit tests..."
	"$(PYTEST)" src/test/pipeline/python --cov=src/app/scripts/sticknotes --cov-report=term-missing

test-config:
	@echo "==> [Pipeline] Running JSON Schema config validation tests..."
	"$(PYTEST)" src/test/pipeline/config

test-qml:
	@echo "==> [Pipeline] Running headless QML component & theme tests..."
	./src/test/pipeline/qml/run-qml-tests.sh

lint:
	@echo "==> [Pipeline] Running static linters & format checks..."
	./src/test/pipeline/lint/run-lint.sh

# Manual target (run by a human on their own machine; NEVER invoked by `make test` or CI)
test-manual:
	@echo "==> [Manual] Running Quickshell headless/session smoke test..."
	./src/test/manual/smoke/run-shell-smoke.sh

smoke: test-manual
