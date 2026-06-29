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
