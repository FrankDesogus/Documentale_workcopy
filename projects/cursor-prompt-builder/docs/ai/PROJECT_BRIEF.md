# Project Brief — cursor-prompt-builder

## Nome del progetto

cursor-prompt-builder

## Descrizione

CLI Python che genera prompt operativi per Cursor Agent partendo da un task
documentato in `TASKS.md`. Riduce il copia/incolla manuale e standardizza
il passaggio `TASKS.md → prompt Cursor Agent`.

## Obiettivi principali

- Leggere un `TASKS.md` e estrarre un task per ID.
- Generare un prompt operativo completo per Cursor Agent (repo, branch, scope,
  file da leggere, test da eseguire, stop conditions, guardrail).
- Supportare `--project DIR` e `--tasks-file FILE` come sorgenti alternative.
- Output su stdout (default) o su file con `--output FILE`.

## Non-obiettivi

- Non esegue Cursor Agent.
- Non fa commit, push o merge.
- Non modifica `TASKS.md` o altri file di progetto.
- Nessuna interfaccia grafica.
- Nessun accesso alla rete.

## Utenti e contesto

Operatore della AI Software Station che deve passare task a Cursor Agent.
Ambiente: Linux, Python già disponibile, CLI in terminale.

## Vincoli tecnici

- Solo Python standard library: `argparse`, `pathlib`, `sys`, `re`, `textwrap`.
- Python 3.8+ compatibile.
- Nessuna dipendenza esterna.

## Criteri di successo

- `python prompt_builder.py --project ../task-cli-pilot --task TASK-003`
  produce un prompt completo su stdout.
- `scripts/test.sh` passa al 100%.
- Review Claude Code + OneAI: Approvato.

## Stato

In sviluppo

## Data ultima revisione

2026-06-29
