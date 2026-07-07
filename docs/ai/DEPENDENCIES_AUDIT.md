# Audit dipendenze `requirements.txt` — TASK-008

**Data audit:** 2026-07-07  
**Progetto:** `projects/documentale-workcopy`  
**Branch:** `task/documentale-dependencies-audit`  
**Scope:** sola analisi — nessuna modifica a `requirements.txt`, settings o codice applicativo.

---

## Metodologia

Analisi read-only su:

- `requirements.txt` (11 pacchetti pinati)
- `config/settings.py`, `config/test_settings.py`, `config/wsgi.py`, `config/asgi.py`
- Tutto il codebase Python (`*.py`) con ricerca import e riferimenti a `INSTALLED_APPS`
- `DEPLOY.md`, `.env.example`, `manage.py`, `scripts/test.sh`
- Confronto con il problema #2 di `docs/ai/PROJECT_ANALYSIS.md` (DRF / django-filter)

Comandi grep eseguiti (root: `projects/documentale-workcopy/`):

```bash
rg "rest_framework|django_filters|djangorestframework|django-filter" --glob '*.py'
rg "from PIL|import PIL|ImageField" --glob '*.py'
rg "gunicorn" --glob '*.{py,md,sh,ini,service}'
rg "psycopg" --glob '*.{py,md,env*,example}'
rg "asgiref|sqlparse|tzdata" --glob '*.py'
rg "decouple|from decouple" --glob '*.py'
rg "FileField|ImageField" --glob '*.py'
rg "INSTALLED_APPS|rest_framework|django_filters|filter_backends|ModelViewSet|APIView" --glob '*.py'
rg "DB_ENGINE|postgresql" --glob '*.{py,env*,example}'
```

Moduli settings analizzati: solo `config/settings.py` e `config/test_settings.py` (nessuna directory `settings/` split).

---

## Riepilogo classificazioni

| # | Pacchetto | Versione | Classificazione | Categoria |
|---|-----------|----------|-----------------|-----------|
| 1 | `asgiref` | 3.11.1 | Probabilmente usata | Runtime (indiretta via Django) |
| 2 | `Django` | 5.2.14 | Usata chiaramente | Runtime |
| 3 | `django-filter` | 25.2 | Apparentemente inutilizzata | Runtime (non integrata) |
| 4 | `djangorestframework` | 3.17.1 | Apparentemente inutilizzata | Runtime (non integrata) |
| 5 | `gunicorn` | 23.0.0 | Usata chiaramente | Runtime/deploy |
| 6 | `pillow` | 12.2.0 | Dubbia | Runtime (non integrata nel codice) |
| 7 | `psycopg` | 3.3.4 | Usata chiaramente | Runtime/deploy |
| 8 | `psycopg-binary` | 3.3.4 | Usata chiaramente | Runtime/deploy |
| 9 | `python-decouple` | 3.8 | Usata chiaramente | Runtime |
| 10 | `sqlparse` | 0.5.5 | Probabilmente usata | Runtime (indiretta via Django) |
| 11 | `tzdata` | 2026.2 | Probabilmente usata | Runtime (indiretta via Django) |

**Conteggio:** 5 usate chiaramente · 3 probabilmente usate (indirette) · 1 dubbia · 2 apparentemente inutilizzate.

---

## Dettaglio per dipendenza

### 1. `asgiref==3.11.1`

| Campo | Valore |
|-------|--------|
| **Classificazione** | Probabilmente usata |
| **Categoria** | Runtime (dipendenza transitiva di Django, pin esplicito) |

**Evidenza positiva (indiretta):**

- Django 5.2 dipende da `asgiref` per ASGI/WSGI e utilità async/sync (`django.core.asgi`, middleware, ORM).
- `config/asgi.py` riga 12: `from django.core.asgi import get_asgi_application` — il runtime ASGI usa la stack Django che importa `asgiref` internamente.
- `scripts/test.sh` righe 88–95: verifica importabilità di `asgiref` come dipendenza di `requirements.txt`.

**Evidenza negativa (codice applicativo):**

```bash
rg "asgiref" --glob '*.py'
# Risultato: nessun match nel codebase applicativo
```

**Nota:** pin esplicito tipico di un `pip freeze`; rimuoverlo lascerebbe comunque `asgiref` installato come dipendenza di Django, ma con versione non pinata.

---

### 2. `Django==5.2.14`

| Campo | Valore |
|-------|--------|
| **Classificazione** | Usata chiaramente |
| **Categoria** | Runtime |

**Evidenza positiva:**

