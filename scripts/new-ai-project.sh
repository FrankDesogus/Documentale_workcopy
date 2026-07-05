#!/usr/bin/env bash
# Scaffold rapido e leggero per un nuovo progetto AI-ready sotto projects/.
# Crea README.md, docs/ai/TASKS.md (da template) e scripts/test.sh placeholder.
# Non fa git add né commit: la revisione resta all'operatore.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECTS_DIR="${REPO_ROOT}/projects"
TASKS_TEMPLATE="${REPO_ROOT}/docs/templates/TASKS.template.md"

usage() {
	cat <<EOF
Usage: $(basename "$0") --name NAME --title "Titolo" [--title "Titolo"]
       $(basename "$0") --help

Crea uno scaffold minimo AI-ready in projects/<name>/:
  README.md
  docs/ai/TASKS.md   (da docs/templates/TASKS.template.md)
  scripts/test.sh    (placeholder eseguibile, exit 0)

Options:
  --name NAME    nome del progetto (lettere, cifre, - e _; no spazi/slash)
  --title TITLE  titolo leggibile del progetto, usato in README.md
  --help, -h     show this help and exit

Non sovrascrive un progetto già esistente. Non esegue git add né commit.
EOF
}

error() {
	printf "ERROR: %s\n" "$*" >&2
	exit 1
}

validate_project_name() {
	local name="$1"
	[[ -n "${name}" ]] || error "Project name cannot be empty."
	[[ "${name}" != */* ]] || error "Project name cannot contain slashes."
	[[ "${name}" != *..* ]] || error "Project name cannot contain '..'."
	[[ "${name}" != -* ]] || error "Project name cannot start with a hyphen."
	[[ "${name}" =~ ^[a-zA-Z0-9_-]+$ ]] ||
		error "Project name '${name}' contains invalid characters. Use only letters, digits, hyphens and underscores."
}

NAME=""
TITLE=""

while [[ $# -gt 0 ]]; do
	case "$1" in
	--help | -h)
		usage
		exit 0
		;;
	--name)
		[[ $# -ge 2 ]] || error "--name requires a value."
		NAME="$2"
		shift 2
		;;
	--title)
		[[ $# -ge 2 ]] || error "--title requires a value."
		TITLE="$2"
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

[[ -n "${NAME}" ]] || error "--name is required. Use --help for usage."
[[ -n "${TITLE}" ]] || error "--title is required. Use --help for usage."

validate_project_name "${NAME}"
[[ -f "${TASKS_TEMPLATE}" ]] || error "Template not found: ${TASKS_TEMPLATE#"${REPO_ROOT}/"}"

DEST="${PROJECTS_DIR}/${NAME}"
[[ ! -e "${DEST}" ]] || error "Directory already exists: ${DEST#"${REPO_ROOT}/"}. Will not overwrite."

printf "== Creating AI-ready project: %s ==\n\n" "${NAME}"

mkdir -p "${DEST}/docs/ai" "${DEST}/scripts"

cat >"${DEST}/README.md" <<EOF
# ${TITLE}

Progetto creato con \`scripts/new-ai-project.sh\`.

Descrivi qui in poche righe cosa fa questo progetto.

## Sviluppo

\`\`\`bash
./scripts/test.sh
\`\`\`

Task e workflow AI: vedi \`docs/ai/TASKS.md\`.
EOF
printf "  created: %s\n" "${DEST#"${REPO_ROOT}/"}/README.md"

cp "${TASKS_TEMPLATE}" "${DEST}/docs/ai/TASKS.md"
printf "  created: %s\n" "${DEST#"${REPO_ROOT}/"}/docs/ai/TASKS.md"

cat >"${DEST}/scripts/test.sh" <<EOF
#!/usr/bin/env bash
# PLACEHOLDER — nessun test ancora configurato per questo progetto.
set -euo pipefail

echo "== Test: ${NAME} =="
echo "Nessun test ancora configurato per questo progetto."
echo "Sostituire questo script con il comando di test reale (pytest, npm test, ...)."
exit 0
EOF
chmod +x "${DEST}/scripts/test.sh"
printf "  created: %s (executable)\n" "${DEST#"${REPO_ROOT}/"}/scripts/test.sh"

printf "\n== Done ==\n\n"
printf "Progetto '%s' creato in: %s\n" "${NAME}" "${DEST#"${REPO_ROOT}/"}"
printf "\nProssimi comandi consigliati:\n"
printf "  1. Editare %s/docs/ai/TASKS.md e aggiungere un task in Backlog.\n" "${DEST#"${REPO_ROOT}/"}"
printf "  2. ./scripts/station-next-task.sh --project %s\n" "${NAME}"
printf "  3. ./scripts/ai-cycle.sh --project %s --task TASK-XXX --dry-run\n" "${NAME}"
