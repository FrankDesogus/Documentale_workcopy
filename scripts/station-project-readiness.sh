#!/usr/bin/env bash
# Verifica se un progetto è pronto per essere gestito dalla Station.
# Read-only: non modifica file, non fa commit, non fa push, non fa merge.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
	cat <<EOF
Usage: $(basename "$0") --project NAME|PATH
       $(basename "$0") --help

Verifica se un progetto è pronto per il workflow AI della Station:
  - projects/<name>/ esiste
  - docs/ai/TASKS.md presente
  - scripts/test.sh presente ed eseguibile
  - almeno un task disponibile (In corso o Backlog), via station-next-task.sh

Stampa READY o NOT_READY con checklist e, se READY, il prossimo comando
consigliato. Read-only: non modifica file.
EOF
}

error() {
	printf "ERROR: %s\n" "$*" >&2
	exit 1
}

normalize_project() {
	local input="$1"
	local name="${input#projects/}"
	printf "projects/%s" "${name}"
}

PROJECT_INPUT=""

while [[ $# -gt 0 ]]; do
	case "$1" in
	--help | -h)
		usage
		exit 0
		;;
	--project)
		[[ $# -ge 2 ]] || error "--project requires a value."
		PROJECT_INPUT="$2"
		shift 2
		;;
	-*)
		error "Unknown option: '$1'. Use --help for usage."
		;;
	*)
		error "Unexpected argument: '$1'. Use --help for usage."
		;;
	esac
done

[[ -n "${PROJECT_INPUT}" ]] || error "--project is required. Use --help for usage."

PROJECT_REL="$(normalize_project "${PROJECT_INPUT}")"
PROJECT_ABS="${REPO_ROOT}/${PROJECT_REL}"

[[ -d "${PROJECT_ABS}" ]] || error "Project directory not found: '${PROJECT_REL}'"

printf "== Readiness check: %s ==\n\n" "${PROJECT_REL}"

ready=1
suggestions=()

TASKS_MD="${PROJECT_ABS}/docs/ai/TASKS.md"
if [[ -f "${TASKS_MD}" ]]; then
	printf "[OK]   docs/ai/TASKS.md presente\n"
else
	printf "[FAIL] docs/ai/TASKS.md assente\n"
	suggestions+=("Crea ${PROJECT_REL}/docs/ai/TASKS.md (es. copiando docs/templates/TASKS.template.md, o rilanciando onboard-existing-project.sh se il progetto era stato importato).")
	ready=0
fi

TEST_SH="${PROJECT_ABS}/scripts/test.sh"
if [[ -f "${TEST_SH}" ]]; then
	printf "[OK]   scripts/test.sh presente\n"
	if [[ -x "${TEST_SH}" ]]; then
		printf "[OK]   scripts/test.sh eseguibile\n"
	else
		printf "[FAIL] scripts/test.sh non eseguibile\n"
		suggestions+=("chmod +x ${PROJECT_REL}/scripts/test.sh")
		ready=0
	fi
else
	printf "[FAIL] scripts/test.sh assente\n"
	printf "[FAIL] scripts/test.sh eseguibile (non applicabile: file assente)\n"
	suggestions+=("Crea ${PROJECT_REL}/scripts/test.sh (placeholder minimo con exit 0 se non ci sono ancora test reali).")
	ready=0
fi

if [[ -f "${TASKS_MD}" ]]; then
	if next_task_output="$("${SCRIPT_DIR}/station-next-task.sh" --project "${PROJECT_REL}" 2>&1)"; then
		printf "[OK]   Task disponibile (esito station-next-task.sh):\n"
		printf "%s\n" "${next_task_output}" | sed 's/^/         /'
	else
		printf "[FAIL] Nessun task disponibile in 'In corso' o 'Backlog'\n"
		suggestions+=("Aggiungi un task in Backlog in ${PROJECT_REL}/docs/ai/TASKS.md, poi rilancia station-next-task.sh.")
		ready=0
	fi
else
	printf "[FAIL] Task disponibile: non verificabile (TASKS.md assente)\n"
	ready=0
fi

printf "\n"
if [[ "${ready}" -eq 1 ]]; then
	printf "STATO: READY\n\n"
	printf "Prossimo comando consigliato:\n"
	printf "  ./scripts/ai-cycle.sh --project %s --task TASK-001 --dry-run\n" "${PROJECT_REL}"
	exit 0
else
	printf "STATO: NOT_READY\n\n"
	printf "Suggerimenti:\n"
	for s in "${suggestions[@]}"; do
		printf "  - %s\n" "${s}"
	done
	exit 1
fi
