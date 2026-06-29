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

### Run — 2026-06-29 — TASK-002 Parsing task da TASKS.md

**Agente:** Claude Code
**Task:** TASK-002 — Parsing task da TASKS.md
**Branch:** task/cursor-prompt-builder

**Operazioni eseguite:**

1. Implementate `_split_row`, `_is_separator`, `parse_task` in `prompt_builder.py`.
2. Implementata `find_tasks_file` per risolvere `--project` e `--tasks-file`.
3. Aggiornato `main()`: risolve il file, chiama `parse_task`, stampa colonne su stdout (exit 0), exit 1 se task non trovato o file mancante.
4. Corretto bug nel backward scan: il `break` su riga dati intermedia impediva di trovare l'header quando ci sono più task nella stessa tabella. Rimosso il `break` spurio.
5. Corretto exit code del placeholder: exit 0 quando il parsing riesce (il warning "not yet implemented" rimane su stderr).
6. Esteso `scripts/test.sh` con 6 nuovi check (parsing per ID, agente, riga non prima, sezione Completati, task non trovato, file mancante).
7. shellcheck e shfmt: OK.

**Esito test (`scripts/test.sh`):**

```
Tutti i controlli passati. (21/21 PASS)
```

**Problemi riscontrati:**

- Bug backward scan: risolto rimuovendo `break` su riga dati intermedia.
- pipefail + exit 1 placeholder: risolto cambiando exit code a 0 su parsing OK.

**Prossimo passo:**

TASK-003 — Generazione prompt Cursor base.

---

### Run — 2026-06-29 — TASK-003 Generazione prompt Cursor base

**Agente:** Cursor Agent
**Task:** TASK-003 — Generazione prompt Cursor base
**Branch:** task/cursor-prompt-builder

**Operazioni eseguite:**

1. Implementate funzioni ausiliarie: `resolve_project_dir`, `find_repo_root`, `project_rel_path`, `expected_branch`.
2. Implementata `build_prompt(task, project_dir, task_id) -> str`: output strutturato su stdout con repository, branch atteso, progetto, task ID, titolo, agente, file da leggere, file modificabili, obiettivo, scope, fuori scope, test, stop conditions, guardrail.
3. Aggiornato `main()`: risolve la project dir, chiama `build_prompt()`, rimuove il placeholder e il dump key:value.
4. Esteso `scripts/test.sh`: aggiunta `skip()`, sezione "Generazione prompt TASK-003" (6 nuovi check), sezione "Qualità script bash" (shellcheck + shfmt condizionali).

**Esito test (`scripts/test.sh`):**

```
Tutti i controlli passati. (27/27 PASS)
```

**Problemi riscontrati:**

- Nessuno.

**Prossimo passo per l'operatore umano:**

Approvare il commit. TASK-004 (Output su file e opzioni CLI) è il prossimo task per Cursor Agent.

---

### Run — 2026-06-29 — TASK-004 Output su file e opzioni CLI

**Agente:** Cursor Agent
**Nota deviazione workflow:** Cursor Agent non ha potuto eseguire comandi shell (approvazione negata nella sessione); i test sono stati eseguiti manualmente dall'operatore. L'implementazione è di Cursor Agent; review e commit di competenza Claude Code.
**Task:** TASK-004 — Output su file e opzioni CLI
**Branch:** task/cursor-prompt-builder

**Operazioni eseguite:**

1. Aggiunto gestione `--output FILE` in `main()`: se specificato, scrive il prompt su file con `Path.write_text()` e stampa messaggio di conferma su stdout; altrimenti comportamento invariato (stdout).
2. Aggiunta gestione errori scrittura: `OSError` → messaggio su stderr + exit 1.
3. Esteso `scripts/test.sh`: sezione "Opzioni CLI e output su file (TASK-004)" con 8 nuovi check (`--output` crea file, contenuto, conferma stdout, separazione stdout/prompt, `--project`, `--tasks-file`, output non scrivibile → exit 1).

**Esito test (`scripts/test.sh`):**

```
Tutti i controlli passati. (35/35 PASS)
```

**Problemi riscontrati:**

- Nessuno.

**Prossimo passo per l'operatore umano:**

Approvare il commit. TASK-005 (Review completa e integrazione workflow) è il prossimo task per Claude Code + OneAI.
