# Tasks — task-cli-pilot

## In corso

_Nessun task in corso._

## Backlog

| ID | Titolo | Agente previsto | Note |
|----|--------|-----------------|------|
_Backlog vuoto._

## Completati

| ID | Titolo | Commit | Data |
|----|--------|--------|------|
| TASK-001 | Scaffold progetto e test base | `e8abff5` | 2026-06-29 |
| TASK-002 | Implementare `add` e `list` | `1fec4be` | 2026-06-29 |
| TASK-003 | Implementare `done` e `delete` | `784885d` | 2026-06-29 |
| TASK-004 | Implementare `clear`, `--version`, gestione errori | `6b8bbe0` | 2026-06-29 |
| TASK-005 | Review completa e merge su main | — | 2026-06-29 |

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
