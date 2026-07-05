#!/usr/bin/env bash
# Fotografia rapida e read-only dello stato della AI Software Station.
# Non modifica file, non fa commit, non fa push, non fa merge.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=scripts/lib/tasks-md.sh
source "${SCRIPT_DIR}/lib/tasks-md.sh"

usage() {
	cat <<EOF
Usage: $(basename "$0")
       $(basename "$0") --help

Mostra una fotografia rapida dello stato della AI Software Station:
branch, working tree, ultimi commit, helper disponibili, progetti rilevati
e relativo stato task, ultimi log dei cicli AI.

Read-only: non modifica file, non fa commit, non fa push, non fa merge.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	usage
	exit 0
fi
[[ $# -eq 0 ]] || {
	printf "ERROR: opzione non riconosciuta: '%s'. Usa --help.\n" "$1" >&2
	exit 1
}

printf "== AI Software Station — status ==\n\n"

# ── Repository ────────────────────────────────────────────────────────────────

printf -- "-- Repository --\n"
branch="$(git -C "${REPO_ROOT}" branch --show-current)"
printf "Branch corrente: %s\n" "${branch}"

if [[ -z "$(git -C "${REPO_ROOT}" status --short)" ]]; then
	printf "Working tree:    pulito\n"
else
	printf "Working tree:    sporco\n"
	git -C "${REPO_ROOT}" status --short | sed 's/^/  /'
fi

printf "\nUltimi commit:\n"
git -C "${REPO_ROOT}" log --oneline --decorate -n 5 | sed 's/^/  /'
printf "\n"

# ── Helper disponibili ────────────────────────────────────────────────────────

printf -- "-- Helper disponibili --\n"
helpers=(
	"task-intake:task-intake.sh"
	"cursor-prompt:cursor-prompt.sh"
	"ai-review:ai-review.sh"
	"ai-cycle:ai-cycle.sh"
	"commit-if-approved:commit-if-approved.sh"
	"ai-cycle-log:ai-cycle-log.sh"
	"station-status:station-status.sh"
	"station-next-task:station-next-task.sh"
	"new-ai-project:new-ai-project.sh"
)
for entry in "${helpers[@]}"; do
	label="${entry%%:*}"
	file="${entry#*:}"
	path="${SCRIPT_DIR}/${file}"
	if [[ -x "${path}" ]]; then
		printf "  [x] %-18s scripts/%s\n" "${label}" "${file}"
	elif [[ -f "${path}" ]]; then
		printf "  [!] %-18s scripts/%s (presente, non eseguibile)\n" "${label}" "${file}"
	else
		printf "  [ ] %-18s scripts/%s (assente)\n" "${label}" "${file}"
	fi
done
printf "\n"

# ── Progetti ──────────────────────────────────────────────────────────────────

printf -- "-- Progetti in projects/ --\n"
PROJECTS_DIR="${REPO_ROOT}/projects"
if [[ -d "${PROJECTS_DIR}" ]]; then
	shopt -s nullglob
	project_dirs=("${PROJECTS_DIR}"/*/)
	shopt -u nullglob
	if [[ "${#project_dirs[@]}" -eq 0 ]]; then
		printf "  (nessun progetto trovato)\n"
	fi
	for dir in "${project_dirs[@]}"; do
		name="$(basename "${dir}")"
		tasks_md="${dir}docs/ai/TASKS.md"
		test_sh="${dir}scripts/test.sh"

		printf "  %s\n" "${name}"

		if [[ -f "${test_sh}" ]]; then
			if [[ -x "${test_sh}" ]]; then
				printf "    scripts/test.sh:  presente, eseguibile\n"
			else
				printf "    scripts/test.sh:  presente, NON eseguibile\n"
			fi
		else
			printf "    scripts/test.sh:  assente\n"
		fi

		if [[ -f "${tasks_md}" ]]; then
			backlog="$(tasks_md_count_rows "${tasks_md}" "Backlog")"
			in_corso="$(tasks_md_count_rows "${tasks_md}" "In corso")"
			completati="$(tasks_md_count_rows "${tasks_md}" "Completati")"
			printf "    docs/ai/TASKS.md: In corso=%s Backlog=%s Completati=%s\n" \
				"${in_corso}" "${backlog}" "${completati}"
		else
			printf "    docs/ai/TASKS.md: assente\n"
		fi
	done
else
	printf "  (directory projects/ assente)\n"
fi
printf "\n"

# ── Log cicli AI ──────────────────────────────────────────────────────────────

printf -- "-- Ultimi log cicli AI (logs/ai-cycles/) --\n"
LOGS_DIR="${REPO_ROOT}/logs/ai-cycles"
if [[ -d "${LOGS_DIR}" ]]; then
	shopt -s nullglob
	log_files=("${LOGS_DIR}"/*.md)
	shopt -u nullglob
	if [[ "${#log_files[@]}" -eq 0 ]]; then
		printf "  (nessun log presente)\n"
	else
		# shellcheck disable=SC2012
		ls -t "${LOGS_DIR}"/*.md | head -n 3 | while read -r f; do
			printf "  %s\n" "$(basename "${f}")"
		done
	fi
else
	printf "  (directory logs/ai-cycles/ assente — nessun ciclo --run eseguito ancora)\n"
fi
printf "\n"

# ── Suggerimento ──────────────────────────────────────────────────────────────

printf -- "-- Prossimo comando utile --\n"
if [[ "${branch}" == "main" ]]; then
	printf "  Sei su main. Per iniziare un task: git switch -c task/<nome> e poi\n"
	printf "  ./scripts/station-next-task.sh --project <nome-progetto>\n"
else
	printf "  ./scripts/station-next-task.sh --project <nome-progetto>\n"
fi
