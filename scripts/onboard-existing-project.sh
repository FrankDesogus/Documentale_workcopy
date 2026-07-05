#!/usr/bin/env bash
# Importa un progetto software esistente dentro projects/<name>/ e aggiunge la
# struttura AI minima (docs/ai/TASKS.md, scripts/test.sh) se assente.
# Non modifica il progetto sorgente, non installa dipendenze, non esegue
# codice del progetto importato, non fa git add né commit.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECTS_DIR="${REPO_ROOT}/projects"
ONBOARD_TASKS_TEMPLATE="${REPO_ROOT}/docs/templates/PROJECT_ANALYSIS_TASK.md"

# Nomi di directory escluse dalla copia, ovunque si trovino nell'albero
# sorgente (case-sensitive, match sul nome esatto della directory):
#   - version control, ambienti virtuali, cache di build/lint/test;
#   - cartelle di upload/media con probabili dati reali di utenti.
# "files/" è deliberatamente ESCLUSA da questa lista: nome troppo generico,
# alto rischio di rimuovere codice sorgente legittimo. Se un progetto reale
# tiene upload reali in una cartella dal nome non standard, va rimossa
# manualmente dopo l'onboarding (vedi RUNBOOK).
EXCLUDE_DIR_NAMES=(
	.git .venv venv env node_modules __pycache__ .pytest_cache
	.mypy_cache .ruff_cache .tox dist build
	media uploads upload attachments
)

# Pattern di FILE esclusi dalla copia, ovunque si trovino nell'albero
# sorgente: segreti locali e database SQLite reali. ".env.example" è
# l'unica eccezione esplicita (template, nessun segreto reale).
EXCLUDE_FILE_PATTERNS=(".env" ".env.*" "*.sqlite" "*.sqlite3" "*.db")
EXCLUDE_FILE_EXCEPTIONS=(".env.example")

is_excluded_file_exception() {
	local base="$1" exc
	for exc in "${EXCLUDE_FILE_EXCEPTIONS[@]}"; do
		[[ "${base}" == "${exc}" ]] && return 0
	done
	return 1
}

