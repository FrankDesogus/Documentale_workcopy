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

---

### Run — 2026-07-05 — TASK-003 Preparare ambiente test dedicato Documentale

**Agente:** Claude Code (con autorizzazione esplicita dell'operatore per
installare pacchetti solo in una venv dedicata alla copia)
**Task:** TASK-003 — Preparare ambiente test dedicato Documentale
**Branch:** task/documentale-test-env

**Operazioni eseguite:**

1. Creata venv dedicata: `projects/documentale-workcopy/.venv` (Python
   3.14.5, pip 26.1.1). Già coperta da `.gitignore` esistente (`.venv/`),
   mai committata.
2. Installate le dipendenze con `.venv/bin/pip install -r requirements.txt`
   — solo in questa venv, nessun pacchetto globale, nessun `sudo`.
3. Eseguito `scripts/test.sh` con la venv attivata.
4. Aggiornati `docs/ai/TESTING_STATUS.md` (esito reale) e `docs/ai/TASKS.md`
   (TASK-003 → Completati, checklist spuntata).
5. Nessuna modifica alla logica applicativa. Nessun `.env` letto, nessun
   database reale toccato, nessun server avviato, nessuna migrazione su
   database reale (solo SQLite `:memory:` interno al test runner Django).
6. Nessun commit eseguito in questo step (fatto separatamente via
   `commit-if-approved.sh` dopo review).

**Esito test (`scripts/test.sh`, con venv `.venv` attiva):**

```
== 0/3 — Verifica dipendenze Python (requirements.txt) ==
OK — dipendenze di requirements.txt importabili.

== 1/3 — Compilazione e sintassi Python ==
OK — compilazione/sintassi Python superata.
(1 SyntaxWarning non bloccante in documents/versioning.py:9)

== 2/3 — Django manage.py check (settings di test, no .env) ==
System check identified no issues (0 silenced).
OK — manage.py check superato.

== 3/3 — Django manage.py test (SQLite :memory:, no migrate/runserver) ==
Ran 1207 tests in 489.755s
OK
Found 1207 test(s).
System check identified no issues (0 silenced).
OK — manage.py test superato.

Tutti i controlli completati con successo.
Exit code: 0
```

**Problemi riscontrati:**

- `documents/versioning.py:9` — `SyntaxWarning` cosmetico (escape sequence
  `\d` non raw string). Non bloccante, tutti i test passano comunque. Non
  corretto in questo task (è codice applicativo, fuori scope di TASK-003).
- Molti messaggi informativi "Email non inviata: ... senza indirizzo email"
  e un messaggio "Errore durante apply: Errore simulato in test atomicità"
  durante l'esecuzione: comportamento atteso di test che verificano
  rollback/notifiche, non fallimenti.

**Prossimo passo per l'operatore umano:**

1. Ricordare che la venv `.venv` è locale a questa macchina/sessione: va
   ricreata (`python3 -m venv .venv && .venv/bin/pip install -r requirements.txt`)
   da chiunque riprenda il lavoro, e i cicli `ai-cycle.sh --run` futuri
   NON la attivano automaticamente.
2. Valutare se aprire un piccolo task dedicato per correggere il
   `SyntaxWarning` in `documents/versioning.py:9`.
3. Procedere con i task successivi della roadmap in
   `docs/ai/PROJECT_ANALYSIS.md` (es. migrazione permessi cartella, pulizia
   dipendenze inutilizzate, allineamento documentazione).

---

### Run — 2026-07-06 — TASK-004 Correggere SyntaxWarning in versioning