- Framework centrale: tutte le app (`accounts`, `documents`, `approvals`, `projects`, `auditlog`, `notifications`, `ecn`) importano moduli `django.*`.
- `manage.py` righe 11–18: `from django.core.management import execute_from_command_line`.
- `config/settings.py` righe 29–43: `INSTALLED_APPS` con 7 app custom + contrib Django.
- `config/wsgi.py` riga 12: `from django.core.wsgi import get_wsgi_application`.
- `scripts/test.sh`: esegue `compileall`, `manage.py check`, `manage.py test` — tutti richiedono Django.

---

### 3. `django-filter==25.2`

| Campo | Valore |
|-------|--------|
| **Classificazione** | Apparentemente inutilizzata |
| **Categoria** | Runtime (dichiarata ma non integrata) |

**Evidenza negativa (verifica esplicita TASK-008):**

```bash
rg "rest_framework|django_filters|django-filter|djangorestframework" --glob '*.py'
# Risultato: nessun match nel codice Python applicativo
```

```bash
rg "django_filters|django_filters" config/settings.py
# Risultato: nessun match
```

- `config/settings.py` righe 29–43 — `INSTALLED_APPS` **non** contiene `'django_filters'`.
- Nessun `FilterSet`, `DjangoFilterBackend`, import `django_filters` in views, forms, admin o test.

**Conferma problema #2 di `PROJECT_ANALYSIS.md`:** il caso segnalato (pinato ma assente da `INSTALLED_APPS` e import) **è ancora vero** al 2026-07-07.

---

### 4. `djangorestframework==3.17.1`

| Campo | Valore |
|-------|--------|
| **Classificazione** | Apparentemente inutilizzata |
| **Categoria** | Runtime (dichiarata ma non integrata) |

**Evidenza negativa (verifica esplicita TASK-008):**

```bash
rg "rest_framework|djangorestframework" --glob '*.py'
# Risultato: nessun match nel codice Python applicativo
```

- `config/settings.py` righe 29–43 — `INSTALLED_APPS` **non** contiene `'rest_framework'`.
- Nessun `APIView`, `ViewSet`, `Router`, serializer DRF, URL `/api/`, `REST_FRAMEWORK` in settings.

**Conferma problema #2 di `PROJECT_ANALYSIS.md`:** **ancora vero** — residuo o preparazione API REST mai completata.

---

### 5. `gunicorn==23.0.0`

| Campo | Valore |
|-------|--------|
| **Classificazione** | Usata chiaramente |
| **Categoria** | Runtime/deploy |

**Evidenza positiva (deploy, non import Python):**

- `DEPLOY.md` righe 3, 94–111: servizio systemd con  
  `ExecStart=.../gunicorn --workers 3 --bind unix:/run/documentale.sock config.wsgi:application`
- `config/wsgi.py` espone `application` — target WSGI per gunicorn.
- `PROJECT_HANDOFF.md`: registra aggiunta di `gunicorn==23.0.0` a `requirements.txt`.
- `scripts/test.sh` righe 88–95: verifica importabilità del pacchetto (controllo ambiente, non uso applicativo).

**Evidenza negativa (import diretto):**

```bash
rg "gunicorn" --glob '*.py'
# Risultato: nessun match — invocato solo da riga di comando in deploy
```

---

### 6. `pillow==12.2.0`

| Campo | Valore |
|-------|--------|
| **Classificazione** | Dubbia |
| **Categoria** | Runtime (non referenziata nel codice) |

**Evidenza negativa:**

```bash
rg "from PIL|import PIL|ImageField" --glob '*.py'
# Risultato: nessun match
```

```bash
rg "FileField|ImageField" --glob '*.py'
# Risultato: solo FileField, zero ImageField
```

Modelli con upload file (tutti `FileField`, non `ImageField`):

- `documents/models.py` riga 10 — `file = models.FileField(...)`
- `approvals/models.py` riga 104 — `file = models.FileField(...)`
- `ecn/models.py` riga 357 — `file = models.FileField(...)`
- `auditlog/models.py` riga 288 — `file = models.FileField(...)`

Django richiede Pillow **solo** per `ImageField` e operazioni su immagini; `FileField` per PDF/documenti **non** lo usa.

**Evidenza positiva debole:**

- `docs/ai/PROJECT_ANALYSIS.md` elenca Pillow sotto stack "Immagini", ma il codice non implementa campi immagine.
- Possibile intento futuro o residuo di template/scaffolding — non verificabile nel codice.

---

### 7. `psycopg==3.3.4`

| Campo | Valore |
|-------|--------|
| **Classificazione** | Usata chiaramente |
| **Categoria** | Runtime/deploy |

**Evidenza positiva:**

