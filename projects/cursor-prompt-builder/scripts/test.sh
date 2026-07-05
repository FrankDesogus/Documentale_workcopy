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
echo "-- Opzioni CLI e output su file (TASK-004) --"
OUTPUT_TMP="$(mktemp)"
OUTPUT_STDOUT="$(python "${PROJECT_ROOT}/prompt_builder.py" \
	--tasks-file "${TASKS_FILE}" --task TASK-004 \
	--output "${OUTPUT_TMP}" 2>/dev/null || true)"

if [[ -f "${OUTPUT_TMP}" ]]; then
	pass "--output → crea il file"
else
	fail "--output → crea il file"
fi

if grep -q "Cursor Agent" "${OUTPUT_TMP}"; then
	pass "--output → file contiene Cursor Agent"
else
	fail "--output → file contiene Cursor Agent"
fi

if grep -q "TASK-004" "${OUTPUT_TMP}"; then
	pass "--output → file contiene task ID"
else
	fail "--output → file contiene task ID"
fi

if echo "${OUTPUT_STDOUT}" | grep -qi "prompt written to"; then
	pass "--output → stdout contiene messaggio di conferma"
else
	fail "--output → stdout contiene messaggio di conferma"
fi

if ! echo "${OUTPUT_STDOUT}" | grep -q "Cursor Agent"; then
	pass "--output → stdout non contiene il prompt completo"
else
	fail "--output → stdout non contiene il prompt completo"
fi

rm -f "${OUTPUT_TMP}"

if python "${PROJECT_ROOT}/prompt_builder.py" \
	--project "${PROJECT_ROOT}" --task TASK-004 \
	2>/dev/null | grep -q "TASK-004"; then
	pass "--project → risolve docs/ai/TASKS.md"
else
	fail "--project → risolve docs/ai/TASKS.md"
fi

if python "${PROJECT_ROOT}/prompt_builder.py" \
	--tasks-file "${TASKS_FILE}" --task TASK-004 \
	2>/dev/null | grep -q "Output su file"; then
	pass "--tasks-file → legge TASKS.md direttamente"
else
	fail "--tasks-file → legge TASKS.md direttamente"
fi

if (python "${PROJECT_ROOT}/prompt_builder.py" \
	--tasks-file "${TASKS_FILE}" --task TASK-004 \
	--output "${PROJECT_ROOT}" \
	>/dev/null 2>&1); then
	fail "output non scrivibile → exit 1"
else
	pass "output non scrivibile → exit 1"
fi

echo ""
echo "-- Dettaglio task (extract_task_detail) --"
# usa station-summary TASKS.md (ha sezioni ### TASK-XXX)
STATION_TASKS="${PROJECT_ROOT}/../station-summary/docs/ai/TASKS.md"
# usa log-analyzer TASKS.md (NON ha sezioni ### TASK-XXX)
LOG_TASKS="${PROJECT_ROOT}/../log-analyzer/docs/ai/TASKS.md"

# task con sezione dettaglio: output deve contenere "Dettaglio completo"
if python "${PROJECT_ROOT}/prompt_builder.py" \
	--tasks-file "${STATION_TASKS}" --task TASK-001 \
	2>/dev/null | grep -q "Dettaglio completo del task"; then
	pass "TASKS.md con dettaglio → prompt contiene sezione dettaglio"
else
	fail "TASKS.md con dettaglio → prompt contiene sezione dettaglio"
fi

# task con sezione dettaglio: il contenuto della sezione è incluso
if python "${PROJECT_ROOT}/prompt_builder.py" \
	--tasks-file "${STATION_TASKS}" --task TASK-001 \
	2>/dev/null | grep -q "Scaffold"; then
	pass "TASKS.md con dettaglio → contenuto sezione incluso nel prompt"
else
	fail "TASKS.md con dettaglio → contenuto sezione incluso nel prompt"
fi

