#!/usr/bin/env bash
# Genera un prompt di review per Claude Code a partire da progetto e task ID.
# Non chiama agenti AI, non modifica file, non esegue operazioni Git.
# L'operatore incolla l'output in Claude Code per avviare la review.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
	cat <<EOF
Usage: $(basename "$0") --project PATH --task ID (--output FILE | --stdout)
       $(basename "$0") --help

Generate a Claude Code review prompt for a given project and task.

Options:
  --project PATH   path to the project directory (e.g. projects/log-analyzer)
  --task ID        task ID to review (e.g. TASK-004)
  --output FILE    write the prompt to FILE
  --stdout         print the prompt to stdout
  --help, -h       show this help and exit

Exactly one of --output or --stdout is required.
No agents, Git operations, or file modifications are performed.
EOF
}

error() {
	printf "ERROR: %s\n" "$*" >&2
	exit 1
}

generate_prompt() {
	local project_path="$1"
	local task_id="$2"
	local branch="$3"
	local date
	date="$(date +%Y-%m-%d)"

	cat <<EOF
# Review richiesta — ${task_id} — ${project_path}

> Documento generato da \`scripts/ai-review.sh\` il ${date}.
> Incollare questo prompt in Claude Code per avviare la review.

---

## Contesto operativo

| Campo | Valore |
|-------|--------|
| **Repository** | \`${REPO_ROOT}\` |
| **Branch** | \`${branch}\` |
| **Progetto** | \`${project_path}\` |
| **Task** | \`${task_id}\` |

---

## Sei Claude Code nel repository: ${REPO_ROOT}

Branch corrente: \`${branch}\`
Progetto da revisionare: \`${project_path}\`
Task da revisionare: \`${task_id}\`

---

## File da leggere prima di procedere

Leggi i seguenti file del progetto:

- \`${project_path}/AGENTS.md\`
- \`${project_path}/CLAUDE.md\`
- \`${project_path}/docs/ai/TASKS.md\`
- \`${project_path}/docs/ai/RUN_LOG.md\`
- \`${project_path}/docs/ai/REVIEW_LOG.md\`
- \`${project_path}/scripts/test.sh\`

---

## Comandi di verifica da eseguire

Esegui nell'ordine e usa gli output per compilare il verdetto:

\`\`\`bash
git status --short
git diff -- ${project_path}
cd ${project_path} && ./scripts/test.sh
cd -
\`\`\`

Devi verificare concretamente, in questo ordine:

1. **SCOPE** — \`git diff --stat\` e \`git status --short\`: il diff tocca solo file
   attesi per \`${task_id}\`? Nessun file fuori da \`${project_path}\`? Nessun refactoring
   non richiesto?
2. **TESTS** — \`./scripts/test.sh\` è stato eseguito e chiude con exit 0? Se non l'hai
   eseguito, lo stato è \`NOT_RUN\` (non assumere PASS).
3. **SECURITY_GUARDRAILS** — nel diff non ci sono secret/credenziali, né comandi Git
   distruttivi o automazioni pericolose (\`push\`, \`merge\`, \`reset --hard\`,
   \`clean\`, \`branch -D\`), né installazioni di pacchetti o accessi di rete.
4. **DOCS_LOGS** — \`RUN_LOG.md\`, \`REVIEW_LOG.md\`, \`TASKS.md\` aggiornati se il task
   lo richiede; \`NOT_NEEDED\` solo se il task non comporta cambi funzionali.

Se i test falliscono, riporta l'output completo e fermati (TESTS: FAIL).

---

## Checklist review

Verifica ogni punto prima di emettere il verdetto:

**Scope:**
- [ ] Il diff riguarda solo il task \`${task_id}\`
- [ ] Nessuna feature aggiunta fuori scope
- [ ] Nessun refactoring non richiesto

**Qualità tecnica:**
- [ ] Solo Python standard library (se applicabile)
- [ ] Nessuna dipendenza esterna introdotta
- [ ] Nessun secret o credenziale nel codice
- [ ] Nessuna automazione Git pericolosa nel codice o nei test

**Test:**
- [ ] I test coprono il comportamento introdotto dal task
- [ ] I test passano tutti (exit 0)
- [ ] shellcheck e shfmt passano (se script bash)

**Documentazione:**
- [ ] \`RUN_LOG.md\` aggiornato con entry per \`${task_id}\`
- [ ] \`REVIEW_LOG.md\` aggiornato con entry per \`${task_id}\`
- [ ] \`TASKS.md\` aggiornato (task spostato in Completati con hash commit)
- [ ] Deviazioni del workflow documentate nei log

---

## Esito — VERDETTO MACCHINA-LEGGIBILE (obbligatorio)

Concludi SEMPRE la review con esattamente questo blocco, come ultima cosa
dell'output, senza testo dopo. I valori devono essere uno degli ammessi.
Questo blocco viene letto da \`scripts/commit-if-approved.sh\` per decidere se
un commit locale è consentito.

\`\`\`
REVIEW_VERDICT: APPROVED | CHANGES_REQUESTED | BLOCKED
SCOPE: OK | ISSUES
TESTS: PASS | FAIL | NOT_RUN
SECURITY_GUARDRAILS: OK | ISSUES
DOCS_LOGS: OK | ISSUES | NOT_NEEDED
COMMIT_READY: YES | NO
\`\`\`

Regole di coerenza (rispettale sempre):

- \`COMMIT_READY: YES\` è ammesso **solo** se contemporaneamente
  \`REVIEW_VERDICT: APPROVED\`, \`TESTS: PASS\` e \`SECURITY_GUARDRAILS: OK\`.
- \`REVIEW_VERDICT: APPROVED\` **non basta**: se \`COMMIT_READY\` è \`NO\`, il commit
  non è consentito.
- \`TESTS: NOT_RUN\` o \`TESTS: FAIL\` ⇒ \`COMMIT_READY: NO\`.
- \`SECURITY_GUARDRAILS: ISSUES\` o \`SCOPE: ISSUES\` ⇒ \`REVIEW_VERDICT\` diverso da
  \`APPROVED\` e \`COMMIT_READY: NO\`.
- Se ci sono problemi risolvibili dall'implementatore usa \`CHANGES_REQUESTED\`;
  usa \`BLOCKED\` per problemi che impediscono di procedere.

Prima del blocco, riassumi in prosa il perché di ciascun valore.

---

## Se COMMIT_READY: YES — commit locale controllato

Non fare push, non fare merge. Usa l'helper che rilegge il verdetto e blocca
i casi non conformi:

\`\`\`bash
./scripts/commit-if-approved.sh \\
  --project ${project_path} \\
  --task ${task_id} \\
  --review-file <file-di-questa-review>
\`\`\`

In alternativa, commit manuale equivalente (solo se il verdetto lo consente):

\`\`\`bash
git add ${project_path}
git commit -m "Add implementation for ${task_id} in ${project_path}"
\`\`\`

---

## Divieti assoluti

Non fare push, merge, reset o operazioni distruttive. In dettaglio:

- \`git push\`
- \`git merge\`
- \`git reset --hard\`
- \`git clean\`
- \`git branch -D\`
- Lancio di Cursor Agent
- Lancio di Claude da shell
- Installazione di pacchetti
- Accesso alla rete
- Modifica di file fuori da \`${project_path}\`
- Procedere al task successivo senza istruzione esplicita dell'operatore

---

## Prossimo passo per l'operatore

Dopo aver ricevuto l'esito da Claude Code:

- Se **APPROVED**: verifica il commit locale, poi decidi tu se e quando mergiare su main.
- Se **BLOCKED**: correggi i problemi segnalati e ri-esegui questo script per una nuova review.
EOF
}

# ── Argument parsing ──────────────────────────────────────────────────────────

PROJECT=""
TASK_ID=""
OUTPUT=""
TO_STDOUT=0

while [[ $# -gt 0 ]]; do
	case "$1" in
	--help | -h)
		usage
		exit 0
		;;
	--project)
		[[ $# -ge 2 ]] || error "--project requires a value."
		PROJECT="$2"
		shift 2
		;;
	--task)
		[[ $# -ge 2 ]] || error "--task requires a value."
		TASK_ID="$2"
		shift 2
		;;
	--output)
		[[ $# -ge 2 ]] || error "--output requires a value."
		OUTPUT="$2"
		shift 2
		;;
	--stdout)
		TO_STDOUT=1
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

[[ -n "${PROJECT}" ]] || error "--project is required."
[[ -n "${TASK_ID}" ]] || error "--task is required."

if [[ "${TO_STDOUT}" -eq 0 && -z "${OUTPUT}" ]]; then
	error "Specify --output FILE or --stdout."
fi

PROJECT_ABS="${REPO_ROOT}/${PROJECT}"
[[ -d "${PROJECT_ABS}" ]] || error "Project directory not found: '${PROJECT_ABS}'"

BRANCH="$(git -C "${REPO_ROOT}" branch --show-current 2>/dev/null || echo "unknown")"

PROMPT="$(generate_prompt "${PROJECT}" "${TASK_ID}" "${BRANCH}")"

if [[ -n "${OUTPUT}" ]]; then
	printf "%s\n" "${PROMPT}" >"${OUTPUT}" || error "Cannot write to '${OUTPUT}'."
	printf "Review prompt written to %s\n" "${OUTPUT}"
fi

if [[ "${TO_STDOUT}" -eq 1 ]]; then
	printf "%s\n" "${PROMPT}"
fi
