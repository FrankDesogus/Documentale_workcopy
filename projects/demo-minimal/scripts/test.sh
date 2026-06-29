#!/usr/bin/env bash
# Test di struttura per demo-minimal.
# Verifica la presenza dei file obbligatori del progetto.
# Exit 0 se tutto è a posto, exit 1 se manca qualcosa.
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

echo ""
if [[ "${FAILURES}" -eq 0 ]]; then
	echo "Tutti i controlli passati."
	exit 0
else
	printf "Falliti: %d controllo/i.\n" "${FAILURES}" >&2
	exit 1
fi
