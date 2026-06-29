#!/usr/bin/env bash
# Test per task-cli-pilot.
# Verifica struttura obbligatoria e comportamento base della CLI.
# Exit 0 se tutto è a posto, exit 1 se qualcosa fallisce.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

FAILURES=0

pass() { printf "PASS  %s\n" "$1"; }

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

check_exit0() {
	local desc="$1"
	shift
	if "$@" >/dev/null 2>&1; then
		pass "${desc}"
	else
		fail "${desc} — exit code non zero"
	fi
}

echo "== Test: task-cli-pilot =="
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
check_file "task_cli.py"

echo ""
echo "-- Sintassi Python --"
check_exit0 "task_cli.py (py_compile)" \
	python -m py_compile "${PROJECT_ROOT}/task_cli.py"

echo ""
echo "-- Comportamento CLI base --"
check_output "task_cli.py --version" \
	"task-cli-pilot 0.1.0" \
	"$(python "${PROJECT_ROOT}/task_cli.py" --version)"

echo ""
echo "-- Comportamento add/list (directory temporanea) --"
TMPDIR="$(mktemp -d)"
# shellcheck disable=SC2329
cleanup_tmp() {
	rm -rf "${TMPDIR}"
}
trap cleanup_tmp EXIT

CLI=(python "${PROJECT_ROOT}/task_cli.py")

check_output "list senza tasks.json" \
	"No tasks." \
	"$(cd "${TMPDIR}" && "${CLI[@]}" list)"

check_output "add primo task" \
	"Added task #1: testo" \
	"$(cd "${TMPDIR}" && "${CLI[@]}" add "testo")"

if [[ -f "${TMPDIR}/tasks.json" ]]; then
	pass "tasks.json creato nella directory temporanea"
else
	fail "tasks.json creato nella directory temporanea — file mancante"
fi

if python -c "import json; json.load(open('${TMPDIR}/tasks.json'))" >/dev/null 2>&1; then
	pass "tasks.json è JSON valido"
else
	fail "tasks.json è JSON valido — parsing fallito"
fi

if python -c "
import json
data = json.load(open('${TMPDIR}/tasks.json'))
assert isinstance(data, list), 'root non è una lista'
assert len(data) == 1, 'attesa una task'
task = data[0]
for key in ('id', 'text', 'done'):
    assert key in task, f'chiave mancante: {key}'
" >/dev/null 2>&1; then
	pass "tasks.json ha formato id/text/done"
else
	fail "tasks.json ha formato id/text/done — struttura non valida"
fi

check_output "list dopo add" \
	"[ ] 1 — testo" \
	"$(cd "${TMPDIR}" && "${CLI[@]}" list)"

check_output "add secondo task (ID 2)" \
	"Added task #2: altro" \
	"$(cd "${TMPDIR}" && "${CLI[@]}" add "altro")"

if python -c "
import json
data = json.load(open('${TMPDIR}/tasks.json'))
ids = [task['id'] for task in data]
assert ids == [1, 2], f'ID attesi [1, 2], ottenuti {ids}'
" >/dev/null 2>&1; then
	pass "due add consecutivi producono ID 1 e 2"
else
	fail "due add consecutivi producono ID 1 e 2 — ID non corretti"
fi

printf '[{"id": 1, "text": "completato", "done": true}]\n' >"${TMPDIR}/tasks.json"

check_output "list task con done=true" \
	"[x] 1 — completato" \
	"$(cd "${TMPDIR}" && "${CLI[@]}" list)"

echo ""
if [[ "${FAILURES}" -eq 0 ]]; then
	echo "Tutti i controlli passati."
	exit 0
else
	printf "Falliti: %d controllo/i.\n" "${FAILURES}" >&2
	exit 1
fi
