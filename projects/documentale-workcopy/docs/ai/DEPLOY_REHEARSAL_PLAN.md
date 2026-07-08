# Piano prova deploy controllata — Documentale (TASK-016)

**Data:** 2026-07-08
**Progetto:** `projects/documentale-workcopy`
**Scope:** solo pianificazione — questo documento **prepara** una prova
di deploy, **non la esegue**. Nessun comando di questo piano è stato
eseguito su sistemi reali durante la stesura.

**Riferimenti:** `docs/ai/DEPLOYMENT_READINESS.md` (audit deploy
TASK-011), `DEPLOY.md` (procedura produzione originale),
`docs/ai/TESTING_STATUS.md`, `docs/ai/PERMISSIONS_AUDIT.md`.

---

## 1. Scopo della prova

Verificare che il Documentale si installi e avvii correttamente da zero
(clone → dipendenze → migrate → gruppi → superuser → static → avvio),
in un ambiente **isolato e usa-e-getta**, per validare la procedura
documentata in `DEPLOY.md` prima di un eventuale deploy aziendale reale.
Non è un deploy di produzione: è una prova a perdere.

---

## 2. Cosa NON viene fatto

- **Nessun deploy sul server aziendale reale.**
- **Nessun database di produzione toccato.**
- **Nessuna migrazione su dati reali.**
- **Nessun `.env` reale** (con credenziali/hostname aziendali) usato o
  creato da un agente AI.
- **Nessun server esposto in rete** (solo `runserver`/gunicorn locale,
  se mai eseguito, sempre su interfaccia loopback).
- **Nessuna modifica al progetto sorgente originale**
  (`/home/frank/Documenti/Per Lavoro/Documentale/Documentale`).
- **Nessuna modifica a `projects/documentale-workcopy`** oltre a questo
  piano e alla documentazione: la prova va condotta in una copia/VM
  separata, non nella workcopy Station.
- **Nessuna esecuzione automatica di questo piano da parte di un
  agente AI**: ogni step con effetti persistenti richiede che sia
  l'operatore umano a lanciarlo.

---

## 3. Ambiente consigliato

- **VM isolata o container usa-e-getta** (non la macchina Station, non
  la workcopy `projects/documentale-workcopy`).
- **Database vuoto e dedicato** — PostgreSQL locale creato apposta per
  la prova, oppure SQLite di sviluppo (accettabile solo per la prova
  locale rapida, non rappresentativo del target produzione).
- **`media/` vuota** — mai copiare la `media/` reale (per design, non
  esiste comunque nulla di reale in questa workcopy: vedi TASK-012,
  `.gitkeep-note.txt`).
- **`.env` di test creato manualmente dall'operatore**, con valori
  fittizi (`SECRET_KEY` generata al momento, `DB_PASSWORD` di prova,
  `ALLOWED_HOSTS=127.0.0.1,localhost`). **Un agente AI non deve mai
  creare né leggere questo file.**
- Clone del codice: usare l'export/copia della workcopy (o del repo
  Station), **mai** il sorgente originale in
  `~/Documenti/Per Lavoro/Documentale/Documentale`.

---

## 4. Prerequisiti

- Python 3.12+ (coerente con `DEPLOY.md`).
- PostgreSQL disponibile (locale, container, o VM) se si vuole
  rappresentare fedelmente il target di produzione; SQLite sufficiente
  per una prova minima.
- `git` per clonare/copiare il codice nell'ambiente isolato.
- Accesso di rete **non necessario** per i passaggi core (nessun
  pacchetto va scaricato oltre `pip install -r requirements.txt`, già
  verificato coerente in TASK-008/009: 8 pacchetti, nessuno inutilizzato).
- Nessun accesso alla rete aziendale/email reale richiesto per la prova
  (`EMAIL_BACKEND` può restare `locmem` o `console` in `.env` di prova).

---

## 5. Checklist pre-flight

- [ ] Ambiente isolato pronto (VM/container), non la macchina Station.
- [ ] Copia del codice ottenuta senza toccare il sorgente originale né
      la workcopy Station in scrittura.
- [ ] Nessuna rete aziendale coinvolta nell'ambiente di prova.
- [ ] Operatore umano pronto a creare manualmente `.env` di prova (non
      delegato a un agente AI).
- [ ] DB di prova vuoto e dedicato disponibile (Postgres o SQLite).
- [ ] Consapevolezza che tutto l'ambiente sarà distrutto a fine prova
      (§18).

---

## 6. Procedura dry-run locale (senza VM, sola verifica statica)

Eseguibile anche nella workcopy Station, perché **non scrive nulla di
persistente** (stessa categoria di check già eseguiti in TASK-011):

```bash
cd projects/documentale-workcopy
source .venv/bin/activate
python manage.py check --settings=config.test_settings
python manage.py check --deploy --settings=config.test_settings
python manage.py help setup_document_groups
```

