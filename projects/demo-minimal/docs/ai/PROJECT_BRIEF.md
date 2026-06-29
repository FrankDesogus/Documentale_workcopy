# Project Brief — demo-minimal

## Nome del progetto

demo-minimal

## Descrizione

Piccola utility CLI locale in Python (standard library) che stampa un
messaggio di benvenuto. Serve esclusivamente a validare il ciclo di lavoro
AI Software Station: Claude Code (piano) → Codex (task) → Cursor (codice)
→ test → review → commit.

## Obiettivi principali

- Avere un progetto reale, anche minimo, su cui esercitare l'intero flusso.
- Avere un test automatico funzionante (`scripts/test.sh` non più placeholder).
- Produrre almeno un commit frutto di review AI.

## Non-obiettivi

- Non è un'app reale destinata a utenti.
- Non ha dipendenze esterne.
- Non deve essere estesa oltre il necessario per validare il flusso.

## Utenti e contesto

Solo l'operatore della AI Software Station, per esercitare il flusso manuale.

## Vincoli tecnici

- Python 3, standard library only. Nessuna dipendenza esterna.
- Un singolo file `cli.py` nella root del progetto.
- Compatibile con l'ambiente locale (Python 3.14.5 rilevato).

## Criteri di successo

- `python cli.py` stampa `Hello from demo-minimal.` e esce con codice 0.
- `scripts/test.sh` esce con codice 0.
- Il ciclo completo (piano → implementazione → test → review → commit) è
  documentato in `RUN_LOG.md` e `REVIEW_LOG.md`.

## Stato

In preparazione

## Data ultima revisione

2026-06-29
