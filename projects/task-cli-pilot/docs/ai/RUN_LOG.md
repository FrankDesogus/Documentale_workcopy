# Run Log

Registro delle esecuzioni dei cicli AI su questo progetto.

---

## Template

### Run — YYYY-MM-DD HH:MM — Titolo del task

**Agente:** Claude Code | Codex | Cursor | Altro
**Task:** <!-- riferimento a TASKS.md, es. #ID Titolo -->
**Branch:** <!-- nome del branch usato -->

**Operazioni eseguite:**
<!-- Cosa ha fatto l'agente, in ordine -->

1.

**Esito test (`scripts/test.sh`):**

```
# incolla qui l'output
```

**Problemi riscontrati:**
<!-- Errori, ambiguità, stop forzati. Vuoto se nessuno. -->

-

**Prossimo passo per l'operatore umano:**
<!-- Cosa deve fare l'operatore ora: approvare, correggere, committare, altro -->

---

<!-- Aggiungi i run qui sotto in ordine cronologico -->

### Run — 2026-06-29 — TASK-003 Implementare `done` e `delete`

**Agente:** Claude Code
**Task:** TASK-003 — Implementare `done` e `delete`
**Branch:** task/task-cli-pilot

**Operazioni eseguite:**

1. Implementate `cmd_done` e `cmd_delete` in `task_cli.py`.
2. Refactoring del dispatch in `main()`: sostituito il blocco `if args.command in ("add","list")` con catena `if/elif` completa.
3. Esteso `scripts/test.sh` con 8 nuovi check per `done` e `delete` (flag salvato, task rimosso, exit 1 su ID inesistente). Risolto SC1010 (`done` keyword bash) usando variabile `CMD_DONE`.
4. shellcheck e shfmt: OK.

**Esito test (`scripts/test.sh`):**

```
Tutti i controlli passati. (30/30 PASS)
```

**Problemi riscontrati:**

SC1010 — `done` è keyword bash: risolto con `CMD_DONE="done"`.

**Prossimo passo per l'operatore umano:**

Procedere con TASK-004: `clear`, `--version`, gestione errori.

### Run — 2026-06-29 — TASK-002 Implementare `add` e `list`

**Agente:** Cursor Agent
**Task:** TASK-002 — Implementare `add` e `list`
**Branch:** task/task-cli-pilot

**Operazioni eseguite:**

1. Implementati helper `load_tasks`, `save_tasks`, `cmd_add`, `cmd_list` in `task_cli.py`.
2. Collegati i comandi `add` e `list` al dispatch in `main()` con persistenza su `tasks.json` (CWD).
3. Lasciati `done`, `delete`, `clear` con messaggio esplicito «not yet implemented» (exit 1).
4. Esteso `scripts/test.sh` con test comportamentali in directory temporanea (`mktemp -d`).

**File modificati:**

- `task_cli.py`
- `scripts/test.sh`
- `docs/ai/RUN_LOG.md`

**Esito test (`scripts/test.sh`):**

```
Non eseguito dall'agente: invocazione shell di python/bash bloccata in questo ambiente.
Verifica manuale richiesta all'operatore:

  cd projects/task-cli-pilot && scripts/test.sh
```

**Problemi riscontrati:**

- L'ambiente agente ha rifiutato l'esecuzione di `scripts/test.sh` e dei comandi `python`; `TASKS.md` non aggiornato finché i test non passano localmente.

**Prossimo passo per l'operatore umano:**

1. Eseguire `cd projects/task-cli-pilot && scripts/test.sh`.
2. Se i test passano, aggiornare `docs/ai/TASKS.md` (TASK-002 → Completati) e procedere con review/commit.
