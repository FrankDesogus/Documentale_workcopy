#!/usr/bin/env bash
# Controlli reali e sicuri per documentale-workcopy (Django).
# Nessuna rete, nessuna installazione pacchetti, nessun DB reale, nessun server.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TEST_SETTINGS="${TEST_SETTINGS:-config.test_settings}"
REQUIREMENTS_FILE="${PROJECT_ROOT}/requirements.txt"

usage() {
	cat <<EOF
Usage: $(basename "$0") [--help]

Esegue controlli reali e sicuri sul Django importato in questa copia:
  0) verifica che le dipendenze di requirements.txt siano importabili;
  1) python -m compileall (sintassi di tutto il codice);
  2) manage.py check (settings di test, nessun .env reale);
  3) manage.py test (SQLite :memory:, nessun database reale).

Se le dipendenze non sono installate nell'interprete Python in uso, lo
script fallisce (exit 1) con un elenco chiaro: NON le installa mai da solo
e NON esegue in quel caso la suite Django reale. Questo è un blocco di
ambiente, non un'indicazione di bug nel codice applicativo. Vedi
docs/ai/TESTING_STATUS.md per lo stato dettagliato della validazione.

Nessuna rete, nessuna installazione pacchetti, nessun database reale,
nessun server avviato, nessuna migrazione reale eseguita.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
	usage
	exit 0
fi
[[ $# -eq 0 ]] || {
	echo "ERRORE: opzione non riconosciuta: '$1'. Usa --help." >&2
	exit 1
}

cd "${PROJECT_ROOT}"

fail() {
	echo "ERRORE: $*" >&2
	exit 1
}

step() {
	echo ""
	echo "== $1 =="
}

if command -v python3 >/dev/null 2>&1; then
	PYTHON=python3
elif command -v python >/dev/null 2>&1; then
	PYTHON=python
else
	fail "Python non trovato. Installare Python 3 e le dipendenze elencate in requirements.txt."
fi

echo "== Test: documentale-workcopy =="
echo "Root progetto: ${PROJECT_ROOT}"
echo "Python: $($PYTHON --version 2>&1)"
echo "Settings di test: ${TEST_SETTINGS}"

if [[ ! -f "${REQUIREMENTS_FILE}" ]]; then
	fail "File requirements.txt non trovato in ${PROJECT_ROOT}."
fi

# ---------------------------------------------------------------------------
# 0) Verifica dipendenze (requirements.txt) — fallisce se manca qualcosa
# ---------------------------------------------------------------------------
step "0/3 — Verifica dipendenze Python (requirements.txt)"

declare -A CHECKED_IMPORTS=()
missing=()

while IFS= read -r line || [[ -n "${line}" ]]; do
	line="${line%%#*}"
	line="${line// /}"
	[[ -z "${line}" ]] && continue

	pkg="${line%%==*}"
	pkg="${pkg%%>=*}"
	pkg="${pkg%%\[*}"

	case "${pkg}" in
	Django) import_name="django" ;;
	Pillow | pillow) import_name="PIL" ;;
	python-decouple) import_name="decouple" ;;
	django-filter) import_name="django_filters" ;;
	djangorestframework) import_name="rest_framework" ;;
	psycopg | psycopg-binary) import_name="psycopg" ;;
	asgiref | gunicorn | sqlparse | tzdata) import_name="${pkg}" ;;
	*) import_name="${pkg}" ;;
	esac

	[[ -n "${CHECKED_IMPORTS[${import_name}]+x}" ]] && continue
	CHECKED_IMPORTS["${import_name}"]=1

	if ! "${PYTHON}" -c "import ${import_name}" >/dev/null 2>&1; then
		missing+=("${pkg} (import ${import_name})")
	fi
done <"${REQUIREMENTS_FILE}"

if [[ ${#missing[@]} -gt 0 ]]; then
	echo "" >&2
	echo "BLOCCO AMBIENTE — non è un bug del codice applicativo del Documentale." >&2
	echo "Dipendenze Python mancanti in questo interprete (${PYTHON}):" >&2
	for dep in "${missing[@]}"; do
		echo "  - ${dep}" >&2
	done
	echo "" >&2
	echo "Questo script NON installa dipendenze automaticamente (per design)." >&2
	echo "Serve un ambiente Python dedicato con:" >&2
	echo "  pip install -r requirements.txt" >&2
	echo "" >&2
	echo "Di conseguenza la suite Django reale (manage.py check / test) NON" >&2
	echo "è stata eseguita in questo run. Stato dettagliato della validazione:" >&2
	echo "  docs/ai/TESTING_STATUS.md" >&2
	fail "Controlli Django reali non eseguibili: ambiente senza le dipendenze installate."
fi

echo "OK — dipendenze di requirements.txt importabili."

# ---------------------------------------------------------------------------
# 1) Compilazione / sintassi Python su tutto il codice del progetto
# ---------------------------------------------------------------------------
step "1/3 — Compilazione e sintassi Python"

echo "Esecuzione: python -m compileall (esclusi .git, venv, node_modules, cache)"
if ! "${PYTHON}" -m compileall -q \
	-x '/(\.git|__pycache__|staticfiles|node_modules|\.venv|venv|media)/' \
	"${PROJECT_ROOT}"; then
	fail "Compilazione Python fallita: errori di sintassi nel codice."
fi

echo "OK — compilazione/sintassi Python superata."

# ---------------------------------------------------------------------------
# 2) manage.py check con settings di test sicuri
# ---------------------------------------------------------------------------
step "2/3 — Django manage.py check (settings di test, no .env)"

export DJANGO_SETTINGS_MODULE="${TEST_SETTINGS}"
export SECRET_KEY="test-secret-key-not-for-production-use-only"

if ! "${PYTHON}" -c "import django; print('Django', django.get_version())" >/dev/null 2>&1; then
	fail "Django non importabile nonostante il controllo dipendenze."
fi

echo "Esecuzione: manage.py check --settings=${TEST_SETTINGS}"
if ! "${PYTHON}" manage.py check --settings="${TEST_SETTINGS}"; then
	fail "manage.py check fallito."
fi

echo "OK — manage.py check superato."

# ---------------------------------------------------------------------------
# 3) manage.py test con SQLite in memoria
# ---------------------------------------------------------------------------
step "3/3 — Django manage.py test (SQLite :memory:, no migrate/runserver)"

echo "Esecuzione: manage.py test --settings=${TEST_SETTINGS}"
if ! "${PYTHON}" manage.py test --settings="${TEST_SETTINGS}" -v 1; then
	fail "manage.py test fallito."
fi

echo "OK — manage.py test superato."

echo ""
echo "Tutti i controlli completati con successo."
exit 0
