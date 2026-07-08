# Deployment readiness — Documentale (TASK-011)

**Data:** 2026-07-08
**Progetto:** `projects/documentale-workcopy`
**Scope:** solo analisi e dry-run sicuri — **nessun deploy reale, nessun server avviato, nessuna migrazione eseguita, nessun segreto letto**.

---

## 1. Stato generale deployment

Il progetto **non è mai stato deployato da questa workcopy**: nessun
`db.sqlite3`, nessun `staticfiles/` (output di `collectstatic`), nessun
`.env` presenti. La procedura di deploy è documentata in `DEPLOY.md` ed è
coerente con lo stack reale del codice (verificato in questo task), ma
non è mai stata eseguita qui, né deve esserlo in questo task.

**Verdetto sintetico:** documentazione di deploy tecnicamente accurata
(dopo le correzioni di TASK-010 sui nomi gruppo), stack coerente,
nessun blocco bloccante trovato. Non idoneo a un deploy realmente
automatizzato senza una prova controllata (vedi §12).

---

## 2. Stack rilevato

| Componente | Dettaglio | Fonte |
|---|---|---|
| Framework | Django 5.2.14 | `requirements.txt`, `config/settings.py` |
| Python | 3.x (venv locale in uso: verificare versione server) | `.venv` |
| DB previsto produzione | PostgreSQL, via `psycopg`/`psycopg-binary` 3.3.4, selezionato con `DB_ENGINE` in `.env` | `config/settings.py` righe 79–98 |
| DB sviluppo/test | SQLite (`db.sqlite3` per dev, `:memory:` per test) | `config/settings.py`, `config/test_settings.py` |
| Static/media | `STATIC_ROOT=staticfiles/`, `MEDIA_ROOT=media/`, serviti da nginx in produzione (non da Django) | `config/settings.py` righe 121–126, `DEPLOY.md` §7 |
| WSGI | `config/wsgi.py` → `config.wsgi:application`, servito da gunicorn 23.0.0 | `config/wsgi.py`, `DEPLOY.md` §6 |
| ASGI | `config/asgi.py` presente ma **non usato** in `DEPLOY.md` (deploy è WSGI/gunicorn puro, nessun websocket/async) | `config/asgi.py` |
| Frontend | Tailwind CSS v3, CSS compilato **committato** in `static/css/tailwind.css` (58 KB, verificato presente) — Node.js **non richiesto in produzione** | `package.json`, `README.md` |
| Email | SMTP (Office 365/Exchange relay), configurabile via env, nessuna credenziale richiesta dal relay secondo il commento in `config/settings.py` | `config/settings.py` righe 145–158 |
| Reverse proxy | nginx (statico + proxy verso gunicorn via unix socket) | `DEPLOY.md` §7 |
| Process manager | systemd unit `documentale.service` | `DEPLOY.md` §6 |

---

## 3. Comandi documentati — verifica esistenza

Tutti i comandi citati in `DEPLOY.md` sono stati verificati con
`manage.py help` (elenco comandi, nessuna esecuzione reale):

| Comando | Citato in DEPLOY.md | Esiste? |
|---|---|---|
| `migrate` | Sì (§4) | ✅ standard Django |
| `collectstatic` | Sì (§4) | ✅ standard Django (**non eseguito** in questo audit, per sicurezza — scriverebbe potenzialmente molti file) |
| `createsuperuser` | Sì (§4) | ✅ standard Django |
| `manage.py shell -c "..."` (bootstrap gruppi) | Sì (§5) | ✅ funziona, ma vedi §8 — esiste un comando dedicato migliore |
| `certbot --nginx` | Sì (§8) | Comando di sistema, non Django — non verificabile da qui |

**Comando scoperto e non documentato in `DEPLOY.md`:**
`python manage.py setup_document_groups` — comando custom idempotente
(`documents/management/commands/setup_document_groups.py`) che crea
esattamente gli stessi 10 gruppi con descrizioni, leggendo le costanti
`GROUP_*` direttamente dal codice (fonte unica, mai disallineabile).
**Raccomandazione:** `DEPLOY.md` §5 dovrebbe usare questo comando al
posto dello snippet Python manuale — vedi §11.

