#!/usr/bin/env bash
# Test per cursor-prompt-builder.
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

check_output() {
	local desc="$1"
	local expected="$2"
	local actual="$3"
	if [[ "${actual}" == "${expected}" ]]; then
		pass "${desc}"
	else
		fail "${desc} — atteso: '${expected}' — ottenuto: '${actual}'"
	fi
}

echo "== Test: cursor-prompt-builder =="
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
check_file "prompt_builder.py"

echo ""
echo "-- Sintassi Python --"
check_exit0 "prompt_builder.py (py_compile)" \
	python -m py_compile "${PROJECT_ROOT}/prompt_builder.py"

echo ""
echo "-- Comportamento CLI base --"
check_output "prompt_builder.py --version" \
	"cursor-prompt-builder 0.1.0" \
	"$(python "${PROJECT_ROOT}/prompt_builder.py" --version)"

check_exit0 "prompt_builder.py --help" \
	python "${PROJECT_ROOT}/prompt_builder.py" --help

echo ""
echo "-- Parsing task da TASKS.md --"
TASKS_FILE="${PROJECT_ROOT}/docs/ai/TASKS.md"

if python "${PROJECT_ROOT}/prompt_builder.py" \
	--tasks-file "${TASKS_FILE}" --task TASK-002 \
	2>/dev/null | grep -q "TASK-002"; then
	pass "parsing TASK-002 → output contiene ID"
else
	fail "parsing TASK-002 → output contiene ID"
fi

if python "${PROJECT_ROOT}/prompt_builder.py" \
	--tasks-file "${TASKS_FILE}" --task TASK-002 \
	2>/dev/null | grep -q "Cursor Agent"; then
	pass "parsing TASK-002 → output contiene agente"
else
	fail "parsing TASK-002 → output contiene agente"
fi

if python "${PROJECT_ROOT}/prompt_builder.py" \
	--tasks-file "${TASKS_FILE}" --task TASK-003 \
	2>/dev/null | grep -q "Cursor Agent"; then
	pass "parsing TASK-003 (riga non prima) → agente estratto"
else
	fail "parsing TASK-003 (riga non prima) → agente estratto"
fi

if python "${PROJECT_ROOT}/prompt_builder.py" \
	--tasks-file "${TASKS_FILE}" --task TASK-001 \
	2>/dev/null | grep -q "fda3d5b"; then
	pass "parsing TASK-001 (Completati) → commit estratto"
else
	fail "parsing TASK-001 (Completati) → commit estratto"
fi

if (python "${PROJECT_ROOT}/prompt_builder.py" \
	--tasks-file "${TASKS_FILE}" --task TASK-999 \
	>/dev/null 2>&1); then
	fail "task non trovato → exit 1"
else
	pass "task non trovato → exit 1"
fi

if (python "${PROJECT_ROOT}/prompt_builder.py" \
	--tasks-file "/tmp/nonexistent-tasks.md" --task TASK-002 \
	>/dev/null 2>&1); then
	fail "file non trovato → exit 1"
else
	pass "file non trovato → exit 1"
fi

echo ""
echo "-- Generazione prompt TASK-003 --"
TASK003_OUTPUT="$(python "${PROJECT_ROOT}/prompt_builder.py" \
	--tasks-file "${TASKS_FILE}" --task TASK-003 2>/dev/null || true)"

if [[ -n "${TASK003_OUTPUT}" ]]; then
	pass "TASK-003 → output su stdout"
else
	fail "TASK-003 → output su stdout"
fi

if echo "${TASK003_OUTPUT}" | grep -q "Cursor Agent"; then
	pass "TASK-003 → output contiene Cursor Agent"
else
	fail "TASK-003 → output contiene Cursor Agent"
fi

if echo "${TASK003_OUTPUT}" | grep -q "TASK-003"; then
	pass "TASK-003 → output contiene TASK-003"
else
	fail "TASK-003 → output contiene TASK-003"
fi

if echo "${TASK003_OUTPUT}" | grep -q "Generazione prompt Cursor base"; then
	pass "TASK-003 → output contiene titolo task"
else
	fail "TASK-003 → output contiene titolo task"
fi

if echo "${TASK003_OUTPUT}" | grep -Eiq "no push"; then
	pass "TASK-003 → output contiene guardrail no push"
else
	fail "TASK-003 → output contiene guardrail no push"
fi

if echo "${TASK003_OUTPUT}" | grep -q "\[prompt generation not yet implemented\]"; then
	fail "TASK-003 → output non contiene placeholder"
else
	pass "TASK-003 → output non contiene placeholder"
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
