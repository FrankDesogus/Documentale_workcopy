# Tasks — cursor-prompt-builder

## In corso

_Nessun task in corso._

## Backlog

| ID | Titolo | Agente previsto | Note |
|----|--------|-----------------|------|
| TASK-003 | Generazione prompt Cursor base | Cursor Agent | Output strutturato su stdout, scope, stop conditions |
| TASK-004 | Output su file e opzioni CLI | Cursor Agent | `--output FILE`, `--project`, `--tasks-file`, validazione errori |
| TASK-005 | Review completa e integrazione workflow | Claude Code + OneAI | Review diff, REVIEW_LOG, merge su decisione umana |

## Completati

| ID | Titolo | Commit | Data |
|----|--------|--------|------|
| TASK-001 | Scaffold progetto e test base | `fda3d5b` | 2026-06-29 |
| TASK-002 | Parsing task da TASKS.md | `dc5c5a0` | 2026-06-29 |

---

## Regole di aggiornamento

- Sposta un task da Backlog a "In corso" solo quando inizia il lavoro.
- Un solo task "In corso" per agente alla volta.
- Sposta in "Completati" solo dopo test e review positivi.
- Registra sempre il commit di riferimento nei task completati.

## Ordine di esecuzione suggerito

1. TASK-001 — scaffold (Claude Code)
2. TASK-002 — parsing TASKS.md (Cursor Agent, prompt da OneAI)
3. TASK-003 — generazione prompt (Cursor Agent, prompt da OneAI)
4. TASK-004 — opzioni CLI e output file (Cursor Agent, prompt da OneAI)
5. TASK-005 — review completa, merge (Claude Code + OneAI)
