# PROJECT_ANALYSIS — Documentale Workcopy

Report di analisi iniziale (TASK-001). Solo lettura del codice e della documentazione
presenti in `projects/documentale-workcopy`. Nessuna modifica applicativa.

**Data analisi:** 2026-07-05  
**Agente:** Cursor Agent  
**Branch atteso:** `task/documentale-workcopy` (workcopy Station)

---

## Panoramica del progetto

**Documentale** è un sistema documentale interno Django per una piccola azienda.
Gestisce documenti di qualità e di progetto con revisioni, approvazioni interne,
Engineering Change Notices (ECN), progetti con snapshot versione/revisione,
audit trail e notifiche (email + in-app).

### Scopo e vincoli di dominio

Principio architetturale centrale: **Document ≠ DocumentVersion ≠ DocumentFile**.

- **Document** — identità logica (codice, titolo, categoria, cartella progetto).
- **DocumentVersion** — revisione con ciclo di vita (`DRAFT → IN_APPROVAL → APPROVED / REJECTED → SUPERSEDED / ARCHIVED`).
- **DocumentFile** — file fisico caricato (hash SHA-256, MIME, dimensione).

Regole di visibilità: gli utenti normali vedono solo l'ultima revisione approvata
dei documenti attivi; bozze, versioni obsolete e documenti rifiutati sono visibili
solo ad autori, responsabili o ruoli con permessi elevati.

Funzionalità esplicitamente **fuori scope** (per design): firma digitale, OCR,
OpenSearch, React SPA, workflow engine complesso, gestionale general-purpose.

### Stato di maturità

Il progetto importato nella Station è **funzionalmente avanzato**: flussi documento,
approvazione, ECN, progetti, permessi cartella modulari, modalità sanatoria (backfill
storico), UI Tailwind con light/dark mode. La documentazione interna (`PROJECT_HANDOFF.md`,
`AI_CONTEXT.md`) indica una suite Django di oltre 1100 test, tutti verdi
nell'ultimo checkpoint documentato (2026-06-29).

La copia Station è stata **sanitizzata in onboarding**: contenuto `media/` rimosso;
`scripts/test.sh` è ancora un placeholder Station (nessun test Django collegato).

---

## Stack tecnologico

| Componente | Versione / dettaglio |
|------------|---------------------|
| Linguaggio | Python 3 (sviluppo originale su Windows/PyCharm; deploy target Python 3.12) |
| Framework | Django **5.2.14** (LTS) |
| Database dev | SQLite (`db.sqlite3`, default se `DB_ENGINE` non impostato) |
| Database prod | PostgreSQL via `psycopg` 3.3.4 (`django.db.backends.postgresql`) |
| Config env | `python-decouple` 3.8 |
| Server WSGI prod | `gunicorn` 23.0.0 |
| Frontend | Django templates + **Tailwind CSS v3** (^3.4.0), `@tailwindcss/forms` |
| Immagini | `pillow` 12.2.0 |
| HTMX | Non presente nel codice (menzionato in `CLAUDE.md` come opzione futura) |
| API REST | `djangorestframework` in `requirements.txt` ma **non registrato** in `INSTALLED_APPS` né usato nel codice |
| Filtri | `django-filter` in `requirements.txt` ma **non usato** nel codice |

Localizzazione: `LANGUAGE_CODE = 'it-it'`, `TIME_ZONE = 'Europe/Rome'`.

---

## Struttura cartelle (sintetica)

```
documentale-workcopy/
├── manage.py                 # Entry point Django CLI
├── config/                   # Progetto Django (settings, urls, wsgi, demo_utils)
├── accounts/                 # App utenti (modello User standard, nessuna estensione)
├── documents/                # Documenti, versioni, file, servizi revisione
├── approvals/                # Richieste approvazione, policy, decisioni
├── ecn/                      # Engineering Change Notices, CCB, dossier
├── projects/                 # Cartelle, progetti, snapshot versione/revisione, permessi
├── auditlog/                 # AuditLog live + HistoricalRecord (sanatoria)
├── notifications/            # Notifiche in-app + log email
├── templates/                # Template HTML globali (per app)
├── static/                   # Asset statici (css/tailwind.css committato)
├── src/css/                  # Sorgente Tailwind (main.css)
├── media/                    # Upload utente (vuoto in workcopy — rimosso in onboarding)
├── scripts/                  # test.sh (placeholder Station)
├── docs/ai/                  # Documentazione AI Software Station
├── requirements.txt
├── package.json              # Build Tailwind
├── DEPLOY.md                 # Guida deploy Linux/PostgreSQL/nginx
├── README.md
├── CLAUDE.md                 # Regole architetturali
├── AI_CONTEXT.md             # Briefing tecnico per AI
├── PROJECT_HANDOFF.md        # Checkpoint, comandi, backlog interno
├── AGENTS.md                 # Regole operative agenti
└── .env.example              # Template variabili d'ambiente
```

