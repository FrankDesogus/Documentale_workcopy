#!/usr/bin/env bash
# Wrapper per cursor-prompt-builder: genera un prompt operativo per Cursor Agent
# a partire da un task documentato in TASKS.md.
#
# Uso: ./scripts/cursor-prompt.sh --project projects/<nome> --task TASK-XXX [--output FILE]
#      Nota: usare su task in Backlog o In corso. Sui task già Completati
#      alcune colonne (es. "Agente previsto") possono essere assenti.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

exec python "${REPO_ROOT}/projects/cursor-prompt-builder/prompt_builder.py" "$@"