**Agente:** Claude Code (fix diretto come orchestratore, task di una riga —
autorizzato esplicitamente dall'operatore per micro-fix di questa entità)
**Task:** TASK-004 — Correggere SyntaxWarning in versioning
**Branch:** task/documentale-fix-versioning-warning

**Operazioni eseguite:**

1. Analizzato `documents/versioning.py`: il `SyntaxWarning` proviene dal
   docstring di modulo (riga 1-13, stringa non raw contenente `\d` come
   testo descrittivo), non dalla regex compilata `_RE_NUMERIC` (riga 20,
   già `r'^\d+$'` corretta).
2. Fix applicato: `"""` → `r"""` sul docstring di apertura. Nessun'altra
   modifica.
3. Verificato con `ast.parse` + `python -W error::SyntaxWarning`: nessun
   warning residuo.
4. Eseguita la suite Django completa con la venv `.venv` attivata:
   1206/1207 test PASS, 1 fallimento
   (`test_document_list_shows_approval_date`).
5. **Verifica di indipendenza (test di controllo A/B):** ripristinato
   temporaneamente `documents/versioning.py` alla versione originale
   (`git stash`) e rieseguito il test isolato: fallisce **identicamente**.
   Confermato che il fallimento è pre-esistente e indipendente dal fix.
   Fix ripristinato (`git stash pop`).
6. Causa del fallimento identificata: bug di fuso orario nel test stesso
   (confronta `strftime` su datetime UTC non convertito con il rendering
   del template, localizzato in Europe/Rome — vicino alla mezzanotte
   CEST/UTC le due date possono differire di un giorno). Non è una
   regressione, non è collegato al fix, non è codice applicativo di
   produzione (il template localizza correttamente).
7. Aggiornati `docs/ai/TESTING_STATUS.md` e `docs/ai/TASKS.md` con
   entrambi gli esiti, documentati onestamente.

**Esito test (`scripts/test.sh`, con venv `.venv` attiva):**

```
== 1/3 == OK — compilazione/sintassi Python superata. (nessun SyntaxWarning)
== 2/3 == System check identified no issues (0 silenced).
== 3/3 == Ran 1207 tests in 480.905s — FAILED (failures=1)
```

Test isolato di controllo (stesso test, file originale ripristinato):
FAILED identicamente — fallimento confermato indipendente dal fix.

**Problemi riscontrati:**

- 1 test fragile su confine di fuso orario, pre-esistente, non corretto
  (fuori scope di TASK-004): vedi `docs/ai/TESTING_STATUS.md`.

**Prossimo passo per l'operatore umano:**

1. Valutare un piccolo task dedicato per correggere
   `test_document_list_shows_approval_date` in `documents/tests.py`
   (usare `timezone.localtime()` nell'assert).
2. Procedere con i task della roadmap in `docs/ai/PROJECT_ANALYSIS.md`.

---

### Run — 2026-07-06 — TASK-005 Correggere test approval date timezone

**Agente:** Claude Code (fix diretto come orchestratore, task di una riga)
**Task:** TASK-005 — Correggere test approval date timezone
**Branch:** task/documentale-fix-approval-date-test

**Operazioni eseguite:**

1. Analizzata la causa esatta: `approved_at` impostato con `timezone.now()`
   in `approvals/services.py` (datetime UTC-aware); il template
   `templates/documents/document_list.html` lo renderizza con
   `|date:"d/m/Y"`, che converte automaticamente in `Europe/Rome`; il test
   confrontava invece con `strftime` diretto sul datetime UTC (nessuna
   conversione) — mismatch possibile vicino alla mezzanotte CEST.
2. Fix applicato in `documents/tests.py`,
   `test_document_list_shows_approval_date`:
   `v.approved_at.strftime('%d/%m/%Y')` →
   `timezone.localtime(v.approved_at).strftime('%d/%m/%Y')`
   (`timezone` già importato). Nessuna altra modifica.
3. Test mirato isolato: PASS.
4. Suite Django completa (venv `.venv` attiva): **1207/1207 PASS**, 0
   warning, `manage.py check` pulito.
5. Aggiornati `docs/ai/TESTING_STATUS.md` e `docs/ai/TASKS.md`.
6. Nessuna modifica a view, modelli, template o migrazioni. Nessun file
   del progetto sorgente originale toccato.

**Esito test (`scripts/test.sh`, con venv `.venv` attiva):**

```
Ran 1207 tests in 502.104s
OK
Tutti i controlli completati con successo.
Exit code: 0
```

**Problemi riscontrati:**

- Nessuno. Suite completamente verde, nessun warning residuo.

**Prossimo passo per l'operatore umano:**

1. Procedere con i task della roadmap in `docs/ai/PROJECT_ANALYSIS.md`
   (es. migrazione permessi cartella, pulizia dipendenze inutilizzate,
   allineamento documentazione).

---

### Run — 2026-07-06 — Organizzazione backlog operativo roadmap

**Agente:** Claude Code (solo documentazione, nessun codice applicativo)
**Task:** N/A — riorganizzazione `docs/ai/TASKS.md`
**Branch:** task/documentale-roadmap-backlog

**Operazioni eseguite:**

1. Letti `PROJECT_ANALYSIS.md`, `TESTING_STATUS.md`, `TASKS.md`,
   `RUN_LOG.md` per ricostruire lo stato reale (TASK-001..005 completati,
   suite 1207/1207 PASS, nessun problema noto residuo).
2. Trasformata la roadmap di `PROJECT_ANALYSIS.md` in Backlog operativo in
   `docs/ai/TASKS.md`: TASK-006 (audit permessi, solo analisi), TASK-007
   (migrazione permessi, dipende da TASK-006), TASK-008 (audit dipendenze),
   TASK-009 (pulizia dipendenze, dipende da TASK-008), TASK-010
   (allineamento documentazione), TASK-011 (review deployment),
   TASK-012 (hardening config test) — ciascuno con dettaglio operativo
   completo (obiettivo, scope, file coinvolti, acceptance criteria, test,
   guardrail, note).
3. Nota aggiunta in `PROJECT_ANALYSIS.md`: roadmap operativa trasferita in
   `TASKS.md`.
4. Nessuna modifica a codice applicativo.

**Esito test (`scripts/test.sh`, con venv `.venv` attiva):**

Suite Django reale confermata 1207/1207 PASS (nessuna modifica applicativa
in questo lavoro).

**Prossimo passo per l'operatore umano:**

1. Eseguire **TASK-006** (audit permessi cartella/documenti, solo analisi)
   con `./scripts/ai-cycle.sh --project documentale-workcopy --task TASK-006 --run`.

---

### Run — 2026-07-06 — TASK-006 Audit permessi cartella/documenti

**Agente:** Cursor Agent
**Task:** TASK-006 — Audit permessi cartella/documenti
**Branch:** task/documentale-permissions-audit

**Operazioni eseguite:**

1. Letti `docs/ai/TASKS.md`, `AGENTS.md`, `scripts/test.sh` (obbligatori pre-modifica).
2. Analisi read-only del sistema permessi: `projects/models.py`,
   `projects/resolver.py`, `projects/permissions.py`,
   `documents/permissions.py`, `projects/views.py`, `ecn/permissions.py`,
   management command `backfill_folder_permission_grants` e
   `compare_folder_permissions`, sezioni permessi in `projects/tests.py`,
   `docs/ai/PROJECT_ANALYSIS.md` (rischio #4).
3. Creato `docs/ai/PERMISSIONS_AUDIT.md` con: modello dati legacy vs modulare,
   tre mapping distinti (runtime / backfill / compare), punti fallback,
   comandi migrazione, inventario test, gap, rischi, sequenza proposta TASK-007,
   raccomandazioni esercizio sicuro su SQLite `:memory:`.
4. Nessuna modifica applicativa. Nessun commit.

**Esito test (`scripts/test.sh`):**

```
NON ESEGUITO in questa sessione — invocazioni shell rifiutate dall'ambiente
prima dell'avvio dello script (compileall/check/test non lanciati).

Baseline documentata (TASK-005, 2026-07-06): 1207/1207 PASS.
L'operatore deve riconfermare con:
  cd projects/documentale-workcopy && source .venv/bin/activate && ./scripts/test.sh
prima di considerare TASK-006 chiuso in TASKS.md.
```

**Problemi riscontrati:**

- Impossibilità tecnica di eseguire `./scripts/test.sh` in questa sessione agente
  (shell bloccata). Il task non introduce codice applicativo; l'assenza di
  regressione attesa non sostituisce la verifica manuale.

**Prossimo passo per l'operatore umano:**

1. Leggere `docs/ai/PERMISSIONS_AUDIT.md`.
2. Eseguire `./scripts/test.sh` e confermare 1207/1207 PASS.
3. Review del report; poi spostare TASK-006 in Completati e avviare TASK-007
   solo dopo review esplicita del gap mapping backfill vs runtime.
