#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "== ai-cycle-dogfood — test suite =="
echo ""

echo "-- py_compile --"
python3 -m py_compile "$PROJECT_DIR/dogfood.py" && echo "  PASS: dogfood.py compila"
python3 -m py_compile "$PROJECT_DIR/test_dogfood.py" && echo "  PASS: test_dogfood.py compila"
echo ""

echo "-- unittest --"
cd "$PROJECT_DIR"
python3 -m unittest test_dogfood -v
echo ""

echo "== Test completati =="