### App Django principali

| App | Ruolo | Note |
|-----|-------|------|
| `accounts` | Autenticazione Django standard | `models.py` vuoto; nessun profilo utente custom |
| `documents` | Core documentale | Modelli, servizi revisione, permessi, gate ECN configurabile (`requires_ecn_for_revision`) |
| `approvals` | Workflow approvazione | Policy ANY/ALL/SEQUENTIAL, allegati, integrazione sanatoria |
| `ecn` | Change Notice + CCB | Flusso DRAFT→CLOSED, dossier istruttorio, coordinator visibility |
| `projects` | Cartelle ad albero (materialized path), progetti, snapshot | Permessi modulari `FolderPermissionGrant` + legacy `ProjectFolderMembership` |
| `auditlog` | Tracciamento azioni | `AuditLog` (live) + `HistoricalRecord` (sanatoria/backfill) |
| `notifications` | Comunicazioni | In-app (`Notification`) + email (`NotificationLog`), template email ECN |
| `config` | Settings e routing root | `settings.py`, `urls.py`, `demo_utils.py`, `wsgi.py` |

**Migrazioni:** 33 file di migrazione distribuiti tra le app (16 in `projects`, 5 in `documents`, 5 in `approvals`, 3 in `ecn`, 2 in `auditlog`, 2 in `notifications`).

**Management commands utili:**

- `setup_document_groups` — creazione gruppi applicativi
- `demo_company`, `demo_workflow`, `demo_full` — popolamento DB demo
- `backfill_folder_permission_grants` — migrazione permessi legacy → modulari
- `compare_folder_permissions` — confronto permessi legacy vs modulari

---

## Entry point

| File | Funzione |
|------|----------|
| `manage.py` | CLI Django; imposta `DJANGO_SETTINGS_MODULE=config.settings` |
| `config/settings.py` | Configurazione completa (env-driven via `python-decouple`) |
| `config/urls.py` | Routing root: dashboard, documenti, cartelle/progetti, approvazioni, ECN, notifiche, auth |
| `config/wsgi.py` | Application WSGI per gunicorn (`config.wsgi:application`) |
| `config/asgi.py` | ASGI (standard Django, non usato in deploy documentato) |

URL principali (da `config/urls.py`):

- `/` — dashboard
- `/documents/` — CRUD documenti e revisioni
- `/folders/`, `/projects/`, `/project-revisions/` — gestione progetti
- `/approvals/` — coda approvazioni
- `/ecn/` — ECN
- `/notifications/` — inbox notifiche
- `/accounts/login|logout/` — autenticazione

---

## Dipendenze Python

Da `requirements.txt`:

```
asgiref==3.11.1
Django==5.2.14
django-filter==25.2          # dichiarato, non integrato nel codice
djangorestframework==3.17.1  # dichiarato, non integrato nel codice
gunicorn==23.0.0
pillow==12.2.0
psycopg==3.3.4
psycopg-binary==3.3.4
python-decouple==3.8
sqlparse==0.5.5
tzdata==2026.2
```

**Osservazione:** `djangorestframework` e `django-filter` sono pinati ma assenti da
`INSTALLED_APPS` e da qualsiasi import nel codebase — probabile residuo o preparazione
non completata.

---

## Dipendenze Node/frontend

Da `package.json`:

| Pacchetto | Versione | Uso |
|-----------|----------|-----|
| `tailwindcss` | ^3.4.0 | Compilazione CSS |
| `@tailwindcss/forms` | ^0.5.0 | Plugin form Tailwind |

Script npm:

- `npm run dev` — watch: `src/css/main.css` → `static/css/tailwind.css`
- `npm run build` — build minificata produzione

Il CSS compilato (`static/css/tailwind.css`) è **committato** intenzionalmente:
Node.js non è richiesto in produzione.

Configurazione tema: `tailwind.config.js` (dark mode `class`, palette brand ELT navy/ciano).

---

## Comandi di avvio (dedotti, non eseguiti)

### Sviluppo locale (Linux/bash, equivalente documentato in PowerShell)

```bash
# Ambiente Python (presupposto venv attivo e dipendenze installate)
cp .env.example .env   # compilare SECRET_KEY e altre variabili
python manage.py migrate
python manage.py runserver

# Frontend CSS (terminale separato, opzionale se si modifica Tailwind)
npm install
npm run dev
```

### Demo / sanatoria