Atteso: `check` pulito; `check --deploy` con warning attesi in ambiente
di test (DEBUG=True, SECRET_KEY corta, nessun SSL — **non sono bug**,
spariscono con un `.env` di produzione reale correttamente compilato).

---

## 7. Procedura VM isolata (passi con effetti reali — solo operatore umano)

Da eseguire **fuori** dalla workcopy Station, in un ambiente a perdere:

```bash
# 1. Copia codice (mai il sorgente originale, mai in scrittura sulla workcopy Station)
git clone <copia-locale-o-repo> /tmp/documentale-rehearsal
cd /tmp/documentale-rehearsal/projects/documentale-workcopy   # o percorso equivalente

# 2. Venv dedicata alla prova (mai quella della Station)
python3 -m venv .venv-rehearsal
source .venv-rehearsal/bin/activate
pip install -r requirements.txt

# 3. .env di prova — CREATO A MANO dall'operatore, valori fittizi
cp .env.example .env
# editare .env: SECRET_KEY generata, DEBUG=True (solo per la prova),
# DB_ENGINE=sqlite3 (prova minima) o postgresql (prova rappresentativa)

# 4. Migrazioni su DB di prova vuoto
python manage.py migrate

# 5. Gruppi applicativi (comando idempotente, corretto in TASK-011)
python manage.py setup_document_groups

# 6. Superuser di prova
python manage.py createsuperuser

# 7. Static files
python manage.py collectstatic --noinput

# 8. Avvio locale (mai esposto in rete)
python manage.py runserver 127.0.0.1:8000
```

---

## 8. Comandi da eseguire manualmente (mai delegati a un agente AI)

- Creazione/edit di `.env` (contiene segreti anche se di prova).
- `createsuperuser` (richiede password interattiva).
- Qualunque comando con `sudo` (setup PostgreSQL/nginx/systemd da
  `DEPLOY.md`).
- Distruzione finale dell'ambiente di prova (§18).
- Decisione se e quando promuovere la prova a deploy aziendale reale.

---

## 9. Comandi che un agente AI NON deve eseguire autonomamente

- `python manage.py migrate` su qualunque DB non effimero/di test.
- `python manage.py collectstatic` (scrive potenzialmente centinaia di
  file — già evitato in TASK-011).
- `python manage.py runserver` o avvio di gunicorn/nginx.
- Qualunque comando `apt`, `systemctl`, `certbot`, `psql` reale.
- Creazione o lettura di `.env`.
- `git push`, merge del branch di rehearsal su `main`, deploy reale.

---

## 10. Verifiche dopo installazione

- `python manage.py check --deploy` con l'`.env` di prova reale → i 6
  warning visti in dry-run (§6) dovrebbero ridursi se `.env` di prova
  imposta `DEBUG=False`/`SECRET_KEY` lunga (anche in prova, per
  esercitare il check realisticamente).
- Login con il superuser di prova su `http://127.0.0.1:8000/`.
- Verifica che i gruppi creati da `setup_document_groups` corrispondano
  ai 10 attesi (vedi `docs/ai/DEPLOYMENT_READINESS.md` §3).
- Verifica che i file statici (incluso `tailwind.css`, già committato)
  vengano serviti correttamente in dev (`DEBUG=True`) o da
  `staticfiles/` con `DEBUG=False`.

---

## 11. Bootstrap gruppi/permessi

Usare **solo** `python manage.py setup_document_groups` (comando
idempotente, corretto in `DEPLOY.md` durante TASK-011 — non più lo
snippet manuale). Crea i 10 gruppi con nomi esatti dalle costanti
`GROUP_*` di `documents/permissions.py`/`ecn/permissions.py`. Non
assegnare utenti ai gruppi con nomi scritti a mano: usare l'admin
Django o script che referenzino le costanti, mai stringhe letterali.

**Nota permessi cartella (TASK-013/014):** una prova di deploy non
richiede né tocca `ProjectFolderMembership`/`FolderPermissionGrant` —
sono dati applicativi, non bootstrap iniziale. `can_view_ecn` resta
sul path legacy per design (vedi `docs/ai/PERMISSIONS_AUDIT.md`); non
è un blocco per la rehearsal.

---

## 12. Static files / Tailwind

`static/css/tailwind.css` è **già committato** (58 KB, verificato in
TASK-011) — **Node.js non è necessario** per la prova. Se si vuole
comunque verificare la build frontend: `npm install && npm run build`
in un ambiente con Node, mai necessario per il solo avvio Django.
`collectstatic` va eseguito solo in ambiente di prova isolato, mai
nella workcopy Station (scriverebbe `staticfiles/` lì).

---

## 13. Database/migrazioni

**Solo su DB vuoto isolato**, mai su un DB con dati reali:

- Prova minima: SQLite locale nell'ambiente di rehearsal (`DB_ENGINE`
  di default in `config/settings.py`).
- Prova rappresentativa: PostgreSQL locale/container dedicato, mai
  condiviso con altri progetti.
