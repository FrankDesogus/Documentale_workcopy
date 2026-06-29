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

if echo "${TASK002_OUT}" | grep -Eq "[1-9]+ backlog"; then
	pass "parse_tasks → almeno 1 task in backlog"
else
	fail "parse_tasks → almeno 1 task in backlog"
fi

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
