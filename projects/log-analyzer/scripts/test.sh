#!/usr/bin/env bash
# Test per log-analyzer.
# Verifica struttura obbligatoria e comportamento base della CLI.
# Exit 0 se tutto è a posto, exit 1 se qualcosa fallisce.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

FAILURES=0

pass() { printf "PASS  %s\n" "$1"; }

skip() { printf "SKIP  %s\n" "$1"; }

fail() {
	printf "FAIL  %s\n" "$1" >&2
	FAILURES=$((FAILURES + 1))
}

check_file() {
	local rel="$1"
	if [[ -f "${PROJECT_ROOT}/${rel}" ]]; then
		pass "${rel}"
	else
		fail "${rel} — file mancante"
	fi
}

check_exit0() {
	local desc="$1"
	shift
	if "$@" >/dev/null 2>&1; then
		pass "${desc}"
	else
		fail "${desc} — exit code non zero"
	fi
}

echo "== Test: log-analyzer =="
echo ""

echo "-- Struttura e documentazione obbligatoria --"
check_file "AGENTS.md"
check_file "CLAUDE.md"
check_file ".cursor/rules/project-rules.mdc"
check_file "docs/ai/PROJECT_BRIEF.md"
check_file "docs/ai/ARCHITECTURE.md"
check_file "docs/ai/TASKS.md"
check_file "docs/ai/DECISIONS.md"
check_file "docs/ai/REVIEW_LOG.md"
check_file "docs/ai/RUN_LOG.md"
check_file "scripts/test.sh"
check_file "log_analyzer.py"

echo ""
echo "-- Sintassi Python --"
check_exit0 "log_analyzer.py (py_compile)" \
	python -m py_compile "${PROJECT_ROOT}/log_analyzer.py"

echo ""
echo "-- Comportamento CLI base --"
check_exit0 "log_analyzer.py --help" \
	python "${PROJECT_ROOT}/log_analyzer.py" --help

if python "${PROJECT_ROOT}/log_analyzer.py" --version 2>&1 | grep -q "log-analyzer 0.1.0"; then
	pass "log_analyzer.py --version"
else
	fail "log_analyzer.py --version"
fi

echo ""
echo "-- Parsing TASKS.md (TASK-002) --"
PROJECTS_DIR="$(cd "${PROJECT_ROOT}/.." && pwd)"
TASK002_OUT="$(python "${PROJECT_ROOT}/log_analyzer.py" \
	--projects-dir "${PROJECTS_DIR}" \
	--project log-analyzer 2>/dev/null || true)"

if echo "${TASK002_OUT}" | grep -q "Tasks:"; then
	pass "parse_tasks → output contiene Tasks:"
else
	fail "parse_tasks → output contiene Tasks:"
fi

if echo "${TASK002_OUT}" | grep -Eq "[1-9]+ completati"; then
	pass "parse_tasks → almeno 1 task completato"
else
	fail "parse_tasks → almeno 1 task completato"
fi

if echo "${TASK002_OUT}" | grep -q "0 in corso"; then
	pass "parse_tasks → 0 task in corso"
else
	fail "parse_tasks → 0 task in corso"
fi

if echo "${TASK002_OUT}" | grep -Eq "[0-9]+ backlog"; then
	pass "parse_tasks → output contiene contatore backlog"
else
	fail "parse_tasks → output contiene contatore backlog"
fi

echo ""
echo "-- Parsing RUN_LOG e REVIEW_LOG (TASK-003) --"
TMPPY="$(mktemp)"
cat >"${TMPPY}" <<'PYEOF'
import sys
sys.path.insert(0, sys.argv[1])
from log_analyzer import parse_last_run, parse_last_review
from pathlib import Path
run = parse_last_run(Path(sys.argv[2]))
review = parse_last_review(Path(sys.argv[3]))
print("run_task:" + (run.get("task", "") if run else ""))
print("run_esito:" + (run.get("esito_test", "") if run else ""))
print("review_esito:" + (review.get("esito", "") if review else ""))
missing = parse_last_run(Path("/tmp/nonexistent-log.md"))
print("missing_none:" + ("1" if missing is None else "0"))
PYEOF
TASK003_OUT="$(python3 "${TMPPY}" \
	"${PROJECT_ROOT}" \
	"${PROJECT_ROOT}/docs/ai/RUN_LOG.md" \
	"${PROJECT_ROOT}/docs/ai/REVIEW_LOG.md" 2>/dev/null || true)"
