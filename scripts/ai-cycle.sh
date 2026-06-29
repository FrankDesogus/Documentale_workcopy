#!/usr/bin/env bash
# Orchestratore dry-run del ciclo operativo AI Software Station.
# Versione 1: solo modalità --dry-run. Non modifica file, non esegue agenti,
# non effettua operazioni Git. Mostra i comandi del ciclo nell'ordine corretto.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
	cat <<EOF
Usage: $(basename "$0") --project NAME|PATH --task ID --dry-run
       $(basename "$0") --help

Orchestrate the AI Software Station task cycle in dry-run mode.
Shows all commands that would be executed without running them.

Options:
  --project NAME|PATH  project name (e.g. log-analyzer) or path
                       (e.g. projects/log-analyzer)
  --task ID            task ID to cycle (e.g. TASK-004)
  --dry-run            required in v1: show commands without executing them
  --help, -h           show this help and exit

Version 1 supports only --dry-run mode.
No agents, Git operations, file modifications, or network access are performed.
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

# ── Argument parsing ──────────────────────────────────────────────────────────

PROJECT_INPUT=""
TASK_ID=""
DRY_RUN=0

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
	--dry-run)
		DRY_RUN=1
		shift
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
[[ "${DRY_RUN}" -eq 1 ]] || error "Only --dry-run is supported in v1. Pass --dry-run explicitly."

current_branch="$(git -C "${REPO_ROOT}" branch --show-current)"
[[ "${current_branch}" != "main" ]] ||
	error "ai-cycle must run on a task branch, not on 'main'. Switch to a task branch first."

[[ -z "$(git -C "${REPO_ROOT}" status --short)" ]] ||
	error "Working tree is not clean. Commit or stash your changes before running ai-cycle."

PROJECT_REL="$(normalize_project "${PROJECT_INPUT}")"
PROJECT_ABS="${REPO_ROOT}/${PROJECT_REL}"
TASKS_MD="${PROJECT_ABS}/docs/ai/TASKS.md"

[[ -d "${PROJECT_ABS}" ]] || error "Project directory not found: '${PROJECT_REL}'"
[[ -f "${TASKS_MD}" ]] || error "TASKS.md not found: '${PROJECT_REL}/docs/ai/TASKS.md'"
grep -q "${TASK_ID}" "${TASKS_MD}" ||
	error "Task '${TASK_ID}' not found in ${PROJECT_REL}/docs/ai/TASKS.md"

if awk '
  /^## Completati/ { in_section=1; next }
  /^## /           { in_section=0 }
  in_section && /'"${TASK_ID}"'/ { found=1 }
  END { exit !found }
' "${TASKS_MD}"; then
	error "Task '${TASK_ID}' is already in the 'Completati' section. Use a task in Backlog or In corso."
fi

task_section="$(awk '
  /^## Backlog/   { section="Backlog" }
  /^## In corso/  { section="In corso" }
  /^## /          { if ($0 !~ /Backlog/ && $0 !~ /In corso/) section="" }
  section != "" && /'"${TASK_ID}"'/ { print section; exit }
' "${TASKS_MD}")"
[[ -n "${task_section}" ]] || task_section="Backlog"

# ── Dry-run output ────────────────────────────────────────────────────────────

cat <<EOF
[DRY-RUN] Progetto: ${PROJECT_REL}
[DRY-RUN] Task:     ${TASK_ID}
[DRY-RUN] Modalità: dry-run (nessuna modifica effettiva)

[STEP 1] Verifica branch e working tree
  Branch:        ${current_branch}  ✓
  Working tree:  pulito  ✓

[STEP 2] Verifica precondizioni task
  Progetto:  ${PROJECT_REL}  ✓
  TASKS.md:  ${PROJECT_REL}/docs/ai/TASKS.md  ✓
  Task:      ${TASK_ID}  ✓
  Stato:     ${task_section}

[STEP 3] Genera prompt Cursor Agent
  ./scripts/cursor-prompt.sh \\
    --project ${PROJECT_REL} \\
    --task ${TASK_ID} \\
    --output /tmp/cursor-prompt-${TASK_ID}.md

[STEP 4] Genera prompt di review per Claude Code
  # (eseguire dopo che Cursor Agent ha completato il task)
  ./scripts/ai-review.sh \\
    --project ${PROJECT_REL} \\
    --task ${TASK_ID} \\
    --output /tmp/review-prompt-${TASK_ID}.md

[STEP 5] Esegui test del progetto
  cd ${PROJECT_REL} && ./scripts/test.sh

[STEP 6] Snapshot git
  git status --short
  git diff --stat -- ${PROJECT_REL}

[DRY-RUN] Fine. Nessuna modifica effettuata.
[DRY-RUN] Eseguire i comandi mostrati nell'ordine indicato.
EOF
