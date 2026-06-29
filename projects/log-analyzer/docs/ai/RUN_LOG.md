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

### Run — 2026-06-29 — TASK-001 Scaffold progetto e test base

**Agente:** Claude Code
**Task:** TASK-001 — Scaffold progetto e test base
**Branch:** task/log-analyzer

**Operazioni eseguite:**

1. Creata struttura con `./scripts/new-project.sh log-analyzer`.
2. Scritti `PROJECT_BRIEF.md`, `ARCHITECTURE.md`, `TASKS.md`, `DECISIONS.md`.
3. Scritto `log_analyzer.py`: argparse skeleton con `--version`, `--help`, `--projects-dir`, `--project`, `--output`; placeholder per le funzioni di parsing (TASK-002/003/004).
4. Scritto `scripts/test.sh`: struttura obbligatoria, py_compile, --help, --version, shellcheck, shfmt.

**Esito test (`scripts/test.sh`):**

```
Tutti i controlli passati. (16/16 PASS)
```

**Problemi riscontrati:**

- Nessuno.

**Prossimo passo per l'operatore umano:**

Approvare il commit. TASK-002 (Parsing TASKS.md) è il prossimo task per Cursor Agent.

---

### Run — 2026-06-29 — TASK-002 Parsing TASKS.md

**Agente:** Cursor Agent
**Task:** TASK-002 — Parsing TASKS.md
**Branch:** task/log-analyzer

**Operazioni eseguite:**

1. Aggiunti helper `_SECTION_KEYS`, `_split_row`, `_is_separator` (pattern identico a cursor-prompt-builder).
2. Implementata `parse_tasks(tasks_path)`: scansione sezioni `## Backlog/In corso/Completati`, header dinamico, righe separator, file mancante → dict vuoto.
3. Aggiunto `import re`.

**Esito test (`scripts/test.sh`):**

```
Tutti i controlli passati. (20/20 PASS)
```

Note: 4 test di parsing aggiunti durante la review (Claude Code) per verificare i conteggi.

**Problemi riscontrati:**

- Nessuno.

**Prossimo passo per l'operatore umano:**

Approvare il commit. TASK-003 (Parsing RUN_LOG e REVIEW_LOG) è il prossimo task per Cursor Agent.

---

### Run — 2026-06-29 — TASK-003 Parsing RUN_LOG e REVIEW_LOG

**Agente:** Cursor Agent
**Nota:** test non eseguibili da Cursor Agent (shell bloccata); test verificati manualmente da Claude Code.
**Task:** TASK-003 — Parsing RUN\_LOG e REVIEW\_LOG
**Branch:** task/log-analyzer

**Operazioni eseguite:**

1. Aggiunte regex `_RUN_HEADER_RE` e `_REVIEW_HEADER_RE` per `### Run/Review — YYYY-MM-DD …`.
2. Aggiunto `_normalize_test_outcome` (gestisce PASS/FAIL italiano e inglese).
3. Aggiunti `_parse_run_body` e `_parse_review_body` (scansione linea per linea, stdlib).
4. Aggiunto `_parse_last_log_entry` (helper generico: scansiona file, trova ultima entry, chiama body_parser).
5. Rimossi placeholder in `parse_last_run` e `parse_last_review`; ora delegano a `_parse_last_log_entry`.
6. Aggiunti 4 test in `scripts/test.sh` durante review (Claude Code) per verificare estrazione task ID, esito, review esito e file mancante.

**Esito test (`scripts/test.sh`):**

```
Tutti i controlli passati. (24/24 PASS)
```

**Problemi riscontrati:**

- Cursor Agent non ha potuto eseguire i test (shell bloccata in sessione). Test eseguiti da Claude Code.

**Prossimo passo per l'operatore umano:**

Approvare il commit. TASK-004 (Scanning directory e output CLI) è il prossimo task per Cursor Agent.

---

### Run — 2026-06-29 — TASK-004 Scanning directory e output CLI

**Agente:** Cursor Agent
**Nota:** test non eseguibili da Cursor Agent (shell bloccata); test verificati da Claude Code.
**Task:** TASK-004 — Scanning directory e output CLI
**Branch:** task/log-analyzer

**Operazioni eseguite:**

1. Implementata `summarize_project(project_dir)`: aggrega `parse_tasks`, `parse_last_run`, `parse_last_review` in un dict unificato.
2. Implementata `_format_last_run` e `_format_last_review`: formattazione testuale dei log entry.
3. Implementata `format_summary(summaries)`: output testuale per singolo e multi-progetto.
4. Implementato `main()`: argparse completo con `--projects-dir`, `--project`, `--output`; gestione file inesistente, `--output FILE`, output su stdout.
5. Aggiunti 5 test in `scripts/test.sh` (Claude Code durante review): header progetto, Ultimo run, Ultima review, multi-project scan ≥2 progetti, --output FILE.

**Esito test (`scripts/test.sh`):**

```
Tutti i controlli passati. (29/29 PASS)
```

**Problemi riscontrati:**

- Cursor Agent non ha potuto eseguire i test (shell bloccata in sessione). Test eseguiti da Claude Code.

**Prossimo passo per l'operatore umano:**

Approvare il commit. TASK-005 (Review completa e integrazione workflow) è il prossimo task.