usage() {
	cat <<EOF
Usage: $(basename "$0") --source PATH --name NAME --title "Titolo"
       $(basename "$0") --help

Importa un progetto software esistente in projects/<name>/ e prepara la
struttura AI minima per usarlo con la Station.

Options:
  --source PATH  percorso della directory del progetto esistente da importare
  --name NAME    nome del nuovo progetto sotto projects/ (lettere, cifre, - e _)
  --title TITLE  titolo leggibile, usato nel TASKS.md generato
  --help, -h     show this help and exit

Comportamento:
  - Copia il contenuto di --source in projects/NAME/, escludendo ricorsivamente
    le directory: ${EXCLUDE_DIR_NAMES[*]}
  - Esclude inoltre ricorsivamente i file: ${EXCLUDE_FILE_PATTERNS[*]}
    (eccetto: ${EXCLUDE_FILE_EXCEPTIONS[*]}, sempre copiato se presente).
  - Non sovrascrive un progetto già esistente in projects/NAME/.
  - Crea docs/ai/TASKS.md (da docs/templates/PROJECT_ANALYSIS_TASK.md) solo se
    non è già presente nel progetto importato.
  - Crea scripts/test.sh (placeholder eseguibile, exit 0) solo se non è già
    presente nel progetto importato.
  - Non modifica il progetto sorgente, non installa dipendenze, non esegue
    codice del progetto importato, non fa git add né commit.
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

# Escapa & / e \ perché il valore va inserito come replacement in sed con delimitatore '/'.
escape_for_sed_replacement() {
	printf '%s' "$1" | sed 's/[&/\]/\\&/g'
}

SOURCE_INPUT=""
NAME=""
TITLE=""

while [[ $# -gt 0 ]]; do
	case "$1" in
	--help | -h)
		usage
		exit 0
		;;
	--source)
		[[ $# -ge 2 ]] || error "--source requires a value."
		SOURCE_INPUT="$2"
		shift 2
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

[[ -n "${SOURCE_INPUT}" ]] || error "--source is required. Use --help for usage."
[[ -n "${NAME}" ]] || error "--name is required. Use --help for usage."
[[ -n "${TITLE}" ]] || error "--title is required. Use --help for usage."

[[ -e "${SOURCE_INPUT}" ]] || error "Source not found: '${SOURCE_INPUT}'"
[[ -d "${SOURCE_INPUT}" ]] || error "Source is not a directory: '${SOURCE_INPUT}'"

validate_project_name "${NAME}"
[[ -f "${ONBOARD_TASKS_TEMPLATE}" ]] ||
	error "Template not found: ${ONBOARD_TASKS_TEMPLATE#"${REPO_ROOT}/"}"

SOURCE_ABS="$(cd "${SOURCE_INPUT}" && pwd)"
DEST="${PROJECTS_DIR}/${NAME}"

[[ ! -e "${DEST}" ]] ||
	error "Directory already exists: ${DEST#"${REPO_ROOT}/"}. Will not overwrite."

case "${DEST}/" in
"${SOURCE_ABS}/"*)
	error "La destinazione (${DEST#"${REPO_ROOT}/"}) risulterebbe dentro la sorgente (${SOURCE_ABS}). Impossibile procedere."
	;;
esac

printf "== Onboarding progetto esistente: %s ==\n\n" "${NAME}"
printf "Sorgente: %s\n" "${SOURCE_ABS}"
printf "Destinazione: %s\n\n" "${DEST#"${REPO_ROOT}/"}"

mkdir -p "${DEST}"
cp -R "${SOURCE_ABS}/." "${DEST}/"
printf "Copiato contenuto sorgente in %s\n" "${DEST#"${REPO_ROOT}/"}"

printf "\nEsclusione directory pesanti/non utili (se presenti):\n"
for dir_name in "${EXCLUDE_DIR_NAMES[@]}"; do
	found=0
	while IFS= read -r -d '' match; do
		found=1
		rm -rf -- "${match}"
	done < <(find "${DEST}" -type d -name "${dir_name}" -prune -print0)
	if [[ "${found}" -eq 1 ]]; then
		printf "  rimossa: %s (ovunque nell'albero copiato)\n" "${dir_name}"
	fi
done

printf "\nEsclusione file sensibili (se presenti):\n"
for pattern in "${EXCLUDE_FILE_PATTERNS[@]}"; do
	removed=0
	while IFS= read -r -d '' match; do
		base="$(basename "${match}")"
		if is_excluded_file_exception "${base}"; then
			continue
		fi
		rm -f -- "${match}"
		removed=1
	done < <(find "${DEST}" -type f -name "${pattern}" -print0)
	if [[ "${removed}" -eq 1 ]]; then
		printf "  rimossi file corrispondenti a: %s (eccetto %s)\n" \
			"${pattern}" "${EXCLUDE_FILE_EXCEPTIONS[*]}"
	fi
done

printf "\nStruttura AI minima:\n"

mkdir -p "${DEST}/docs/ai"
TASKS_MD="${DEST}/docs/ai/TASKS.md"
if [[ -f "${TASKS_MD}" ]]; then
	printf "  docs/ai/TASKS.md: già presente nel progetto sorgente, lasciato invariato.\n"
else
	escaped_name="$(escape_for_sed_replacement "${NAME}")"
	escaped_title="$(escape_for_sed_replacement "${TITLE}")"
	sed -e "s/{{PROJECT_NAME}}/${escaped_name}/g" -e "s/{{PROJECT_TITLE}}/${escaped_title}/g" \
		"${ONBOARD_TASKS_TEMPLATE}" >"${TASKS_MD}"
	printf "  created: %s\n" "${DEST#"${REPO_ROOT}/"}/docs/ai/TASKS.md"
fi

mkdir -p "${DEST}/scripts"
TEST_SH="${DEST}/scripts/test.sh"
if [[ -f "${TEST_SH}" ]]; then
	chmod +x "${TEST_SH}"
	printf "  scripts/test.sh: già presente nel progetto sorgente, reso eseguibile.\n"
else
	cat >"${TEST_SH}" <<EOF
#!/usr/bin/env bash
# PLACEHOLDER — nessun test ancora configurato per questo progetto importato.
set -euo pipefail

echo "== Test: ${NAME} =="
echo "Nessun test ancora configurato per questo progetto."
echo "Sostituire questo script con il comando di test reale (pytest, npm test, ...)."
exit 0
EOF
	chmod +x "${TEST_SH}"
	printf "  created: %s (executable)\n" "${DEST#"${REPO_ROOT}/"}/scripts/test.sh"
fi

printf "\n== Done ==\n\n"
printf "Progetto '%s' importato in: %s\n" "${NAME}" "${DEST#"${REPO_ROOT}/"}"
printf "\nProssimi comandi consigliati:\n"
printf "  ./scripts/station-status.sh\n"
printf "  ./scripts/station-next-task.sh --project %s\n" "${NAME}"
printf "  ./scripts/ai-cycle.sh --project %s --task TASK-001 --run\n" "${NAME}"
