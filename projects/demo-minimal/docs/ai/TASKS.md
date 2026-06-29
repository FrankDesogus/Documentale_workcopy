# Tasks — demo-minimal

## In corso

| ID       | Titolo                                   | Agente      | Branch                  | Note                          |
| -------- | ---------------------------------------- | ----------- | ----------------------- | ----------------------------- |
| TASK-001 | Configurare test reale del progetto demo | Claude Code | task/demo-minimal-test  | Sostituire placeholder test.sh |

## Backlog

| ID       | Titolo                                        | Priorità | Note                                      |
| -------- | --------------------------------------------- | -------- | ----------------------------------------- |
| TASK-002 | Implementare CLI minimale (`cli.py`)          | Alta     | `python cli.py` → stampa messaggio, exit 0 |
| TASK-003 | Eseguire review e aggiornare RUN_LOG          | Media    | Review con Claude Code, log in `RUN_LOG.md` e `REVIEW_LOG.md` |

## Completati

| ID | Titolo | Commit | Data |
| -- | ------ | ------ | ---- |
|    |        |        |      |

---

## Regole di aggiornamento

- Sposta un task da Backlog a "In corso" solo quando inizia il lavoro.
- Un solo task "In corso" per agente alla volta.
- Sposta in "Completati" solo dopo test e review positivi.
- Registra sempre il commit di riferimento nei task completati.

## Ordine di esecuzione suggerito

1. TASK-001 — senza un test reale non si può chiudere nessun task.
2. TASK-002 — implementazione CLI, con branch `task/cli-minimale`.
3. TASK-003 — review del diff, log, commit finale.
