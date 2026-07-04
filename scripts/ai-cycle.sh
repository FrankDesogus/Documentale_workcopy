#!/usr/bin/env bash
# Orchestratore del ciclo operativo AI Software Station.
# --dry-run (v1): mostra i comandi senza eseguirli.
# --run     (v2): esecuzione assistita controllata — genera prompt, lancia agente,
#                 esegue test, prepara review. Non fa commit, push o merge automatici.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
	cat <<EOF
Usage: $(basename "$0") --project NAME|PATH --task ID --dry-run
       $(basename "$0") --project NAME|PATH --task ID --run
       $(basename "$0") --help

Orchestrate the AI Software Station task cycle.

Options:
  --project NAME|PATH  project name (e.g. log-analyzer) or path
                       (e.g. projects/log-analyzer)
  --task ID            task ID to cycle (e.g. TASK-004)
  --dry-run            show all commands without executing them (v1)
  --run                execute the full assisted cycle: generate Cursor prompt,
                       launch Cursor Agent, run tests, prepare review prompt,
                       show git snapshot. Stops before commit. (v2)
  --help, -h           show this help and exit

Guardrails (--run mode):
  Never performs push, merge, branch delete, reset --hard, or git clean.
  Never commits automatically.
  Aborts immediately if tests fail.
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
RUN_MODE=0

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
	--run)
		RUN_MODE=1
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
[[ "${DRY_RUN}" -eq 1 ]] || [[ "${RUN_MODE}" -eq 1 ]] ||
	error "Specify --dry-run (show commands) or --run (execute cycle). Use --help for usage."
[[ ! ("${DRY_RUN}" -eq 1 && "${RUN_MODE}" -eq 1) ]] ||
	error "--dry-run and --run are mutually exclusive."

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

# ── Run mode — assisted execution ────────────────────────────────────────────

run_cycle() {
	local cursor_prompt_file="/tmp/cursor-prompt-${TASK_ID}.md"
	local review_prompt_file="/tmp/review-prompt-${TASK_ID}.md"

	echo "[RUN] Progetto: ${PROJECT_REL}"
	echo "[RUN] Task:     ${TASK_ID}"
	echo "[RUN] Modalità: run (esecuzione assistita)"
	echo ""

	echo "[STEP 1] ✓ Branch: ${current_branch}"
	echo "[STEP 1] ✓ Working tree: pulito"
	echo ""

	echo "[STEP 2] ✓ Progetto: ${PROJECT_REL}"
	echo "[STEP 2] ✓ Task: ${TASK_ID} (${task_section})"
	echo ""

	echo "[STEP 3] Generazione prompt Cursor Agent..."
	"${SCRIPT_DIR}/cursor-prompt.sh" \
		--project "${PROJECT_REL}" \
		--task "${TASK_ID}" \
		--output "${cursor_prompt_file}"
	echo "[STEP 3] ✓ Prompt generato: ${cursor_prompt_file}"
	echo ""

	echo "[STEP 4] Lancio Cursor Agent (timeout 300s)..."
	if ! timeout 300s claude -p --allowedTools "Read,Edit,Write,Bash" \
		<"${cursor_prompt_file}"; then
		printf "ERROR: Cursor Agent fallito o timeout.\n" >&2
		exit 1
	fi
	echo "[STEP 4] ✓ Cursor Agent completato."
	echo ""

	echo "[STEP 5] Esecuzione test..."
	if ! (cd "${PROJECT_ABS}" && ./scripts/test.sh); then
		printf "ERROR: Test falliti. Correggere prima di procedere.\n" >&2
		exit 1
	fi
	echo "[STEP 5] ✓ Test passati."
	echo ""

	echo "[STEP 6] Generazione prompt review..."
	"${SCRIPT_DIR}/ai-review.sh" \
		--project "${PROJECT_REL}" \
		--task "${TASK_ID}" \
		--output "${review_prompt_file}"
	echo "[STEP 6] ✓ Prompt review generato: ${review_prompt_file}"
	echo ""

	echo "[STEP 7] Snapshot git:"
	git -C "${REPO_ROOT}" status --short
	echo ""
	git -C "${REPO_ROOT}" diff --stat -- "${PROJECT_REL}"
	echo ""

	echo "[STEP 8] Scrittura log ciclo..."
	"${SCRIPT_DIR}/ai-cycle-log.sh" \
		--project "${PROJECT_REL}" \
		--task "${TASK_ID}" \
		--command "ai-cycle.sh --project ${PROJECT_REL} --task ${TASK_ID} --run" \
		--agent-result "completato (timeout 300s non raggiunto)" \
		--tests-result "PASS" \
		--prompt-file "${cursor_prompt_file}" \
		--review-file "${review_prompt_file}" \
		--commit-note "Nessun commit da questo ciclo: commit locale solo dopo review APPROVED via scripts/commit-if-approved.sh."
	echo ""

	echo "[RUN] Ciclo completato."
	echo "[RUN] Leggi il diff e il prompt di review: ${review_prompt_file}"
	echo "[RUN] Commit con: scripts/commit-if-approved.sh dopo review APPROVED."
	echo "[RUN] NON è stato eseguito alcun commit, push o merge."
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

if [[ "${DRY_RUN}" -eq 1 ]]; then
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

[STEP 7] Scrivi log ciclo
  ./scripts/ai-cycle-log.sh \\
    --project ${PROJECT_REL} \\
    --task ${TASK_ID} \\
    --tests-result PASS \\
    --prompt-file /tmp/cursor-prompt-${TASK_ID}.md \\
    --review-file /tmp/review-prompt-${TASK_ID}.md
  # → logs/ai-cycles/YYYYMMDD-HHMMSS-${TASK_ID}.md

[STEP 8] (manuale) Commit locale solo se review APPROVED
  ./scripts/commit-if-approved.sh \\
    --project ${PROJECT_REL} \\
    --task ${TASK_ID} \\
    --review-file /tmp/review-prompt-${TASK_ID}.md

[DRY-RUN] Fine. Nessuna modifica effettuata.
[DRY-RUN] Eseguire i comandi mostrati nell'ordine indicato.
EOF
else
	run_cycle
fi