Altri comandi custom presenti (non di deploy, solo per riferimento):
`demo_company`, `demo_full`, `demo_workflow` (app `documents`) —
popolano dati demo, **non vanno mai eseguiti in produzione** (non citati
in `DEPLOY.md`, correttamente); `backfill_folder_permission_grants`,
`compare_folder_permissions` (app `projects`) — comandi di migrazione
permessi cartella (TASK-007), fuori scope del deploy base.

---

## 4. Variabili/configurazioni richieste

Tutte le chiavi lette da `config/settings.py` tramite `python-decouple`
sono presenti in `.env.example` — **verificata la coerenza, nessuna
chiave mancante né chiave extra non usata**:

`SECRET_KEY`, `DEBUG`, `ALLOWED_HOSTS`, `CSRF_TRUSTED_ORIGINS`,
`SECURE_SSL_REDIRECT`, `SESSION_COOKIE_SECURE`, `CSRF_COOKIE_SECURE`,
`SECURE_HSTS_SECONDS`, `SECURE_HSTS_INCLUDE_SUBDOMAINS`,
`SECURE_HSTS_PRELOAD`, `DB_ENGINE`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`,
`DB_HOST`, `DB_PORT`, `DOCUMENTALE_DEMO_MODE`,
`DOCUMENTALE_DEMO_SUPERVISOR_USERNAME`, `EMAIL_BACKEND`, `EMAIL_HOST`,
`EMAIL_PORT`, `EMAIL_USE_TLS`, `EMAIL_USE_SSL`, `EMAIL_HOST_USER`,
`EMAIL_HOST_PASSWORD`, `DEFAULT_FROM_EMAIL`.

Nessun valore letto o riportato — solo nomi di chiave, come da guardrail.
`.env` reale **non presente** in questa workcopy (corretto, mai creato).

---

## 5. Checklist VM locale (dry-run, per una prova futura controllata)

- [ ] Python 3.12+ disponibile (`DEPLOY.md` richiede 3.12 via apt)
- [ ] PostgreSQL disponibile (locale o container), oppure restare su
      SQLite per una prova locale non rappresentativa della produzione
- [ ] `python3 -m venv .venv && pip install -r requirements.txt` in
      ambiente pulito (non la venv Station esistente, per non
      contaminarla)
- [ ] `.env` locale creato da `.env.example` con valori di prova (mai
      valori reali aziendali)
- [ ] `DEBUG=True` per la prova iniziale (per vedere errori dettagliati),
      **mai in un ambiente esposto in rete**
- [ ] `python manage.py migrate` su DB di prova dedicato (mai il DB reale
      di produzione)
- [ ] `python manage.py setup_document_groups` (raccomandato, vedi §3)
- [ ] `python manage.py createsuperuser` con credenziali di prova
- [ ] `python manage.py collectstatic` in directory di prova
- [ ] Avvio con `python manage.py runserver` (solo per verifica locale
      rapida) — **non eseguito in questo task**

---

## 6. Checklist pre-deploy (produzione reale)

- [ ] `SECRET_KEY` generato in modo sicuro (mai riusare quello di test)
- [ ] `DEBUG=False`
- [ ] `ALLOWED_HOSTS`/`CSRF_TRUSTED_ORIGINS` con dominio/IP reale del
      server, non i default di sviluppo
- [ ] PostgreSQL con utente/password dedicati (non `postgres` superuser)
- [ ] `SECURE_SSL_REDIRECT`/`SESSION_COOKIE_SECURE`/`CSRF_COOKIE_SECURE`
      = `True` **dopo** che SSL è realmente attivo (attivarli prima
      romperebbe l'accesso via HTTP)
- [ ] Backup del DB configurato prima del primo `migrate` su dati reali
- [ ] `python manage.py setup_document_groups` eseguito prima di
      assegnare utenti ai gruppi
- [ ] Verifica manuale che il relay SMTP aziendale sia raggiungibile
      dalla rete del server (non verificabile da questa venv locale)
- [ ] `media/` con permessi `www-data` corretti (§9 di `DEPLOY.md`) —
      **attenzione**: file caricati dagli utenti, backup necessario
      separato dal codice

---

## 7. Rischi/blocchi

| # | Rischio | Severità | Note |
|---|---------|----------|------|
| R1 | Compatibilità PostgreSQL mai verificata | Media | I test usano solo SQLite `:memory:` per design (`docs/ai/TESTING_STATUS.md`); nessuna verifica reale di migrazioni/query su Postgres è mai stata fatta in questa workcopy |
| R2 | `EMAIL_HOST`/relay aziendale non verificabile da qui | Bassa | Richiede rete aziendale reale; fuori portata di un audit locale |
| R3 | Bootstrap gruppi manuale in `DEPLOY.md` più fragile del comando dedicato | Bassa (già corretto TASK-010, comando migliore comunque raccomandato) | Vedi §3/§11 |
| R4 | Nessuna prova end-to-end di `collectstatic`/gunicorn/nginx mai eseguita | Media | La procedura è coerente sulla carta (WSGI target corretto, static/media path coerenti) ma non è mai stata eseguita nemmeno in locale da questa workcopy |
| R5 | `media/` locale contiene file (non ispezionati, vedi §8) | Bassa | Correttamente escluso da `.gitignore`, non finisce nel repository |

Nessun rischio bloccante trovato per procedere a una prova controllata
(TASK-012 raccomandato).

---

## 8. Errori documentali trovati

- **TASK-010 (già corretto prima di questo task):** `DEPLOY.md` creava
  un gruppo `'Quality Managers'` (plurale, inesistente nel codice)
  invece di `'Quality Manager'`.
- **Nuovo, trovato in questo task:** `DEPLOY.md` §5 usa uno snippet
  Python manuale per creare i gruppi, mentre esiste un comando dedicato
  idempotente (`setup_document_groups`) che fa la stessa cosa leggendo
  le costanti dal codice — fonte singola, meno rischio di refuso futuro.
  **Corretto in questo task** (vedi §11).
- **Osservazione non bloccante:** `config/asgi.py` esiste ma non è
  menzionato né usato in `DEPLOY.md` — coerente (il deploy documentato è
  WSGI/gunicorn puro), nessuna azione necessaria.

`media/` locale contiene **501 file** (verificato solo il conteggio,
**nessun contenuto letto**). Un file `.gitkeep-note.txt` presente nella
cartella dichiara esplicitamente che il contenuto reale originale (235
file, documenti caricati dagli utenti) è stato **rimosso durante
l'onboarding** per motivi di sicurezza/privacy e non deve mai entrare
nella Station né essere letto da un agente AI. Il conteggio attuale
(501, diverso da 235) suggerisce file generati da esecuzioni demo/dev
locali successive all'onboarding, non i documenti aziendali originali —
ma questo **non è stato verificato aprendo i file**, per rispetto del
guardrail. `media/` resta correttamente escluso da `.gitignore` e non
viene mai committato.

---

## 9. Cosa è stato verificato con dry-run

- `python manage.py check --settings=config.test_settings` → **0
  problemi**.
- `python manage.py check --deploy --settings=config.test_settings` → 6
  warning, tutti **attesi e coerenti con un ambiente di test** (DEBUG=True,
  SECRET_KEY fittizia corta, nessun SSL) — nessuna sorpresa, confermano
  che le impostazioni di sicurezza sono correttamente cablate a variabili
  d'ambiente e si attivano quando configurate.
- Esistenza di tutti i comandi management citati in `DEPLOY.md`
  (`manage.py help`), più scoperta di `setup_document_groups`.
- Coerenza `.env.example` ↔ `config/settings.py` (tutte le chiavi
  lette da `config()` sono presenti in `.env.example`, nessuna mancante).
- Presenza del CSS Tailwind compilato e committato
  (`static/css/tailwind.css`, 58 KB) — coerente con "Node.js non
  necessario in produzione" di `README.md`.
- Assenza di `db.sqlite3`, `staticfiles/`, `.env` in questa workcopy
  (nessun deploy/collectstatic/migrate mai eseguito qui).
- Suite Django reale: **1208/1208 PASS**, `pip check` pulito (vedi §14).

---

## 10. Cosa NON è stato eseguito per sicurezza

- **Nessun `migrate` reale** (né su SQLite dev né su PostgreSQL).
- **Nessun `collectstatic`** (avrebbe scritto potenzialmente centinaia
  di file in `staticfiles/`).
- **Nessun `runserver`** o avvio di gunicorn/nginx.
- **Nessuna lettura di `.env`** (non esiste in questa workcopy) né di
  alcun valore segreto.
- **Nessuna lettura del contenuto di `media/`** (solo conteggio file e
  lettura della nota di sicurezza `.gitkeep-note.txt`).
- **Nessun comando di sistema** (`apt`, `systemctl`, `certbot`, `psql`)
  eseguito realmente.
- **Nessuna modifica a `requirements.txt`, `config/settings.py`, o
  codice applicativo.**

---

## 11. Raccomandazioni per eventuale TASK-012

1. **`DEPLOY.md` §5** — sostituire lo snippet Python manuale con
   `python manage.py setup_document_groups` (comando idempotente
   esistente, fonte unica dei nomi gruppo). *(Applicato in questo
   task, vedi diff.)*
2. Aggiungere a `DEPLOY.md` una nota esplicita che
   `python manage.py check --deploy` va eseguito con l'`.env` di
   produzione reale prima del primo avvio, per validare che i security
   warning visti in questo audit (attesi solo in ambiente di test)
   siano davvero risolti in produzione.
3. **TASK-012 (Hardening configurazione test)**, già in backlog — non
   sovrapposto a questo task, resta valido come miglioria separata a
   `config/test_settings.py`/`scripts/test.sh`.
4. Se si vuole una prova di deploy reale, farla su una **VM/container
   isolato e dedicato**, mai sulla macchina Station, seguendo la
   checklist §5, con dati di test — non su dati aziendali reali.

---

## 12. Acceptance criteria per una prova deploy controllata futura

Se in futuro si vorrà eseguire un vero dry-run applicativo (non solo
documentale come questo TASK-011), la prova dovrebbe:

- [ ] Avvenire in una VM/container isolato, mai sulla macchina/repo
      Station attuale.
- [ ] Usare un `.env` con valori di prova, mai credenziali reali
      aziendali.
- [ ] Usare un DB PostgreSQL di prova dedicato (non il DB reale).
- [ ] Eseguire `migrate` → `setup_document_groups` → `createsuperuser`
      (utente di prova) → `collectstatic` → avvio gunicorn locale (non
      esposto in rete) → verifica manuale di login e una singola
      operazione (es. creazione documento).
- [ ] Documentare l'esito in un nuovo file (es.
      `docs/ai/DEPLOYMENT_DRYRUN_RESULT.md`), senza includere segreti.
- [ ] Distruggere l'ambiente di prova al termine (DB, `.env`, VM).

---

## 13. File analizzati

`DEPLOY.md`, `README.md`, `AI_CONTEXT.md`, `PROJECT_HANDOFF.md`,
`manage.py`, `config/settings.py`, `config/test_settings.py`,
`config/wsgi.py`, `config/asgi.py`, `.env.example` (solo chiavi),
`requirements.txt`, `package.json`, `tailwind.config.js` (presenza),
`static/css/tailwind.css` (presenza), `documents/management/commands/
setup_document_groups.py`, `docs/ai/TESTING_STATUS.md`,
`docs/ai/RUN_LOG.md`.

## 14. Esito test

Suite Django reale: **1208/1208 PASS** (rieseguita dopo il merge di
TASK-010, invariata). `pip check`: "No broken requirements found."
Regressioni Station (cursor-prompt-builder, log-analyzer,
ai-cycle-dogfood): verdi.
