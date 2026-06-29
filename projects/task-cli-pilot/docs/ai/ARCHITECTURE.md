# Architecture — task-cli-pilot

## Contesto

CLI minimale per gestire una lista di task personali. Singolo file Python, zero dipendenze esterne.

## Componenti principali

| Componente | Responsabilità |
|------------|----------------|
| `task_cli.py` | Entry point, parsing argomenti, logica comandi, I/O JSON |
| `tasks.json` | Storage runtime (non versionato) |
| `scripts/test.sh` | Test automatici: struttura + comportamento CLI |

## Struttura interna di `task_cli.py`

```
load_tasks(path)       — carica tasks.json; lista vuota se non esiste
save_tasks(path, tasks) — scrive tasks.json
cmd_add(tasks, text)   — aggiunge task con ID auto-incrementale
cmd_list(tasks)        — stampa task formattati; "No tasks." se vuota
cmd_done(tasks, id)    — marca completato; exit 1 se ID non trovato
cmd_delete(tasks, id)  — rimuove task; exit 1 se ID non trovato
cmd_clear(tasks)       — svuota la lista
main()                 — argparse + dispatch
```

## Formato tasks.json

```json
[
  {"id": 1, "text": "testo del task", "done": false},
  {"id": 2, "text": "altro task", "done": true}
]
```

## Flusso dei dati

```
stdin (argomenti CLI)
  → argparse (main)
    → load_tasks (tasks.json)
      → comando specifico
        → save_tasks (tasks.json)
          → stdout / stderr
```

## Dipendenze esterne

Nessuna. Solo Python standard library.

## Decisioni rilevanti

Vedi [`DECISIONS.md`](DECISIONS.md).

## Data ultima revisione

2026-06-29
