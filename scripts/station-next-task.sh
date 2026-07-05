#!/usr/bin/env bash
# Suggerisce il prossimo task da eseguire per un progetto e stampa il comando
# ai-cycle.sh pronto all'uso. Read-only: non modifica file.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=scripts/lib/tasks-md.sh
source "${SCRIPT_DIR}/lib/tasks-md.sh"

usage() {
	cat <<EOF
Usage: $(basename "$0") --project NAME|PATH
       $(basename "$0") --help

Legge projects/<nome>/docs/ai/TASKS.md e suggerisce il prossimo task da
eseguire: preferisce un task già "In corso"; in mancanza, il primo task in
"Backlog". Stampa il comando ai-cycle.sh pronto all'uso.

Options:
  --project NAME|PATH  project name (e.g. log-analyzer) or path
                       (e.g. projects/log-analyzer)
  --help, -h           show this help and exit

Read-only: non modifica file, non fa commit, non fa push, non fa merge.
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
TASKS_MD="${PROJECT_ABS}/docs/ai/TASKS.md"

[[ -d "${PROJECT_ABS}" ]] || error "Project directory not found: '${PROJECT_REL}'"
[[ -f "${TASKS_MD}" ]] || error "TASKS.md not found: '${PROJECT_REL}/docs/ai/TASKS.md'"

in_corso_row="$(tasks_md_first_row "${TASKS_MD}" "In corso")"
backlog_row="$(tasks_md_first_row "${TASKS_MD}" "Backlog")"

if [[ -n "${in_corso_row}" ]]; then
	task_id="${in_corso_row%%|*}"
	task_title="${in_corso_row#*|}"
	stato="In corso"
	if [[ -n "${backlog_row}" ]]; then
		note="Nota: c'è anche un task in Backlog, ma il task già In corso ha priorità."
	else
		note=""
	fi
elif [[ -n "${backlog_row}" ]]; then
	task_id="${backlog_row%%|*}"
	task_title="${backlog_row#*|}"
	stato="Backlog"
	note=""
else
	error "Nessun task disponibile in 'In corso' o 'Backlog' per '${PROJECT_REL}'. Aggiungi un task in ${PROJECT_REL}/docs/ai/TASKS.md."
fi

snippet="$(tasks_md_task_snippet "${TASKS_MD}" "${task_id}")"

printf "Progetto: %s\n" "${PROJECT_REL}"
printf "Task:     %s\n" "${task_id}"
printf "Titolo:   %s\n" "${task_title}"
printf "Stato:    %s\n" "${stato}"
if [[ -n "${snippet}" ]]; then
	printf "Dettaglio: %s\n" "${snippet}"
fi
if [[ -n "${note}" ]]; then
	printf "%s\n" "${note}"
fi
printf "\nComando pronto:\n"
printf "  ./scripts/ai-cycle.sh --project %s --task %s --run\n" "${PROJECT_REL}" "${task_id}"
