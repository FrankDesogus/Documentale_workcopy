# Tasks — task-cli-pilot

## In corso

| ID | Titolo | Agente | Branch | Note |
|----|--------|--------|--------|------|
| TASK-003 | Implementare `done` e `delete` | Claude Code | task/task-cli-pilot | In completamento |

## Backlog

| ID | Titolo | Agente previsto | Note |
|----|--------|-----------------|------|
| TASK-004 | Implementare `clear`, `--version`, gestione errori | Cursor Agent | Input non validi, edge case lista vuota |
| TASK-005 | Review completa e aggiornamento log | Claude Code + OneAI | Review diff completo, REVIEW_LOG, merge |

## Completati

| ID | Titolo | Commit | Data |
|----|--------|--------|------|
| TASK-001 | Scaffold progetto e test base | `e8abff5` | 2026-06-29 |
| TASK-002 | Implementare `add` e `list` | `1fec4be` | 2026-06-29 |

---

## Regole di aggiornamento

- Sposta un task da Backlog a "In corso" solo quando inizia il lavoro.
- Un solo task "In corso" per agente alla volta.
- Sposta in "Completati" solo dopo test e review positivi.
- Registra sempre il commit di riferimento nei task completati.

## Ordine di esecuzione suggerito

1. TASK-001 — scaffold + test base (Claude Code) — branch `task/task-cli-pilot`
2. TASK-002 — `add` e `list` (Cursor Agent, prompt da OneAI)
3. TASK-003 — `done` e `delete` (Cursor Agent, prompt da OneAI)
4. TASK-004 — `clear`, `--version`, errori (Cursor Agent, prompt da OneAI)
5. TASK-005 — review completa, merge (Claude Code + OneAI)
