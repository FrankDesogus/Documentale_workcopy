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

### Review — 2026-06-29 — TASK-003 Generazione prompt Cursor base

**Reviewer:** Claude Code
**Diff / branch:** task/cursor-prompt-builder (working tree, post Cursor Agent)
**Esito:** Approvato

**Osservazioni:**

- `build_prompt(task, project_dir, task_id) -> str` implementata correttamente: struttura, guardrail, stop conditions, file da leggere, branch atteso, tutti presenti.
- Funzioni ausiliarie (`resolve_project_dir`, `find_repo_root`, `project_rel_path`, `expected_branch`) ben separate per responsabilità.
- `extra_fields` gestisce dinamicamente colonne aggiuntive oltre quelle standard — buona estensibilità senza overhead.
- `main()` aggiornato correttamente: chiama `build_prompt()`, rimuove il placeholder e il dump key:value.
- `scripts/test.sh`: aggiunta `skip()` (necessaria per shellcheck/shfmt condizionali), 6 nuovi check sulla generazione prompt, sezione qualità bash.
- Nessuna dipendenza esterna introdotta. Nessuna automazione git. `--output FILE` non implementato (corretto, è TASK-004).
- 27/27 PASS. shellcheck OK. shfmt OK.

**Azioni richieste prima del commit:**

- Nessuna.

### Review — 2026-06-29 — TASK-004 Output su file e opzioni CLI

**Reviewer:** Claude Code
**Diff / branch:** task/cursor-prompt-builder (working tree, post Cursor Agent)
**Esito:** Approvato

**Nota deviazione workflow:** TASK-004 era assegnato a Cursor Agent come implementatore. Cursor Agent ha implementato il codice ma non ha potuto eseguire i test per mancata approvazione comandi shell nella sessione; i test sono stati eseguiti manualmente dall'operatore. La review e il commit restano di competenza Claude Code. Deviazione accettata e documentata.

**Osservazioni:**

- `--output FILE`: implementazione corretta e minimale (20 righe in `main()`). `Path.write_text()` con encoding utf-8. Conferma su stdout. Senza `--output` comportamento invariato.
- Gestione errori `OSError` con messaggio su stderr e exit 1 — corretta per percorsi non scrivibili o directory.
- Nessuna dipendenza esterna aggiunta. `Path` era già importata.
- `scripts/test.sh`: 8 nuovi check che coprono tutti i casi rilevanti: creazione file, contenuto, conferma stdout, separazione stdout/prompt, `--project`, `--tasks-file`, output non scrivibile. Usa `mktemp` + `rm -f` per cleanup.
- shellcheck e shfmt: OK.
- 35/35 PASS.

**Azioni richieste prima del commit:**

- Nessuna.
