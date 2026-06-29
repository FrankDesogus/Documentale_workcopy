# Tasks — demo-minimal

## In corso

| ID       | Titolo                               | Agente      | Branch                 | Note                    |
| -------- | ------------------------------------ | ----------- | ---------------------- | ----------------------- |
| TASK-002 | Implementare CLI minimale (`cli.py`) | Claude Code | task/demo-minimal-cli  | In fase di completamento |

## Backlog

| ID       | Titolo                       | Priorità | Note                                                        |
| -------- | ---------------------------- | -------- | ----------------------------------------------------------- |
| TASK-003 | Eseguire review e aggiornare RUN_LOG | Media | Review con Claude Code, log in `RUN_LOG.md` e `REVIEW_LOG.md` |

## Completati

| ID       | Titolo                                   | Commit    | Data       |
| -------- | ---------------------------------------- | --------- | ---------- |
| TASK-001 | Configurare test reale del progetto demo | `5e53acd` | 2026-06-29 |

---

## Regole di aggiornamento

- Sposta un task da Backlog a "In corso" solo quando inizia il lavoro.
- Un solo task "In corso" per agente alla volta.
- Sposta in "Completati" solo dopo test e review positivi.
- Registra sempre il commit di riferimento nei task completati.

## Ordine di esecuzione suggerito

1. TASK-001 ✓ — test struttura reale configurato e funzionante.
2. TASK-002 — implementazione CLI (`cli.py`) con branch `task/demo-minimal-cli`.
3. TASK-003 — review del diff, log, commit finale.