rm -f "${TMPPY}"

if echo "${TASK003_OUT}" | grep -q "run_task:TASK-"; then
	pass "parse_last_run → estrae task ID"
else
	fail "parse_last_run → estrae task ID"
fi

if echo "${TASK003_OUT}" | grep -qi "run_esito:PASS\|run_esito:FAIL"; then
	pass "parse_last_run → estrae esito test"
else
	fail "parse_last_run → estrae esito test"
fi

if echo "${TASK003_OUT}" | grep -q "review_esito:Approvato"; then
	pass "parse_last_review → estrae esito review"
else
	fail "parse_last_review → estrae esito review"
fi

if echo "${TASK003_OUT}" | grep -q "missing_none:1"; then
	pass "parse_last_run → file mancante → None"
else
	fail "parse_last_run → file mancante → None"
fi

echo ""
echo "-- Scanning e output CLI (TASK-004) --"
PROJECTS_DIR="$(cd "${PROJECT_ROOT}/.." && pwd)"
TASK004_OUT="$(python "${PROJECT_ROOT}/log_analyzer.py" \
	--projects-dir "${PROJECTS_DIR}" \
	--project log-analyzer 2>/dev/null || true)"

if echo "${TASK004_OUT}" | grep -q "^== log-analyzer =="; then
	pass "output CLI → header progetto"
else
	fail "output CLI → header progetto"
fi

if echo "${TASK004_OUT}" | grep -q "Ultimo run:"; then
	pass "output CLI → contiene Ultimo run"
else
	fail "output CLI → contiene Ultimo run"
fi

if echo "${TASK004_OUT}" | grep -q "Ultima review:"; then
	pass "output CLI → contiene Ultima review"
else
	fail "output CLI → contiene Ultima review"
fi

MULTI_OUT="$(python "${PROJECT_ROOT}/log_analyzer.py" \
	--projects-dir "${PROJECTS_DIR}" 2>/dev/null || true)"

if echo "${MULTI_OUT}" | grep -c "^== " | grep -q "[2-9]"; then
	pass "scanning multi-progetto → almeno 2 progetti trovati"
else
	fail "scanning multi-progetto → almeno 2 progetti trovati"
fi

OUTPUT_TMP="$(mktemp)"
python "${PROJECT_ROOT}/log_analyzer.py" \
	--projects-dir "${PROJECTS_DIR}" \
	--project log-analyzer \
	--output "${OUTPUT_TMP}" >/dev/null 2>&1 || true
if [[ -s "${OUTPUT_TMP}" ]]; then
	pass "--output FILE → file scritto"
else
	fail "--output FILE → file scritto"
fi
rm -f "${OUTPUT_TMP}"

echo ""
echo "-- Qualità script bash --"
if command -v shellcheck >/dev/null 2>&1; then
	if shellcheck "${PROJECT_ROOT}/scripts/test.sh" >/dev/null 2>&1; then
		pass "scripts/test.sh (shellcheck)"
	else
		fail "scripts/test.sh (shellcheck)"
	fi
else
	skip "scripts/test.sh (shellcheck) — shellcheck non disponibile"
fi

if command -v shfmt >/dev/null 2>&1; then
	if diff -u <(cat "${PROJECT_ROOT}/scripts/test.sh") \
		<(shfmt "${PROJECT_ROOT}/scripts/test.sh") >/dev/null 2>&1; then
		pass "scripts/test.sh (shfmt)"
	else
		fail "scripts/test.sh (shfmt)"
	fi
else
	skip "scripts/test.sh (shfmt) — shfmt non disponibile"
fi

echo ""
if [[ "${FAILURES}" -eq 0 ]]; then
	echo "Tutti i controlli passati."
	exit 0
else
	printf "Falliti: %d controllo/i.\n" "${FAILURES}" >&2
	exit 1
fi