- `python manage.py migrate` crea lo schema da zero — se fallisce,
  **non tentare fix improvvisati sul DB**: distruggere il DB di prova e
  ripartire da `migrate` pulito (è un DB usa-e-getta, nessun dato da
  preservare).

---

## 14. Media e privacy

`MEDIA_ROOT` in produzione punta a `media/` (cartella reale). Nella
prova:

- Partire con `media/` **vuota**.
- **Non copiare mai** la `media/` reale di produzione in un ambiente di
  prova (stesso principio guardrail di TASK-012: mai dati reali in un
  ambiente non controllato).
- Se si vuole popolare dati di esempio, usare i comandi demo del
  progetto (`demo_company`, `demo_workflow`, `demo_full` — mai in
  produzione, solo in ambienti di prova/demo).

---

## 15. Account demo/test

- `createsuperuser` con credenziali **di prova**, mai riusate altrove.
- Eventualmente `python manage.py demo_full --reset --no-email` per
  popolare scenari completi (documenti, ECN, approvazioni) — solo in
  ambiente di prova, mai in produzione (comando esplicitamente
  documentato come demo-only in `PROJECT_HANDOFF.md`).
- Nessuna credenziale aziendale reale deve mai comparire nell'ambiente
  di prova.

---

## 16. Criteri di successo

- [ ] `pip install -r requirements.txt` completa senza errori.
- [ ] `python manage.py migrate` completa senza errori su DB vuoto.
- [ ] `python manage.py setup_document_groups` crea i 10 gruppi attesi.
- [ ] `python manage.py createsuperuser` e login funzionano.
- [ ] `python manage.py collectstatic` completa senza errori.
- [ ] L'applicazione risponde su `runserver` locale (o gunicorn locale)
      e le pagine principali (login, dashboard, lista documenti)
      caricano senza errori 500.
- [ ] `python manage.py check --deploy` con `.env` di prova realistico
      non mostra warning critici inattesi rispetto a quelli noti (§6).

---

## 17. Criteri di stop

Fermarsi e non promuovere la prova a deploy reale se:

- `migrate` fallisce con errori non banali (possibile incompatibilità
  PostgreSQL mai verificata prima, rischio R1 di
  `docs/ai/DEPLOYMENT_READINESS.md` §7).
- Qualunque step richiederebbe un'azione irreversibile su un sistema
  condiviso o su dati reali.
- Emergono errori che richiedono modifiche al codice applicativo (in
  quel caso: tornare alla Station, aprire un task dedicato con spec e
  test, **non** patchare a mano nell'ambiente di prova).
- Serve leggere o inserire un segreto reale per proseguire.

---

## 18. Rollback / cleanup

- Distruggere interamente l'ambiente di prova (VM/container, venv
  dedicata, DB di prova, `.env` di prova) a fine esercizio — usa-e-getta
  per design, nulla da preservare.
- Nessun rollback necessario sulla workcopy Station: la prova non la
  tocca mai in scrittura.
- Se la prova ha usato un container/VM, eliminarlo esplicitamente
  (non lasciare risorse orfane).

---

## 19. Rischi residui

| Rischio | Da `DEPLOYMENT_READINESS.md` | Stato dopo questa rehearsal |
|---------|------------------------------|------------------------------|
| Compatibilità PostgreSQL mai verificata | R1 | Verificabile con questa prova se si sceglie Postgres (§13) |
| Procedura mai eseguita end-to-end | R4 | Obiettivo primario di questa rehearsal |
| Relay SMTP aziendale non verificabile da rete esterna | R2 | Resta non verificabile fuori dalla rete aziendale — accettare `EMAIL_BACKEND=console` in prova |
| `media/` con permessi `www-data` (produzione) | — | Non applicabile a una prova locale (nessun www-data se non si usa nginx) |

---

## 20. Prossimo task suggerito dopo la rehearsal

- Se la rehearsal ha successo su SQLite ma non è stata provata su
  PostgreSQL: ripeterla con `DB_ENGINE=postgresql` per chiudere il
  rischio R1.
- Se emergono problemi applicativi durante la prova: aprire un task
  dedicato nella Station con spec precisa (stesso pattern usato per
  TASK-004/005/014), mai fix improvvisati nell'ambiente di prova.
- Se la rehearsal ha successo pieno: la decisione di procedere a un
  deploy aziendale reale resta **esclusivamente dell'operatore umano**
  — nessun agente AI deve avviarlo autonomamente.

---

## Riferimenti

- `docs/ai/DEPLOYMENT_READINESS.md` — audit deploy readiness (TASK-011),
  stack, comandi verificati, `.env.example` coerente.
- `DEPLOY.md` — procedura produzione completa (PostgreSQL, gunicorn,
  nginx, SSL, systemd).
- `docs/ai/TESTING_STATUS.md` — stato suite test e isolamento
  `media`/`.test-media` (TASK-012).
- `docs/ai/PERMISSIONS_AUDIT.md` — stato migrazione permessi cartella
  (TASK-007/013/014), non bloccante per il deploy.