- `config/settings.py` righe 79–98: ramo `else` di `DATABASES` attivo quando `DB_ENGINE != sqlite3`; legge `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`.
- `.env.example` riga 22: `DB_ENGINE=django.db.backends.postgresql` — backend PostgreSQL ufficiale Django 5.2 usa **psycopg 3** (`psycopg` package).
- `DEPLOY.md` sezione 1: setup PostgreSQL per produzione.
- `documents/tests.py` righe 3200–3206: test con `'ENGINE': 'django.db.backends.postgresql'` (mock settings, non connessione reale).

**Evidenza negativa (import diretto):**

```bash
rg "import psycopg|from psycopg" --glob '*.py'
# Risultato: nessun match — caricato dal backend DB Django a runtime
```

---

### 8. `psycopg-binary==3.3.4`

| Campo | Valore |
|-------|--------|
| **Classificazione** | Usata chiaramente |
| **Categoria** | Runtime/deploy |

**Evidenza positiva:**

- Coppia standard con `psycopg`: `psycopg-binary` fornisce wheel precompilati (libpq) evitando compilazione C in deploy (`pip install -r requirements.txt` su server Debian/Ubuntu, vedi `DEPLOY.md` righe 44–46).
- `scripts/test.sh` righe 94–95: `psycopg | psycopg-binary) import_name="psycopg"` — entrambe mappate allo stesso import runtime.

**Nota:** non è ridondanza applicativa; è pattern di packaging per garantire installazione binaria in produzione.

---

### 9. `python-decouple==3.8`

| Campo | Valore |
|-------|--------|
| **Classificazione** | Usata chiaramente |
| **Categoria** | Runtime |

**Evidenza positiva:**

- `config/settings.py` riga 4: `from decouple import Csv, config`
- Stesso file, uso di `config()` per tutte le variabili d'ambiente critiche:
  - righe 11–14: `SECRET_KEY`, `DEBUG`, `ALLOWED_HOSTS`, `CSRF_TRUSTED_ORIGINS`
  - righe 19–24: impostazioni HTTPS/HSTS
  - righe 79, 92–96: `DB_ENGINE` e credenziali PostgreSQL
  - righe 140–143: modalità demo/sanatoria
  - righe 149–158: configurazione email SMTP

```bash
rg "decouple|from decouple" --glob '*.py'
# Risultato: solo config/settings.py (riga 4)
```