# task senza sezione dettaglio: nessun crash, nessuna sezione vuota
LOG_OUTPUT="$(python "${PROJECT_ROOT}/prompt_builder.py" \
	--tasks-file "${LOG_TASKS}" --task TASK-001 \
	2>/dev/null || true)"

if [[ -n "${LOG_OUTPUT}" ]]; then
	pass "TASKS.md senza dettaglio → prompt generato senza crash"
else
	fail "TASKS.md senza dettaglio → prompt generato senza crash"
fi

if ! echo "${LOG_OUTPUT}" | grep -q "Dettaglio completo del task"; then
	pass "TASKS.md senza dettaglio → nessuna sezione dettaglio nel prompt"
else
	fail "TASKS.md senza dettaglio → nessuna sezione dettaglio nel prompt"
fi

echo ""
echo "-- File di riferimento consigliati (read_first) --"

# Progetto con scaffold completo (questo stesso progetto): il prompt non deve
# mai citare prompt_builder.py (file interno del builder, non del target) e
# deve citare i file di scaffold che esistono davvero.
FULL_SCAFFOLD_OUTPUT="$(python "${PROJECT_ROOT}/prompt_builder.py" \
	--project "${PROJECT_ROOT}" --task TASK-004 2>/dev/null || true)"

if ! echo "${FULL_SCAFFOLD_OUTPUT}" | grep -q "prompt_builder.py"; then
	pass "scaffold completo → prompt non cita mai prompt_builder.py"
else
	fail "scaffold completo → prompt non cita mai prompt_builder.py"
fi

if echo "${FULL_SCAFFOLD_OUTPUT}" | grep -q "AGENTS.md"; then
	pass "scaffold completo → prompt cita AGENTS.md (esiste davvero)"
else
	fail "scaffold completo → prompt cita AGENTS.md (esiste davvero)"
fi

if echo "${FULL_SCAFFOLD_OUTPUT}" | grep -q "^TASKS.md: .*docs/ai/TASKS.md"; then
	pass "scaffold completo → header TASKS.md sempre presente"
else
	fail "scaffold completo → header TASKS.md sempre presente"
fi

# Progetto con scaffold minimo (solo docs/ai/TASKS.md, come new-ai-project.sh
# o onboard-existing-project.sh): il prompt non deve inventare file che non
# esistono, e non deve mai citare prompt_builder.py.
MINIMAL_PROJECT_DIR="$(mktemp -d)"
mkdir -p "${MINIMAL_PROJECT_DIR}/docs/ai"
cat >"${MINIMAL_PROJECT_DIR}/docs/ai/TASKS.md" <<'EOF'
# Tasks

## Backlog

| ID | Titolo | Priorità | Note |
| -- | ------ | -------- | ---- |
| TASK-001 | Task di prova | media | nota |
EOF

MINIMAL_OUTPUT="$(python "${PROJECT_ROOT}/prompt_builder.py" \
	--project "${MINIMAL_PROJECT_DIR}" --task TASK-001 2>/dev/null || true)"

if ! echo "${MINIMAL_OUTPUT}" | grep -q "AGENTS.md"; then
	pass "scaffold minimo → prompt non inventa AGENTS.md (non esiste)"
else
	fail "scaffold minimo → prompt non inventa AGENTS.md (non esiste)"
fi

if ! echo "${MINIMAL_OUTPUT}" | grep -q "prompt_builder.py"; then
	pass "scaffold minimo → prompt non cita mai prompt_builder.py"
else
	fail "scaffold minimo → prompt non cita mai prompt_builder.py"
fi

if echo "${MINIMAL_OUTPUT}" | grep -q "docs/ai/TASKS.md"; then
	pass "scaffold minimo → prompt cita comunque docs/ai/TASKS.md"
else
	fail "scaffold minimo → prompt cita comunque docs/ai/TASKS.md"
fi

rm -rf "${MINIMAL_PROJECT_DIR}"

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