Variabile ambiente `DOCUMENTALE_DEMO_MODE=true` abilita la modalità sanatoria.
Utente supervisore: username configurabile via `DOCUMENTALE_DEMO_SUPERVISOR_USERNAME`
(default `supervisor_demo`).

Popolamento demo esteso (documentato in `PROJECT_HANDOFF.md`):

```bash
python manage.py demo_full --reset --no-email
```

### Produzione

Vedi sezione deployment; avvio via systemd + gunicorn su socket Unix.

---

## Comandi di test (dedotti, non eseguiti)

### Suite Django (progetto originale)

Documentazione interna (`PROJECT_HANDOFF.md`, `AI_CONTEXT.md`):

```bash
python manage.py test auditlog documents approvals ecn projects accounts notifications --keepdb --failfast --verbosity=1
```

Suite completa stimata: **~1127–1207 test** (conteggi leggermente divergenti tra documenti;
vedi Problemi evidenti).

Altri file test:

- `documents/tests_ui.py`, `documents/tests_tailwind_ui.py` — test UI
- `notifications/tests_workflow_emails.py`, `notifications/tests_inapp.py` — notifiche

Check Django consigliati in `AGENTS.md`:

```bash
python manage.py check
python manage.py makemigrations --check --dry-run
```

### Station (`scripts/test.sh`)

Attualmente **placeholder**: stampa messaggio e termina con exit 0.
Non esegue la suite Django.

---

## Configurazioni di deployment rilevanti

`DEPLOY.md` descrive deploy su **Debian/Ubuntu** con:

