# Review Log

Registro delle review di codice effettuate dagli agenti AI su questo progetto.

---

## Template

### Review — YYYY-MM-DD — Titolo o branch

**Reviewer:** Claude Code | Codex | Altro
**Diff / branch:** <!-- nome branch o hash commit -->
**Esito:** Approvato | Approvato con osservazioni | Respinto

**Osservazioni:**
<!-- Lista dei problemi trovati, suggerimenti, note sul codice -->

-

**Azioni richieste prima del commit:**
<!-- Cosa deve essere corretto. Vuoto se approvato senza riserve. -->

-

---

<!-- Aggiungi le review qui sotto in ordine cronologico -->

### Review — 2026-06-29 — TASK-002 · `add` e `list`

**Reviewer:** Claude Code
**Diff / branch:** `task/task-cli-pilot` — modifiche a `task_cli.py`, `scripts/test.sh`, `docs/ai/RUN_LOG.md`
**Esito:** Approvato

**Osservazioni:**

- Scope rispettato: implementati solo `add` e `list`; `done`, `delete`, `clear` rimangono con `not yet implemented` (exit 1) come da piano.
- `load_tasks`/`save_tasks` corretti: lista vuota se `tasks.json` non esiste; encoding UTF-8 esplicito; newline finale nel JSON.
- `cmd_add`: ID auto-incrementale via `max()` — robusto anche con ID non contigui.
- `cmd_list`: formato `[ ]`/`[x]` corretto; gestione lista vuota con `"No tasks."`.
- `tasks.json` scritto nella directory corrente (CWD), non accanto allo script — comportamento atteso confermato dai test.
- `scripts/test.sh`: test comportamentali in `mktemp -d` — corretti e isolati. Un warning shellcheck SC2329 (funzione `cleanup_tmp` rilevata come non invocata per il `trap` indiretto) è stato corretto inline (`trap 'rm -rf ...' EXIT`). shellcheck e shfmt ora passano puliti.
- `RUN_LOG.md` aggiornato da Cursor Agent con nota onesta che i test non erano stati eseguiti nell'ambiente agente.
- `TASKS.md` non aggiornato da Cursor Agent — corretto in questa review (TASK-001 e TASK-002 → Completati).
- Dipendenze: solo stdlib (`json`, `pathlib`, `argparse`, `sys`, `typing`). Nessun import esterno.

**Azioni richieste prima del commit:**

- Corretta la riga `cleanup_tmp` in `test.sh` (già applicata). Nessun'altra azione richiesta.
