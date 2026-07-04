#!/usr/bin/env bash
# Genera un log Markdown di un ciclo AI sotto logs/ai-cycles/.
# Standalone e flag-driven: usato da ai-cycle.sh --run, ma anche invocabile
# a mano per registrare/simulare un ciclo. Read-only su Git (solo status).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_DIR="${REPO_ROOT}/logs/ai-cycles"

usage() {
	cat <<EOF
Usage: $(basename "$0") --project NAME|PATH --task ID [options]
       $(basename "$0") --help

Write a Markdown log of an AI cycle under logs/ai-cycles/.

Options:
  --project NAME|PATH   project name or path (required)
  --task ID             task ID (required)
  --command STR         command that was run (default: n/d)
  --agent-result STR    Cursor Agent outcome (default: n/d)
  --tests-result STR    tests outcome (default: n/d)
  --prompt-file PATH    path of the generated Cursor prompt (default: n/d)
  --review-file PATH    path of the review prompt/file (default: n/d)
  --commit-note STR     note about commit/non-commit (default: no commit)
  --output FILE         write to FILE instead of the auto path
  --help, -h            show this help and exit

Filename (auto): logs/ai-cycles/YYYYMMDD-HHMMSS-<project>-<task>.md
Never performs push, merge, reset or clean. Git access is read-only (status).
EOF
}

error() {
	printf "ERROR: %s\n" "$*" >&2
	exit 1
}

PROJECT_INPUT=""
TASK_ID=""
COMMAND_STR="n/d"
AGENT_RESULT="n/d"
TESTS_RESULT="n/d"
PROMPT_FILE="n/d"
REVIEW_FILE="n/d"
COMMIT_NOTE="Nessun commit eseguito da questo ciclo."
OUTPUT=""

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
	--task)
		[[ $# -ge 2 ]] || error "--task requires a value."
		TASK_ID="$2"
		shift 2
		;;
	--command)
		[[ $# -ge 2 ]] || error "--command requires a value."
		COMMAND_STR="$2"
		shift 2
		;;
	--agent-result)
		[[ $# -ge 2 ]] || error "--agent-result requires a value."
		AGENT_RESULT="$2"
		shift 2
		;;
	--tests-result)
		[[ $# -ge 2 ]] || error "--tests-result requires a value."
		TESTS_RESULT="$2"
		shift 2
		;;
	--prompt-file)
		[[ $# -ge 2 ]] || error "--prompt-file requires a value."
		PROMPT_FILE="$2"
		shift 2
		;;
	--review-file)
		[[ $# -ge 2 ]] || error "--review-file requires a value."
		REVIEW_FILE="$2"
		shift 2
		;;
	--commit-note)
		[[ $# -ge 2 ]] || error "--commit-note requires a value."
		COMMIT_NOTE="$2"
		shift 2
		;;
	--output)
		[[ $# -ge 2 ]] || error "--output requires a value."
		OUTPUT="$2"
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

[[ -n "${PROJECT_INPUT}" ]] || error "--project is required."
[[ -n "${TASK_ID}" ]] || error "--task is required."

# Slug leggibile per il nome file: togli 'projects/', sostituisci non-alfanumerici.
project_slug="${PROJECT_INPUT#projects/}"
project_slug="${project_slug//\//-}"
project_slug="$(printf "%s" "${project_slug}" | tr -c 'A-Za-z0-9._-' '-')"
task_slug="$(printf "%s" "${TASK_ID}" | tr -c 'A-Za-z0-9._-' '-')"

timestamp="$(date +%Y%m%d-%H%M%S)"
datetime="$(date '+%Y-%m-%d %H:%M:%S %z')"
branch="$(git -C "${REPO_ROOT}" branch --show-current 2>/dev/null || echo "unknown")"
git_status="$(git -C "${REPO_ROOT}" status --short 2>/dev/null || echo "(git status non disponibile)")"
[[ -n "${git_status}" ]] || git_status="(working tree pulito)"

if [[ -z "${OUTPUT}" ]]; then
	mkdir -p "${LOG_DIR}"
	OUTPUT="${LOG_DIR}/${timestamp}-${project_slug}-${task_slug}.md"
fi

{
	printf "# Ciclo AI — %s — %s\n\n" "${TASK_ID}" "${PROJECT_INPUT}"
	printf "| Campo | Valore |\n"
	printf "|-------|--------|\n"
	printf "| Data/ora | %s |\n" "${datetime}"
	printf "| Branch | \`%s\` |\n" "${branch}"
	printf "| Progetto | \`%s\` |\n" "${PROJECT_INPUT}"
	printf "| Task | \`%s\` |\n" "${TASK_ID}"
	printf "| Comando eseguito | \`%s\` |\n" "${COMMAND_STR}"
	printf "| Esito Cursor Agent | %s |\n" "${AGENT_RESULT}"
	printf "| Esito test | %s |\n" "${TESTS_RESULT}"
	printf "| Prompt generato | \`%s\` |\n" "${PROMPT_FILE}"
	printf "| Review prompt/file | \`%s\` |\n" "${REVIEW_FILE}"
	printf "\n## Git status finale\n\n"
	# shellcheck disable=SC2016 # backtick fence markdown letterale, %s è printf
	printf '```\n%s\n```\n' "${git_status}"
	printf "\n## Note commit\n\n%s\n" "${COMMIT_NOTE}"
	printf "\n## Garanzie\n\n"
	printf -- "- Nessun \`git push\` eseguito.\n"
	printf -- "- Nessun \`git merge\` su \`main\` eseguito.\n"
	printf -- "- Nessun \`reset --hard\` / \`git clean\` eseguito.\n"
} >"${OUTPUT}" || error "Cannot write log to '${OUTPUT}'."

printf "Cycle log written to %s\n" "${OUTPUT}"