`config/test_settings.py` importa `from config.settings import *` — eredita la dipendenza da decouple (con variabili impostate in `os.environ` prima dell'import).

---

### 10. `sqlparse==0.5.5`

| Campo | Valore |
|-------|--------|
| **Classificazione** | Probabilmente usata |
| **Categoria** | Runtime (dipendenza transitiva di Django, pin esplicito) |

**Evidenza positiva (indiretta):**

- Django usa `sqlparse` per formattazione SQL (`django.db.backends.*`, shell SQL, migrazioni).
- `scripts/test.sh` verifica importabilità.

**Evidenza negativa (codice applicativo):**

```bash
rg "sqlparse" --glob '*.py'
# Risultato: nessun match nel codebase applicativo
```

---

### 11. `tzdata==2026.2`

| Campo | Valore |
|-------|--------|
| **Classificazione** | Probabilmente usata |
| **Categoria** | Runtime (indiretta via Django timezone) |

**Evidenza positiva (indiretta):**

- `config/settings.py` righe 114–116:
  ```python
  TIME_ZONE = 'Europe/Rome'
  USE_TZ = True
  ```
- Con `USE_TZ=True`, Django converte datetime in timezone (es. template `|date`, `timezone.localtime` usati in test e views). Su ambienti senza database IANA di sistema (es. Windows, container minimali), `tzdata` fornisce `zoneinfo` per `Europe/Rome`.
- `scripts/test.sh` verifica importabilità.

**Evidenza negativa (import diretto):**

```bash
rg "tzdata" --glob '*.py'
# Risultato: nessun match nel codebase applicativo
```

---

## Dipendenze usate solo indirettamente

Pacchetti **non importati** nel codice applicativo ma necessari o pinati per il runtime:

| Pacchetto | Meccanismo indiretto |
|-----------|---------------------|
| `asgiref` | Dipendenza runtime di Django (ASGI/sync) |
| `sqlparse` | Dipendenza runtime di Django (SQL parsing) |
| `tzdata` | Database timezone IANA per `USE_TZ=True` / `Europe/Rome` |
| `psycopg` / `psycopg-binary` | Driver PostgreSQL caricato da `django.db.backends.postgresql` quando `DB_ENGINE=postgresql` |
| `gunicorn` | Process manager WSGI invocato da systemd (`DEPLOY.md`), non importato in Python |

---

## Sezioni dedicate — dipendenze dubbie o apparentemente inutilizzate

### `django-filter` — apparentemente inutilizzata

**Evidenza negativa:**

```bash
rg "django_filters|django-filter|FilterSet|DjangoFilterBackend" --glob '*.py'
# Risultato: nessun match
```

- Assente da `INSTALLED_APPS` (`config/settings.py` righe 29–43).
- Nessun filtro declarative su queryset via django-filter.

**Rischio rimozione prematura:** basso per funzionalità attuale — nessun path applicativo la referenzia. Rischio operativo: se un branch/feature locale non mergeato usa django-filter, la rimozione romperebbe quel lavoro (non verificabile in questa copia).

---

### `djangorestframework` — apparentemente inutilizzata

**Evidenza negativa:**

```bash
rg "rest_framework|djangorestframework|APIView|ViewSet|DefaultRouter" --glob '*.py'
# Risultato: nessun match
```

- Assente da `INSTALLED_APPS`.
- Nessuna URL API REST, nessun serializer DRF, nessuna setting `REST_FRAMEWORK`.

**Rischio rimozione prematura:** basso per l'applicazione template-based attuale. Documentazione (`PROJECT_ANALYSIS.md`) la descrive come "preparazione non completata" — rimuoverla chiude quella opzione senza impatto sul flusso documenti/approvazioni esistente.

---

### `pillow` — dubbia

**Evidenza negativa:**

```bash
rg "from PIL|import PIL|ImageField" --glob '*.py'
# Risultato: nessun match
```

- Tutti gli upload usano `FileField` (PDF, allegati, evidence) — Pillow non richiesto da Django per `FileField`.
- `PROJECT_ANALYSIS.md` menziona Pillow sotto "Immagini" ma il codice non ha campi immagine.

**Rischio rimozione prematura:** medio-basso. Rimozione **non** dovrebbe rompere la suite attuale (1208 test su SQLite, nessun `ImageField`). Rischio se in futuro si aggiungono thumbnail/anteprima immagini o si convertono campi in `ImageField` senza reintrodurre Pillow.

---

## Rischi di rimozione

| Dipendenza | Se rimossa senza verifica | Impatto atteso |
|------------|---------------------------|----------------|
| `django-filter` | Nessun import/settings | **Nessun impatto** sul comportamento attuale verificato |
| `djangorestframework` | Nessun import/settings | **Nessun impatto** sul comportamento attuale verificato |
| `pillow` | Nessun `ImageField` | **Nessun impatto** attuale; blocca future funzionalità immagine |
| `asgiref` | Pin rimosso da requirements | Django reinstallerebbe una versione non pinata — **non rimuovere** come pacchetto standalone senza aggiornare il pin di Django |
| `sqlparse` | Idem | Stesso rischio di drift versioni — **mantenere** pin allineato a Django |
| `tzdata` | Rimosso su Linux con tzdata di sistema | Possibile OK in prod Linux; **rischio** su Windows/dev container senza tz di sistema |
| `psycopg` / `psycopg-binary` | Rimossi | **Deploy PostgreSQL rotto** (`DEPLOY.md`, `.env.example`) |
| `gunicorn` | Rimosso | **Deploy produzione rotto** (systemd non avvia l'app) |
| `python-decouple` | Rimosso | **`config/settings.py` non importabile** — app non parte |
| `Django` | — | **App non funzionante** (ovvio) |

---

## Proposta per TASK-009

### Raccomandazioni per dipendenza dubbia/inutilizzata

| Dipendenza | Raccomandazione | Motivazione |
|------------|-----------------|-------------|
| `django-filter` | **Rimuovere** | Zero integrazione; riduce superficie e tempo install |
| `djangorestframework` | **Rimuovere** | Zero integrazione; nessuna API REST nel progetto (template Django + HTMX opzionale) |
| `pillow` | **Rimuovere** (con verifica test) | Nessun `ImageField`; upload solo documenti. Reintrodurre solo se si aggiungono campi immagine |

**Non toccare in TASK-009:** `Django`, `python-decouple`, `gunicorn`, `psycopg`, `psycopg-binary`, `asgiref`, `sqlparse`, `tzdata` — tutte usate o pin necessari.

### Piano di rimozione sicuro (TASK-009)

Eseguire **una dipendenza alla volta**, con test completi tra uno step e l'altro:

1. **Step A — `django-filter`**
   - Rimuovere riga `django-filter==25.2` da `requirements.txt`.
   - `pip uninstall django-filter` (solo in venv locale, con autorizzazione operatore).
   - Eseguire test (sezione sotto).
   - Se PASS → commit step A.

2. **Step B — `djangorestframework`**
   - Rimuovere riga `djangorestframework==3.17.1` da `requirements.txt`.
   - `pip uninstall djangorestframework`.
   - Eseguire test.
   - Se PASS → commit step B.

3. **Step C — `pillow`**
   - Rimuovere riga `pillow==12.2.0` da `requirements.txt`.
   - `pip uninstall pillow`.
   - Eseguire test + smoke manuale upload file (documento PDF, allegato approvazione) in dev.
   - Se PASS → commit step C.

**Alternativa "integrare" (sconsigliata senza requisito prodotto):**

- Aggiungere `'rest_framework'` e/o `'django_filters'` a `INSTALLED_APPS` e implementare API/filtri — **fuori scope** attuale del Documentale (nessun requisito REST nel dominio qualità/progetto).

**Aggiornamento `scripts/test.sh`:** dopo rimozione di DRF/django-filter, lo step 0 continuerà a passare (non verifica più quei pacchetti). Nessuna modifica obbligatoria allo script.

---

## Test da eseguire prima e dopo eventuali rimozioni

### Comando esatto

```bash
source projects/documentale-workcopy/.venv/bin/activate
projects/documentale-workcopy/scripts/test.sh
```

Oppure, dalla root del progetto:

```bash
cd projects/documentale-workcopy
./scripts/test.sh
```

### Cosa verifica lo script (`scripts/test.sh`)

| Step | Controllo |
|------|-----------|
| 0/3 | Importabilità di tutte le dipendenze ancora in `requirements.txt` |
| 1/3 | `python -m compileall` su tutto il codice |
| 2/3 | `manage.py check --settings=config.test_settings` |
| 3/3 | `manage.py test --settings=config.test_settings` (SQLite `:memory:`) |

### Criteri di successo attesi

- Exit code `0`
- Messaggio finale: `Tutti i controlli completati con successo.`
- Suite Django: **1208 test OK** (conteggio post TASK-007-2, invariato da TASK-008)
- `System check identified no issues (0 silenced).`

### Verifiche aggiuntive post-rimozione (TASK-009)

- Dopo rimozione `psycopg`/`gunicorn`: **non applicare** in TASK-009 — restano necessari per deploy.
- Dopo rimozione `pillow`: confermare upload `FileField` in dev (non richiede Pillow).
- Opzionale pre-deploy: `DB_ENGINE=django.db.backends.postgresql` su ambiente di staging con migrate (fuori scope test automatici attuali).

---

## Esito verifica TASK-008 (suite invariata)

TASK-008 è **solo documentazione** — nessuna modifica a codice o `requirements.txt`. La suite Django **non dovrebbe cambiare** rispetto all'ultimo run documentato (TASK-007-2: **1208/1208 PASS**).

L'implementatore deve rieseguire `./scripts/test.sh` con venv attiva per conferma formale prima di chiudere il task in review.

---

## Esito TASK-009 (rimozione applicata, 2026-07-07)

Le 3 dipendenze raccomandate sono state rimosse con successo, **una alla
volta con test completo tra uno step e l'altro** (dettaglio in
`docs/ai/RUN_LOG.md`):

| Step | Dipendenza | Esito | Suite dopo rimozione |
|------|-----------|-------|----------------------|
| A | `django-filter` | Rimossa | 1208/1208 PASS |
| B | `djangorestframework` | Rimossa | 1208/1208 PASS |
| C | `pillow` | Rimossa (nessun dubbio reale emerso in verifica approfondita) | 1208/1208 PASS |

`requirements.txt` finale (8 pacchetti): `asgiref`, `Django`, `gunicorn`,
`psycopg`, `psycopg-binary`, `python-decouple`, `sqlparse`, `tzdata` — tutti
usati chiaramente o probabilmente usati (dipendenze runtime indirette di
Django), nessuno rimosso senza evidenza. Suite Django invariata a
1208/1208 PASS in ogni step, confermando che nessuna delle 3 dipendenze
rimosse era realmente in uso.

---

## Riferimenti

- `requirements.txt` — elenco pin (11 pacchetti)
- `config/settings.py` — `INSTALLED_APPS`, `DATABASES`, `USE_TZ`, decouple
- `DEPLOY.md` — gunicorn, PostgreSQL
- `.env.example` — `DB_ENGINE=django.db.backends.postgresql`
- `docs/ai/PROJECT_ANALYSIS.md` — problema #2 (DRF/django-filter)
- `scripts/test.sh` — mapping import per verifica dipendenze (righe 88–96)
