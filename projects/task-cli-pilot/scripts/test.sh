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
echo "-- Comportamento done/delete (directory temporanea) --"
TMPDIR2="$(mktemp -d)"
# shellcheck disable=SC2329
cleanup_tmp2() {
	rm -rf "${TMPDIR2}"
}
trap cleanup_tmp2 EXIT

# "done" è una keyword bash: usare variabile per evitare SC1010
CMD_DONE="done"

printf '[{"id":1,"text":"alpha","done":false},{"id":2,"text":"beta","done":false}]\n' \
	>"${TMPDIR2}/tasks.json"

check_output "done task esistente" \
	"Task #1 marked as done." \
	"$(cd "${TMPDIR2}" && "${CLI[@]}" "${CMD_DONE}" 1)"

if python -c "
import json
data = json.load(open('${TMPDIR2}/tasks.json'))
assert data[0]['done'] is True, 'done non salvato'
assert data[1]['done'] is False, 'task 2 modificato per errore'
" >/dev/null 2>&1; then
	pass "done salva flag correttamente"
else
	fail "done salva flag correttamente — stato JSON errato"
fi

check_output "list dopo done" \
	"$(printf '[x] 1 — alpha\n[ ] 2 — beta')" \
	"$(cd "${TMPDIR2}" && "${CLI[@]}" list)"

check_output "delete task esistente" \
	"Task #2 deleted." \
	"$(cd "${TMPDIR2}" && "${CLI[@]}" delete 2)"

if python -c "
import json
data = json.load(open('${TMPDIR2}/tasks.json'))
assert len(data) == 1, f'atteso 1 task, trovati {len(data)}'
assert data[0]['id'] == 1, 'task rimasto è quello sbagliato'
" >/dev/null 2>&1; then
	pass "delete rimuove il task corretto"
else
	fail "delete rimuove il task corretto — stato JSON errato"
fi

check_output "list dopo delete" \
	"[x] 1 — alpha" \
	"$(cd "${TMPDIR2}" && "${CLI[@]}" list)"

if (cd "${TMPDIR2}" && "${CLI[@]}" "${CMD_DONE}" 99 >/dev/null 2>&1); then
	fail "done su ID inesistente → exit 1 — non ha restituito errore"
else
	pass "done su ID inesistente → exit 1"
fi

if (cd "${TMPDIR2}" && "${CLI[@]}" delete 99 >/dev/null 2>&1); then
	fail "delete su ID inesistente → exit 1 — non ha restituito errore"
else
	pass "delete su ID inesistente → exit 1"
fi

echo ""
echo "-- Comportamento clear e gestione errori --"
TMPDIR3="$(mktemp -d)"
# shellcheck disable=SC2329
cleanup_tmp3() {
	rm -rf "${TMPDIR3}"
}
trap cleanup_tmp3 EXIT

printf '[{"id":1,"text":"uno","done":false},{"id":2,"text":"due","done":false}]\n' \
	>"${TMPDIR3}/tasks.json"

check_output "clear lista non vuota" \
	"All tasks cleared." \
	"$(cd "${TMPDIR3}" && "${CLI[@]}" clear)"

if python -c "
import json
data = json.load(open('${TMPDIR3}/tasks.json'))
assert data == [], f'atteso [], ottenuto {data}'
" >/dev/null 2>&1; then
	pass "clear salva lista vuota in tasks.json"
else
	fail "clear salva lista vuota in tasks.json — contenuto errato"
fi

check_output "list dopo clear" \
	"No tasks." \
	"$(cd "${TMPDIR3}" && "${CLI[@]}" list)"

check_output "clear su lista già vuota" \
	"All tasks cleared." \
	"$(cd "${TMPDIR3}" && "${CLI[@]}" clear)"

printf 'QUESTO NON E JSON VALIDO\n' >"${TMPDIR3}/tasks.json"

if (cd "${TMPDIR3}" && "${CLI[@]}" list >/dev/null 2>&1); then
	fail "tasks.json corrotto → exit 1 — non ha restituito errore"
else
	pass "tasks.json corrotto → exit 1"
fi

echo ""
if [[ "${FAILURES}" -eq 0 ]]; then
	echo "Tutti i controlli passati."
	exit 0
else
	printf "Falliti: %d controllo/i.\n" "${FAILURES}" >&2
	exit 1
fi
