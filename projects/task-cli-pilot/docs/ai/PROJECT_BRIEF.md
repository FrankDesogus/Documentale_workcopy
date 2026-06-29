# Project Brief — task-cli-pilot

## Nome del progetto

task-cli-pilot

## Descrizione

CLI Python per la gestione di una lista di task personali, salvata su file JSON locale.
Secondo progetto pilota della AI Software Station — usato per validare il workflow multi-agente
con Cursor come implementatore e Claude Code + OneAI come reviewer.

## Obiettivi principali

- Implementare i comandi `add`, `list`, `done`, `delete`, `clear`, `--version`.
- Persistere i task su `tasks.json` nella directory corrente.
- Validare il ciclo multi-agente: OneAI decompone i task, Cursor implementa, Claude Code e OneAI fanno review.

## Non-obiettivi

- Nessuna interfaccia grafica o TUI.
- Nessuna sincronizzazione remota.
- Nessuna autenticazione o multi-utente.
- Nessuna dipendenza esterna (no pip install).

## Utenti e contesto

Operatore locale che vuole una CLI minimale per tenere traccia di task durante una sessione di lavoro.
Contesto: stazione AI, ambiente Linux, Python già disponibile.

## Vincoli tecnici

- Solo Python standard library: `argparse`, `json`, `sys`, `pathlib`.
- Python 3.8+ compatibile.
- Nessun database, nessuna rete, nessuna GUI.
- Nessun pacchetto installabile.

## Criteri di successo

- Tutti i comandi previsti funzionano con exit code 0.
- Errori su ID non trovato: exit code 1 con messaggio chiaro su stderr.
- `scripts/test.sh` passa al 100%.
- Review Claude Code + OneAI: Approvato.

## Stato

In sviluppo

## Data ultima revisione

2026-06-29
