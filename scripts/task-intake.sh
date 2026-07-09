#!/usr/bin/env bash
# Genera un documento di intake strutturato per un nuovo progetto AI Software Station.
# Non chiama agenti AI, non crea file di progetto, non esegue operazioni Git.
# L'operatore deve revisionare l'output prima di procedere.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
	cat <<EOF
Usage: $(basename "$0") --project-name NAME --title TITLE --request TEXT [--output FILE]
       $(basename "$0") --help

Generate a structured intake Markdown document for a new AI Software Station project.

Options:
  --project-name NAME   Project name (letters, digits, hyphens, underscores).
  --title TITLE         Short descriptive title (quote if it contains spaces).
  --request TEXT        Free-form description of what you want to build.
  --output FILE         Write to FILE instead of stdout.
  --help, -h            Show this help and exit.

No AI agents, Git operations or external tools are invoked.
The operator must review and approve the output before creating the project.
EOF
}

error() {
	printf "ERROR: %s\n" "$*" >&2
	exit 1
}

validate_project_name() {
	local name="$1"
	[[ -n "${name}" ]] || error "--project-name cannot be empty."
	[[ "${name}" != -* ]] || error "--project-name cannot start with a hyphen."
	[[ "${name}" =~ ^[a-zA-Z0-9_-]+$ ]] ||
		error "--project-name '${name}' contains invalid characters. Use letters, digits, hyphens, underscores."
}

generate_intake() {
	local name="$1"
	local title="$2"
	local request="$3"
	local date
	date="$(date +%Y-%m-%d)"

	cat <<EOF
# Intake — ${name}

> Documento generato automaticamente da \`task-intake.sh\` il ${date}.
> **Revisionare e completare ogni sezione prima di procedere.**
> Non creare il progetto senza aver approvato questo intake.

---

## Informazioni di base

| Campo | Valore |
|-------|--------|
| **Nome progetto** | \`${name}\` |
| **Titolo** | ${title} |
| **Data intake** | ${date} |

---

## Richiesta originale

> ${request}

---

## Obiettivo

<!-- Completare: sintetizzare in 1-2 frasi l'obiettivo concreto e misurabile. -->

${title}: ...

---

## Vincoli standard della stazione

- Solo Python standard library o Bash.
- Nessuna dipendenza esterna senza approvazione esplicita.
- Nessun accesso alla rete.
- Nessuna automazione Git (push, merge, reset).
- Nessun commit senza test verdi e review approvata.
- Un branch per task; un task alla volta.

---

## Proposta di task iniziali

<!-- Revisionare: aggiungere, rimuovere o ri-ordinare prima di procedere. -->

| ID | Titolo | Agente previsto | Note |
|----|--------|-----------------|------|
| TASK-001 | Scaffold progetto e test base | Claude Code | Struttura, AGENTS.md, scripts/test.sh |
| TASK-002 | <!-- implementazione principale --> | Cursor Agent | <!-- da definire --> |
| TASK-003 | <!-- funzionalità aggiuntiva --> | Cursor Agent | <!-- da definire --> |
| TASK-004 | Review completa e integrazione workflow | Claude Code + OneAI | Review diff, REVIEW_LOG, merge |

---

## File che Claude Code dovrà creare

Eseguire prima:

\`\`\`bash
./scripts/new-project.sh ${name}
\`\`\`

Poi completare manualmente:

- \`projects/${name}/docs/ai/PROJECT_BRIEF.md\` — obiettivo, motivazione, scope, non-scope
- \`projects/${name}/docs/ai/ARCHITECTURE.md\` — struttura tecnica, componenti, flusso
- \`projects/${name}/docs/ai/TASKS.md\` — task operativi (vedi proposta sopra)
- \`projects/${name}/docs/ai/DECISIONS.md\` — decisioni architetturali iniziali

---

## Guardrail

- L'operatore approva ogni merge su main.
- Nessun push automatico.
- Nessun agente implementa più di un task per sessione senza conferma.
- Fermarsi se i test falliscono.
- Fermarsi se il task è ambiguo o fuori scope.
- Segreti e credenziali non entrano mai nel repository.

---

## Prompt per Claude Code

Incollare il testo seguente a Claude Code per avviare lo scaffold e la definizione dei task:

\`\`\`
Sei Claude Code nel repository: ${REPO_ROOT}

Crea lo scaffold per un nuovo progetto:

  Nome: ${name}
  Titolo: ${title}

Richiesta originale dell'operatore:
  ${request}

Passi da eseguire:
1. Esegui: ./scripts/new-project.sh ${name}
2. Scrivi projects/${name}/docs/ai/PROJECT_BRIEF.md
   con: obiettivo, motivazione, scope, non-scope, vincoli.
3. Scrivi projects/${name}/docs/ai/ARCHITECTURE.md
   con: componenti, struttura file, flusso, dipendenze.
4. Scrivi projects/${name}/docs/ai/TASKS.md
   con 3-5 task operativi, ciascuno implementabile in una sessione Cursor.
5. Verifica con: git status --short
6. Non fare git add né commit: revisione e commit spettano all'operatore.

Vincoli:
- Solo Python standard library o Bash.
- Nessuna dipendenza esterna.
- Nessun accesso alla rete.
- Nessuna automazione Git.
\`\`\`

---

## Note operative

- Revisionare la proposta di task prima di passarla a Claude Code.
- Il progetto viene creato solo dopo approvazione di questo intake.
- Claude Code genera la struttura; Cursor Agent implementa i task.
- Usare \`./scripts/cursor-prompt.sh\` per generare i prompt operativi per Cursor Agent.
EOF
}

# ── Argument parsing ──────────────────────────────────────────────────────────

PROJECT_NAME=""
TITLE=""
REQUEST=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
	case "$1" in
	--help | -h)
		usage
		exit 0
		;;
	--project-name)
		[[ $# -ge 2 ]] || error "--project-name requires a value."
		PROJECT_NAME="$2"
		shift 2
		;;
	--title)
		[[ $# -ge 2 ]] || error "--title requires a value."
		TITLE="$2"
		shift 2
		;;
	--request)
		[[ $# -ge 2 ]] || error "--request requires a value."
		REQUEST="$2"
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

[[ -n "${PROJECT_NAME}" ]] || error "--project-name is required."
[[ -n "${TITLE}" ]] || error "--title is required."
[[ -n "${REQUEST}" ]] || error "--request is required."

validate_project_name "${PROJECT_NAME}"

if [[ -n "${OUTPUT}" ]]; then
	generate_intake "${PROJECT_NAME}" "${TITLE}" "${REQUEST}" >"${OUTPUT}" || {
		printf "Error: cannot write to '%s'\n" "${OUTPUT}" >&2
		exit 1
	}
	printf "Intake written to %s\n" "${OUTPUT}"
else
	generate_intake "${PROJECT_NAME}" "${TITLE}" "${REQUEST}"
fi
