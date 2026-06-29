# Project Brief

## Nome del progetto

`station-summary`

## Descrizione

Tool CLI Python che genera un report markdown dello stato dell'AI Software Station.
Rileva i progetti presenti in `projects/`, gli helper in `scripts/`, e produce
un riepilogo leggibile da terminale o salvabile su file.

## Obiettivi principali

- Rilevare automaticamente i progetti sotto `projects/` e mostrarne il nome.
- Rilevare gli helper principali disponibili in `scripts/`.
- Produrre un report markdown strutturato e leggibile.
- Supportare output su stdout (default) e su file (`--output FILE`).

## Non-obiettivi

- Non interroga API esterne.
- Non fa analisi del codice sorgente dei progetti.
- Non gestisce autenticazione o credenziali.
- Non modifica file del repository.

## Utenti e contesto

Operatore della AI Software Station (Frank) che vuole una panoramica rapida
dello stato della stazione, da terminale o da file markdown.

## Vincoli tecnici

- Python 3, solo stdlib (nessuna dipendenza esterna).
- Compatibile con l'ambiente della stazione (Linux/bash).
- Entry point: `summary.py` nella root del progetto.
- Test: `scripts/test.sh` (bash, shellcheck e shfmt se disponibili).

## Criteri di successo

- `python summary.py --help` e `--version` funzionano senza errori.
- Il report elenca correttamente progetti e helper della stazione.
- `scripts/test.sh` esce con codice 0.
- Nessuna dipendenza esterna installata.

## Stato

Stato: In sviluppo

## Data ultima revisione

2026-06-29
