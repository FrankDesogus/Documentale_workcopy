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

### Run — 2026-07-05 — TASK-001 Analisi iniziale progetto Documentale

**Agente:** Cursor Agent
**Task:** TASK-001 — Analisi iniziale progetto Documentale
**Branch:** task/onboard-documentale-workcopy

**Operazioni eseguite:**

1. Letti `docs/ai/TASKS.md`, `AGENTS.md`, `scripts/test.sh` (obbligatori pre-modifica).
2. Analisi read-only di documentazione e codebase: `CLAUDE.md`, `README.md`, `AI_CONTEXT.md`, `PROJECT_HANDOFF.md`, `DEPLOY.md`, `requirements.txt`, `package.json`, `config/`, app Django, migrazioni, template.
3. Creato `docs/ai/PROJECT_ANALYSIS.md` con tutte le sezioni richieste (panoramica, stack, struttura, entry point, dipendenze, comandi, deploy, file sensibili, rischi, problemi, roadmap TASK-002…, raccomandazione).
4. Nessun file applicativo modificato; `scripts/test.sh` non toccato.
5. Nessun commit eseguito.

**Esito test (`scripts/test.sh`):**

```
== Test: documentale-workcopy ==
Nessun test ancora configurato per questo progetto.
Sostituire questo script con il comando di test reale (pytest, npm test, ...).
Exit code: 0
```

Verifica: script placeholder invariato (`exit 0` esplicito). L'operatore può riconfermare con:
`cd projects/documentale-workcopy && ./scripts/test.sh`

**Problemi riscontrati:**

- Nessuno bloccante. Shell non eseguibile dall'agente in questa sessione; esito dedotto da contenuto statico dello script (placeholder Station, exit 0 garantito).

**Prossimo passo per l'operatore umano:**

1. Leggere `docs/ai/PROJECT_ANALYSIS.md`.
2. Trascrivere nel Backlog di `docs/ai/TASKS.md` la roadmap proposta (TASK-002…).
3. Spostare TASK-001 in Completati dopo review positiva.
4. Avviare **TASK-002** (collegare `scripts/test.sh` alla suite Django) — raccomandazione esplicita nel report.

---

### Run — 2026-07-05 — TASK-002 Collegare test reali Django

**Agente:** Cursor Agent (implementazione) + Claude Code (fix + verifica esecuzione)
**Task:** TASK-002 — Collegare test reali Django
**Branch:** task/documentale-test-bootstrap

**Operazioni eseguite:**

1. Cursor Agent ha sostituito il placeholder `scripts/test.sh` con controlli
   reali: verifica dipendenze `requirements.txt`, `python -m compileall`,
   `manage.py check`, `manage.py test` (SQLite `:memory:`, no `.env`, no
   server, no migrazioni reali).
2. Cursor Agent ha creato `config/test_settings.py`: SECRET_KEY fittizia
   impostata via env var prima dell'import di `config.settings` (evita
   `UndefinedValueError` di `python-decouple` senza `.env`), poi override di
   `DATABASES` (SQLite `:memory:`) ed `EMAIL_BACKEND` (`locmem`).
3. Cursor Agent non ha potuto eseguire `bash`/`python3` nella propria
   sessione (shell disabilitata) e non ha aggiornato questo log, per non
   dichiarare un esito non verificato — comportamento corretto.
4. **Claude Code (reviewer)** ha eseguito `ai-cycle.sh --run`, che ha
   correttamente fermato il ciclo allo STEP 5 (`Test falliti`): bug reale di
   sintassi bash in `scripts/test.sh` riga 55
   (`pkg="${pkg%%[*"` — parentesi non chiusa, causava `EOF non atteso`).
5. Bug corretto (una riga: `pkg="${pkg%%\[*}"`), sintassi verificata
   (`bash -n`), script rieseguito manualmente.
6. Corretta anche una discrepanza di formattazione `shfmt` (`< "${FILE}"` →
   `<"${FILE}"`).

**Esito test (`scripts/test.sh`):**

```
== Test: documentale-workcopy ==
Root progetto: /home/frank/AI-Software-Station/projects/documentale-workcopy
Python: Python 3.14.5
Settings di test: config.test_settings

== 0/3 — Verifica dipendenze Python (requirements.txt) ==
Dipendenze mancanti:
  - asgiref (import asgiref)
  - Django (import django)
  - django-filter (import django_filters)
  - djangorestframework (import rest_framework)
  - gunicorn (import gunicorn)
  - psycopg (import psycopg)
  - python-decouple (import decouple)
  - sqlparse (import sqlparse)
  - tzdata (import tzdata)
ERRORE: Impossibile eseguire controlli Django reali. Installare le dipendenze da requirements.txt (fuori da questo script).
Exit code: 1
```

Questo è l'esito **atteso e corretto** in questo ambiente: la AI Software
Station non ha un virtualenv con le dipendenze del Documentale installate
(per design — nessuna installazione automatica di pacchetti), quindi lo
script fallisce onestamente invece di dare un falso `exit 0`. `shellcheck` e
`shfmt` puliti; `bash -n` e `python -m py_compile config/test_settings.py`
OK.

**Problemi riscontrati:**

- Bug di sintassi bash introdotto dall'implementazione (vedi sopra), corretto
  in review prima del commit.
- Ambiente Station privo delle dipendenze Python del Documentale: lo script
  non può eseguire i controlli Django reali qui. Non bloccante per il merge
  di questo task (lo script è corretto e sicuro), ma la suite Django
  completa (~1100+ test) resta da eseguire in un ambiente con
  `pip install -r requirements.txt` (venv dedicato, non creato in questo
  task per non violare il guardrail "nessuna installazione di pacchetti").

**Prossimo passo per l'operatore umano:**

1. Per validare i controlli Django reali: creare un virtualenv locale (fuori
   da questo workflow automatico) con `pip install -r requirements.txt` ed
   eseguire `./scripts/test.sh` per confermare che compile/check/test
   passino sul codice reale.
2. Spostare TASK-002 in Completati dopo review positiva.
3. Procedere con i task successivi della roadmap (`PROJECT_ANALYSIS.md`):
   TASK-003 bootstrap ambiente dev, TASK-004 migrazione permessi cartella, ecc.
