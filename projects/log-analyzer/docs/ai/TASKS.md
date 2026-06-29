# Tasks — log-analyzer

## In corso

_Nessun task in corso._

## Backlog

| ID | Titolo | Agente previsto | Note |
|----|--------|-----------------|------|
| TASK-004 | Scanning directory e output CLI | Cursor Agent | Scansione `projects/`, `--project`, `--output FILE`, output testuale finale |
| TASK-005 | Review completa e integrazione workflow | Claude Code + OneAI | Review diff, REVIEW\_LOG, merge su decisione umana |

## Completati

| ID | Titolo | Commit | Data |
|----|--------|--------|------|
| TASK-001 | Scaffold progetto e test base | `cbeea24` | 2026-06-29 |
| TASK-002 | Parsing TASKS.md | `b72b328` | 2026-06-29 |
| TASK-003 | Parsing RUN\_LOG e REVIEW\_LOG | pending | 2026-06-29 |

---

## Regole di aggiornamento

- Sposta un task da Backlog a "In corso" solo quando inizia il lavoro.
- Un solo task "In corso" per agente alla volta.
- Sposta in "Completati" solo dopo test e review positivi.
- Registra sempre il commit di riferimento nei task completati.

## Ordine di esecuzione suggerito

1. TASK-001 — scaffold (Claude Code)
2. TASK-002 — parsing TASKS.md (Cursor Agent)
3. TASK-003 — parsing RUN_LOG e REVIEW_LOG (Cursor Agent)
4. TASK-004 — scanning e output CLI (Cursor Agent)
5. TASK-005 — review completa, merge (Claude Code + OneAI)
