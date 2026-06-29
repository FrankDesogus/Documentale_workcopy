#!/usr/bin/env bash
# Test per demo-minimal.
# Verifica struttura obbligatoria e comportamento della CLI.
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

echo "== Test: demo-minimal =="
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
check_file "cli.py"

echo ""
echo "-- Comportamento CLI --"
check_output "cli.py (default)" \
	"demo-minimal: AI Software Station demo OK" \
	"$(python "${PROJECT_ROOT}/cli.py")"

check_output "cli.py --version" \
	"demo-minimal 0.1.0" \
	"$(python "${PROJECT_ROOT}/cli.py" --version)"

check_output "cli.py --name Riccardo" \
	"demo-minimal: hello Riccardo" \
	"$(python "${PROJECT_ROOT}/cli.py" --name Riccardo)"

echo ""
if [[ "${FAILURES}" -eq 0 ]]; then
	echo "Tutti i controlli passati."
	exit 0
else
	printf "Falliti: %d controllo/i.\n" "${FAILURES}" >&2
	exit 1
fi
