# Tasks

## In corso

| ID | Titolo | Agente | Branch | Note |
| -- | ------ | ------ | ------ | ---- |
|    |        |        |        |      |

## Backlog

| ID | Titolo | Priorità | Note |
| -- | ------ | -------- | ---- |
| TASK-003 | Generazione report markdown | Alta | Cursor Agent |
| TASK-004 | Opzione output file e gestione errori | Media | Cursor Agent |
| TASK-005 | Review finale e merge | Bassa | Claude Code |

## Completati

| ID | Titolo | Commit | Data |
| -- | ------ | ------ | ---- |
| TASK-001 | Scaffold + test base | 2b5b526 | 2026-06-29 |
| TASK-002 | Rilevamento progetti e helper | — | 2026-06-29 |

---

## Dettaglio task

### TASK-001 — Scaffold + test base — Claude Code

**Scope:** creare la struttura base del progetto.

- `summary.py` minimale con `--help` e `--version`.
- `scripts/test.sh` funzionante: struttura, py_compile, help/version, shellcheck, shfmt.
- Documentazione iniziale (`PROJECT_BRIEF.md`, `ARCHITECTURE.md`, `TASKS.md`, `DECISIONS.md`).

**Criteri di completamento:**
- `python summary.py --help` e `--version` escono con codice 0.
- `scripts/test.sh` esce con codice 0.

---

### TASK-002 — Rilevamento progetti e helper — Cursor Agent

**Scope:** implementare le funzioni di scansione.

- `scan_projects(station_dir)`: ritorna lista nomi cartelle sotto `projects/`.
- `scan_scripts(station_dir)`: ritorna lista file `.sh` sotto `scripts/` (non ricorsivo).
- Test unitari in `scripts/test.sh` per entrambe le funzioni.

**Criteri di completamento:**
- Le funzioni ritornano i dati corretti sulla stazione reale.
- `scripts/test.sh` esce con codice 0.

---

### TASK-003 — Generazione report markdown — Cursor Agent

**Scope:** implementare il renderer del report.

- `render_report(data)`: genera stringa markdown da dict con progetti e helper.
- Integrazione nel flusso principale (esecuzione senza `--output` stampa su stdout).
- Test del renderer in `scripts/test.sh`.

**Criteri di completamento:**
- `python summary.py` produce un report markdown valido su stdout.
- `scripts/test.sh` esce con codice 0.

---

### TASK-004 — Opzione output file e gestione errori — Cursor Agent

**Scope:** aggiungere `--output FILE` e gestione errori robusta.

- `--output FILE`: scrive il report su file invece di stdout.
- Gestione errori: directory stazione non trovata, path non scrivibile.
- Test per `--output` e scenari di errore.

**Criteri di completamento:**
- `python summary.py --output /tmp/report.md` crea il file correttamente.
- Errori producono messaggi chiari su stderr e codice di uscita non-zero.
- `scripts/test.sh` esce con codice 0.

---

### TASK-005 — Review finale e merge — Claude Code

**Scope:** review completa e preparazione al merge.

- Review diff completo del branch.
- Verifica test (tutti PASS).
- Aggiornamento `docs/ai/REVIEW_LOG.md`.
- Commit finale se tutto ok.
- Segnalazione all'operatore per merge manuale su main.

**Criteri di completamento:**
- Review approvata e registrata in `REVIEW_LOG.md`.
- `scripts/test.sh` esce con codice 0.
- Operatore informato e pronto al merge.

---

## Regole di aggiornamento

- Sposta un task da Backlog a "In corso" solo quando inizia il lavoro.
- Un solo task "In corso" per agente alla volta.
- Sposta in "Completati" solo dopo test e review positivi.
- Registra sempre il commit di riferimento nei task completati.
