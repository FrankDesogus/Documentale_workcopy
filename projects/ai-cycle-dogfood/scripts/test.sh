#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# python3 non è garantito sul PATH su Windows (solo "python", es. via venv
# Scripts/py launcher): usarlo come fallback, invariato su Linux/macOS.
PYTHON=python3
command -v python3 >/dev/null 2>&1 || PYTHON=python

echo "== ai-cycle-dogfood — test suite =="
echo ""

echo "-- py_compile --"
"$PYTHON" -m py_compile "$PROJECT_DIR/dogfood.py" && echo "  PASS: dogfood.py compila"
"$PYTHON" -m py_compile "$PROJECT_DIR/test_dogfood.py" && echo "  PASS: test_dogfood.py compila"
echo ""

echo "-- unittest --"
cd "$PROJECT_DIR"
"$PYTHON" -m unittest test_dogfood -v
echo ""

echo "== Test completati =="