1. PostgreSQL (database `documentale`, utente dedicato)
2. Virtualenv Python 3.12 + `pip install -r requirements.txt`
3. File `.env` da `.env.example` (SECRET_KEY, ALLOWED_HOSTS, DB_*, SSL flags)
4. `migrate`, `collectstatic`, `createsuperuser`
5. Creazione gruppi applicativi (nomi in `DEPLOY.md` differiscono da quelli in `AI_CONTEXT.md` — vedi Problemi)
6. Servizio **systemd** gunicorn (3 worker, socket `/run/documentale.sock`)
7. **nginx** reverse proxy (static/media + proxy pass)
8. SSL opzionale (Let's Encrypt o certificato aziendale)

`config/settings.py` legge tutte le variabili sensibili da env:

- Sicurezza: `SECRET_KEY`, `DEBUG`, `ALLOWED_HOSTS`, `CSRF_TRUSTED_ORIGINS`, HSTS/cookie secure
- Database: `DB_ENGINE`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`
- Demo: `DOCUMENTALE_DEMO_MODE`, `DOCUMENTALE_DEMO_SUPERVISOR_USERNAME`
- Email: relay SMTP Office 365 (`EMAIL_HOST`, porta 25, TLS)

---

## Presenza di file sensibili

Solo elenco percorsi — **nessun valore letto o riportato**.

| Percorso | Stato in workcopy | Note |
|----------|-------------------|------|
| `.env` | **Assente** (gitignored) | Da creare localmente da `.env.example` |
| `.env.example` | Presente | Template con placeholder (non segreti reali) |
| `db.sqlite3` | **Assente** (gitignored) | DB locale non incluso nella copia |
| `media/` | Presente ma **vuoto** | 235 file rimossi in onboarding (nota in `.gitkeep-note.txt`) |
| `.claude/settings.local.json` | Presente | Config locale Claude Code (gitignored da `.gitignore` per `.claude/`) |
| `.idea/` | Presente | Config IDE PyCharm (gitignored) |
| `PROJECT_HANDOFF.md` | Documenta credenziali demo locali | Non riportate in questo report |

---

## Rischi tecnici

1. **Test Station disconnessi dal progetto** — `scripts/test.sh` non verifica nulla del
   Django importato; i task futuri nella Station potrebbero procedere senza regression check
   finché non si collega la suite reale.

2. **Ambiente non bootstrappabile out-of-the-box** — Mancano `.env`, `db.sqlite3`, `media/`
   e virtualenv; ogni agente deve configurare l'ambiente prima di test/migrate (fuori scope
   TASK-001, ma blocca sviluppo operativo).

3. **Dipendenze Python non utilizzate** — DRF e django-filter aumentano superficie
   di manutenzione e audit senza beneficio attuale.

4. **Doppio sistema permessi cartella** — `FolderPermissionGrant` (modulare) coesiste con
   `ProjectFolderMembership` (legacy) tramite fallback nel resolver; rischio incoerenze
   finché la migrazione non è completata e il fallback rimosso.

5. **Documentazione interna parzialmente obsoleta** — Branch attivo, conteggio test e nomi
   gruppi differiscono tra file (`AI_CONTEXT.md` vs `PROJECT_HANDOFF.md` vs `DEPLOY.md`).

6. **Segreti in `.env.example`** — Contiene hostname email aziendale e placeholder password;
   il file è committato per design (template), ma va trattato con cura in review.

7. **Suite test pesante** — Oltre 1100 test; esecuzione completa può richiedere tempo
   significativo senza `--keepdb` o selezione per app.

8. **Istruzioni in `AGENTS.md` del progetto importato** — Presuppongono runserver/Tailwind
   attivi e commit locali autonomi; possono entrare in conflitto con guardrail Station
   (da armonizzare in task dedicato).

---

## Problemi evidenti

| # | Problema | Evidenza |
|---|----------|----------|
| 1 | `scripts/test.sh` placeholder | Nessun test Django eseguito dalla Station |
| 2 | DRF/django-filter in requirements ma inutilizzati | Nessun import/`INSTALLED_APPS` |
| 3 | Conteggio test incoerente nella documentazione | 1186 (`AI_CONTEXT`), 1207 e 1127 (`PROJECT_HANDOFF`) |
| 4 | Branch attivo discordante | `AI_CONTEXT.md` cita `authz-foundation`; `PROJECT_HANDOFF.md` cita `main` |
| 5 | Nomi gruppi Django inconsistenti | `DEPLOY.md`: "Document Authors", …; `AI_CONTEXT.md`: `readers`, `authors`, … |
| 6 | Permessi legacy ancora attivi | `include_legacy_fallback=True` diffuso in `projects/` |
| 7 | Nessun TODO/FIXME critico nel codice Python | Grep su `TODO|FIXME` senza match applicativi |
| 8 | `accounts/models.py` vuoto | Coerente con design ma gruppi/permessi dipendono da setup manuale |
| 9 | Media rimosso | Impossibile testare download file senza rigenerare demo o ricaricare |
| 10 | Mancano artefatti Station standard | Nessun `PROJECT_BRIEF.md`, `ARCHITECTURE.md`, `RUN_LOG.md` (pre-TASK-001) in `docs/ai/` |

---

## Roadmap proposta in task piccoli

Task pensati per trascrizione manuale nel Backlog di `docs/ai/TASKS.md` dopo review
operatore.

| ID | Descrizione (una riga) |
|----|------------------------|
| **TASK-002** | Collegare `scripts/test.sh` alla suite Django (`manage.py test` con subset o suite completa, exit non-zero su fallimento). |
| **TASK-003** | Documentare e scriptare bootstrap ambiente dev nella workcopy (`.env` da example, migrate, `setup_document_groups`, comando demo opzionale). |
| **TASK-004** | Completare migrazione permessi cartella: eseguire `backfill_folder_permission_grants`, verificare con `compare_folder_permissions`, test di regressione. |
| **TASK-005** | Rimuovere o integrare dipendenze inutilizzate (`djangorestframework`, `django-filter`) e allineare `requirements.txt` al codice effettivo. |
| **TASK-006** | Allineare documentazione operativa (`DEPLOY.md`, `AI_CONTEXT.md`, `PROJECT_HANDOFF.md`) su nomi gruppi, conteggio test e branch di riferimento. |
| **TASK-007** | Admin Django per `HistoricalRecord` con filtri per tipo evento e data storica (backlog già indicato in `PROJECT_HANDOFF.md`). |
| **TASK-008** | Export audit trail (live e/o storico sanatoria) in PDF — feature backlog documentata. |
| **TASK-009** | Deploy effettivo su server aziendale seguendo `DEPLOY.md` (PostgreSQL, gunicorn, nginx, SSL). |

---

## Raccomandazione sul prossimo task

**Eseguire TASK-002 (configurazione test reale in `scripts/test.sh`)** come primo passo
operativo dopo la review di questo report.

Motivazione:

- È il prerequisito per qualsiasi ciclo AI Software Station affidabile (test obbligatori
  prima di commit/review).
- Il progetto Django ha già una suite estesa e documentata; collegarla al placeholder
  è a basso rischio e alto valore.
- Non richiede modifiche alla logica applicativa né accesso a segreti o database esistente
  (si può partire con migrate + test su DB temporaneo).
- TASK-003 (bootstrap ambiente) può seguire subito dopo o essere combinato se l'operatore
  preferisce, ma senza TASK-002 ogni implementazione futura resterebbe senza rete di
  sicurezza automatica.

Dopo TASK-002, l'operatore dovrebbe trascrivere la roadmap rivista nel Backlog di
`docs/ai/TASKS.md` e spostare TASK-001 in Completati post-review.
