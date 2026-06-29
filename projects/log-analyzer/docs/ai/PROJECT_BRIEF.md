# Project Brief — log-analyzer

## Obiettivo

CLI Python che scansiona i progetti sotto `projects/` e produce un riepilogo testuale dello
stato di ogni progetto: quanti task sono in backlog, in corso o completati; qual è l'esito
dell'ultimo run e dell'ultima review.

## Motivazione

Con l'aumentare dei progetti nella stazione, controllare manualmente `TASKS.md`,
`RUN_LOG.md` e `REVIEW_LOG.md` di ogni progetto diventa ripetitivo.
`log-analyzer` aggrega queste informazioni in una singola vista.

## Scope

- Parsing di `docs/ai/TASKS.md` per conteggi task per sezione.
- Parsing di `docs/ai/RUN_LOG.md` per l'ultima entry di run.
- Parsing di `docs/ai/REVIEW_LOG.md` per l'ultima entry di review.
- Output testuale su stdout (o su file con `--output`).
- Filtro per singolo progetto con `--project`.
- Directory radice configurabile con `--projects-dir`.

## Non-scope

- Nessuna GUI o interfaccia web.
- Nessuna scrittura o modifica dei file analizzati.
- Nessuna integrazione con agenti AI o rete.
- Nessun parsing di file Git (log, diff, blame).
- Nessun output JSON in questa versione.

## Vincoli

- Solo Python standard library.
- Nessuna dipendenza esterna.
- Singolo file `log_analyzer.py`.
- Compatibile Python 3.8+.
