#!/usr/bin/env bash
# Crea un commit LOCALE controllato solo se una review strutturata lo consente.
#
# Legge il verdetto macchina-leggibile prodotto da scripts/ai-review.sh
# (vedi il blocco REVIEW_VERDICT/.../COMMIT_READY) e autorizza il commit
# soltanto quando TUTTE queste condizioni sono vere:
#   REVIEW_VERDICT: APPROVED
#   TESTS: PASS
#   SECURITY_GUARDRAILS: OK
#   COMMIT_READY: YES
#
# Non fa MAI push, MAI merge, non opera su 'main'. Non esegue reset/clean.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
	cat <<EOF
Usage: $(basename "$0") --project NAME|PATH --task ID --review-file FILE
                        [--paths "p1 p2 ..."] [--message MSG] [--dry-run]
       $(basename "$0") --help

Create a controlled LOCAL commit only if a structured review approves it.

Options:
  --project NAME|PATH  project name (e.g. ai-cycle-dogfood) or path
                       (e.g. projects/ai-cycle-dogfood or '.'). Used as context
                       and as default staging path.
  --task ID            task ID being committed (e.g. TASK-001)
  --review-file FILE   path to the filled review containing the verdict block
  --paths "..."        space-separated paths to stage (default: project path)
  --message MSG        explicit commit message (default: generated)
  --dry-run            validate and show what would happen, do NOT commit
  --help, -h           show this help and exit

The commit is allowed ONLY if the review file contains:
  REVIEW_VERDICT: APPROVED, TESTS: PASS, SECURITY_GUARDRAILS: OK, COMMIT_READY: YES
It is blocked on CHANGES_REQUESTED, BLOCKED, TESTS: FAIL, TESTS: NOT_RUN,
COMMIT_READY: NO, or any missing marker.

Guardrails: never push, never merge, never runs on 'main', refuses an empty
working tree, requires an existing review file. No reset/clean.
EOF
}

error() {
	printf "ERROR: %s\n" "$*" >&2
	exit 1
}

# Estrae il valore concreto di un marker dal review file.
# Considera solo righe con un singolo token ALLCAPS (esclude le righe di
# legenda del tipo "KEY: A | B | C") e prende l'ultima occorrenza valida.
extract_marker() {
	local key="$1" file="$2"
	# '|| true' evita che grep-senza-match faccia fallire il pipeline sotto
	# 'set -o pipefail': un marker assente deve produrre stringa vuota (poi
	# intercettata come blocco esplicito), non un'uscita silenziosa.
	{
		grep -E "^${key}:[[:space:]]*[A-Z_]+[[:space:]]*$" "${file}" 2>/dev/null |
			tail -n 1 |
			sed -E "s/^${key}:[[:space:]]*//; s/[[:space:]]+$//"
	} || true
}

# ── Argument parsing ──────────────────────────────────────────────────────────

PROJECT_INPUT=""
TASK_ID=""
REVIEW_FILE=""
PATHS=""
MESSAGE=""
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
	--review-file)
		[[ $# -ge 2 ]] || error "--review-file requires a value."
		REVIEW_FILE="$2"
		shift 2
		;;
	--paths)
		[[ $# -ge 2 ]] || error "--paths requires a value."
		PATHS="$2"
		shift 2
		;;
	--message)
		[[ $# -ge 2 ]] || error "--message requires a value."
		MESSAGE="$2"
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
[[ -n "${REVIEW_FILE}" ]] || error "--review-file is required."

# ── Resolve project path ──────────────────────────────────────────────────────

if [[ -d "${PROJECT_INPUT}" ]]; then
	PROJECT_REL="${PROJECT_INPUT#"${REPO_ROOT}"/}"
elif [[ -d "${REPO_ROOT}/${PROJECT_INPUT}" ]]; then
	PROJECT_REL="${PROJECT_INPUT}"
elif [[ -d "${REPO_ROOT}/projects/${PROJECT_INPUT}" ]]; then
	PROJECT_REL="projects/${PROJECT_INPUT}"
else
	error "Project not found: '${PROJECT_INPUT}' (looked for dir, ./\$input, projects/\$input)."
fi

[[ -f "${REVIEW_FILE}" ]] || error "Review file not found: '${REVIEW_FILE}'."

[[ -z "${PATHS}" ]] && PATHS="${PROJECT_REL}"

# ── Git preconditions ─────────────────────────────────────────────────────────

current_branch="$(git -C "${REPO_ROOT}" branch --show-current)"
[[ "${current_branch}" != "main" ]] ||
	error "Refusing to commit on 'main'. Switch to a task branch first."

[[ -n "$(git -C "${REPO_ROOT}" status --short)" ]] ||
	error "Working tree is clean: nothing to commit."

# ── Parse and validate the review verdict ─────────────────────────────────────

verdict="$(extract_marker "REVIEW_VERDICT" "${REVIEW_FILE}")"
tests="$(extract_marker "TESTS" "${REVIEW_FILE}")"
security="$(extract_marker "SECURITY_GUARDRAILS" "${REVIEW_FILE}")"
commit_ready="$(extract_marker "COMMIT_READY" "${REVIEW_FILE}")"

echo "== Verdetto review letto da: ${REVIEW_FILE} =="
printf "  REVIEW_VERDICT:      %s\n" "${verdict:-<assente>}"
printf "  TESTS:               %s\n" "${tests:-<assente>}"
printf "  SECURITY_GUARDRAILS: %s\n" "${security:-<assente>}"
printf "  COMMIT_READY:        %s\n" "${commit_ready:-<assente>}"
echo ""

blockers=()
[[ "${verdict}" == "APPROVED" ]] || blockers+=("REVIEW_VERDICT must be APPROVED (got '${verdict:-<assente>}').")
[[ "${tests}" == "PASS" ]] || blockers+=("TESTS must be PASS (got '${tests:-<assente>}').")
[[ "${security}" == "OK" ]] || blockers+=("SECURITY_GUARDRAILS must be OK (got '${security:-<assente>}').")
[[ "${commit_ready}" == "YES" ]] || blockers+=("COMMIT_READY must be YES (got '${commit_ready:-<assente>}').")

if [[ ${#blockers[@]} -gt 0 ]]; then
	printf "COMMIT BLOCCATO. Motivi:\n" >&2
	for b in "${blockers[@]}"; do
		printf "  - %s\n" "${b}" >&2
	done
	exit 1
fi

echo "Verdetto conforme: commit consentito."
echo ""

# ── Stage and show what will be committed ─────────────────────────────────────

# shellcheck disable=SC2086 # PATHS is intentionally word-split into path args.
git -C "${REPO_ROOT}" add -- ${PATHS}

staged="$(git -C "${REPO_ROOT}" diff --cached --name-status)"
[[ -n "${staged}" ]] || error "Nothing staged from paths: ${PATHS}. Check --paths."

echo "== git status --short =="
git -C "${REPO_ROOT}" status --short
echo ""
echo "== File che entreranno nel commit =="
printf "%s\n" "${staged}"
echo ""

[[ -n "${MESSAGE}" ]] || MESSAGE="Add implementation for ${TASK_ID} in ${PROJECT_REL}"

if [[ "${DRY_RUN}" -eq 1 ]]; then
	echo "[DRY-RUN] Commit consentito ma NON eseguito."
	echo "[DRY-RUN] Messaggio: ${MESSAGE}"
	echo "[DRY-RUN] Nessun push, nessun merge."
	exit 0
fi

git -C "${REPO_ROOT}" commit -m "${MESSAGE}"
echo ""
echo "Commit locale creato su branch '${current_branch}'. Nessun push, nessun merge."
