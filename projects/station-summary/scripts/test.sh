#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*"; FAIL=$((FAIL + 1)); }

echo "== station-summary — test suite =="
echo ""

# --- struttura ---
echo "-- struttura --"
for f in summary.py scripts/test.sh AGENTS.md CLAUDE.md \
          docs/ai/PROJECT_BRIEF.md docs/ai/ARCHITECTURE.md \
          docs/ai/TASKS.md docs/ai/DECISIONS.md \
          docs/ai/RUN_LOG.md docs/ai/REVIEW_LOG.md \
          .cursor/rules/project-rules.mdc; do
    if [ -f "$PROJECT_DIR/$f" ]; then
        ok "$f esiste"
    else
        fail "$f mancante"
    fi
done
echo ""

# --- py_compile ---
echo "-- py_compile --"
if python3 -m py_compile "$PROJECT_DIR/summary.py" 2>&1; then
    ok "summary.py compila senza errori"
else
    fail "summary.py errore di compilazione"
fi
echo ""

# --- help / version ---
echo "-- help / version --"
if python3 "$PROJECT_DIR/summary.py" --help > /dev/null 2>&1; then
    ok "--help esce con codice 0"
else
    fail "--help esce con codice non-zero"
fi

if python3 "$PROJECT_DIR/summary.py" --version > /dev/null 2>&1; then
    ok "--version esce con codice 0"
else
    fail "--version esce con codice non-zero"
fi
echo ""

# --- scan_projects / scan_scripts ---
echo "-- scan_projects / scan_scripts --"
STATION_DIR="$(cd "$PROJECT_DIR/../.." && pwd)"

if PYTHONPATH="$PROJECT_DIR" python3 -c "
from summary import scan_projects as f
r = f('$STATION_DIR')
assert isinstance(r, list) and len(r) > 0 and 'station-summary' in r
" 2>&1; then
    ok "scan_projects lista non vuota, contiene station-summary"
else
    fail "scan_projects fallito"
fi

if PYTHONPATH="$PROJECT_DIR" python3 -c "
from summary import scan_scripts as f
r = f('$STATION_DIR')
assert isinstance(r, list) and len(r) > 0 and all(n.endswith('.sh') for n in r)
" 2>&1; then
    ok "scan_scripts lista non vuota, solo file .sh"
else
    fail "scan_scripts fallito"
fi
echo ""

# --- shellcheck (opzionale) ---
echo "-- shellcheck (opzionale) --"
if command -v shellcheck > /dev/null 2>&1; then
    if shellcheck "$PROJECT_DIR/scripts/test.sh" 2>&1; then
        ok "shellcheck scripts/test.sh"
    else
        fail "shellcheck scripts/test.sh"
    fi
else
    echo "  SKIP: shellcheck non disponibile"
fi
echo ""

# --- shfmt (opzionale) ---
echo "-- shfmt (opzionale) --"
if command -v shfmt > /dev/null 2>&1; then
    if shfmt -d "$PROJECT_DIR/scripts/test.sh" 2>&1 | grep -q .; then
        fail "shfmt: differenze di formattazione in scripts/test.sh"
    else
        ok "shfmt scripts/test.sh"
    fi
else
    echo "  SKIP: shfmt non disponibile"
fi
echo ""

# --- riepilogo ---
echo "== Risultato: $PASS PASS, $FAIL FAIL =="
[ "$FAIL" -eq 0 ]
