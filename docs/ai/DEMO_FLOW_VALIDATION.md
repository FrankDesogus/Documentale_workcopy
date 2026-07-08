# Validazione flusso DEMO end-to-end (TASK-017)

**Data:** 2026-07-08/09
**Progetto:** `projects/documentale-workcopy`
**Scope:** validazione funzionale in ambiente demo isolato — **nessun
dato reale, nessun `.env` reale, nessuna rete, nessun server esposto**.

---

## 1. Scopo della validazione

Verificare che un **singolo account admin/superuser** possa attraversare
il flusso completo del Documentale (progetto, documento, revisione,
approvazione, ECN, audit) senza bisogno di più utenti/ruoli, per capire
se la demo è presentabile così com'è.

**Esito sintetico: sì.** Un solo superuser (senza gruppi né membership
cartella) crea, invia in approvazione, approva, e attraversa i permessi
ECN — tutto verificato con azioni reali sul database demo, non solo
letto dal codice.

---

## 2. Ambiente demo usato

- Database SQLite **isolato su file**: `.demo/db.sqlite3` (mai
  `:memory:`, perché la demo deve persistere tra comandi separati).
- Media **isolata**: `.demo-media/` (mai la `media/` reale).
- Nessun `.env` reale coinvolto: `SECRET_KEY`/`DEBUG`/`ALLOWED_HOSTS`
  impostati via variabili d'ambiente prima dell'import di
  `config.settings`, stesso pattern di `config/test_settings.py`.
- Server, quando avviato, **solo** su `127.0.0.1:8765` (porta locale
  non standard per evitare conflitti), mai `0.0.0.0`, fermato subito
  dopo la verifica.

---

## 3. File/settings demo creati

- `config/demo_settings.py` (nuovo) — eredita `config.settings`,
  sovrascrive `DATABASES` (SQLite file in `.demo/`) e `MEDIA_ROOT`
  (`.demo-media/`).
- `.gitignore` — aggiunte le voci `.demo/` e `.demo-media/`.
- **Nessuna modifica** a `config/settings.py`, `config/test_settings.py`,
  codice applicativo, `can_view_ecn`, modelli, migrazioni.

Comandi demo **già esistenti** riusati senza modifiche (scoperti in
fase di analisi, non serviva costruire nulla da zero):

- `documents/management/commands/demo_company.py` — crea utenti,
  gruppi, cartelle, 4 documenti base.
- `documents/management/commands/demo_full.py` — chiama `demo_company`
  e aggiunge tutti gli scenari estesi (multi-revisione, rifiuto, ECN in
  tutti gli stati, ECN-esente, policy approvazione, sanatoria).

---

## 4. Credenziali demo locali

| Username | Password | Ruolo | Note |
|----------|----------|-------|------|
| `supervisor_demo` | `demo1234` | superuser, is_staff | Creato da `demo_company`/`demo_full`, **progettato esplicitamente** per presentazioni a singolo accesso (docstring del comando); con `DOCUMENTALE_DEMO_MODE=true` può anche selezionare sé stesso come approvatore/membro CCB via UI |
| `admin_demo` | `admin1234` | superuser, is_staff | Creato da `demo_company`, pensato per Django Admin |
| `demo_admin` | `demo_admin_change_me` | superuser, is_staff | **Creato in questo task** su richiesta esplicita, con credenziali fornite dall'operatore (email `demo_admin@example.local`). Superuser "puro", nessun gruppo, nessuna membership cartella |
| `mario.rossi`, `lucia.bianchi`, `giorgio.verdi`, `anna.neri`, `marco.esposito` | `demo1234` | utenti di reparto | Creati da `demo_company` per scenari multiutente (non necessari per il flusso a singolo account) |

**Tutte queste credenziali esistono solo nel DB demo isolato
(`.demo/db.sqlite3`), mai in un ambiente reale.**

---

## 5. Comandi per preparare la demo

```bash
cd projects/documentale-workcopy
source .venv/bin/activate

# 1. Migrazioni sul DB demo isolato (crea .demo/db.sqlite3)
python manage.py migrate --settings=config.demo_settings

# 2. Dataset demo completo (tutti gli scenari)
python manage.py demo_full --reset --no-email --settings=config.demo_settings

# 3. (Opzionale) creare/aggiornare demo_admin con credenziali esplicite
python manage.py shell --settings=config.demo_settings -c "
from django.contrib.auth.models import User
u, _ = User.objects.get_or_create(username='demo_admin', defaults={
    'email': 'demo_admin@example.local', 'is_superuser': True, 'is_staff': True,
})
u.set_password('demo_admin_change_me')
u.is_superuser = True
u.is_staff = True
u.save()
"
```

## 6. Comandi per avviare la demo

```bash
source .venv/bin/activate
python manage.py runserver 127.0.0.1:8765 --settings=config.demo_settings
```

Login su `http://127.0.0.1:8765/accounts/login/` con una delle
credenziali sopra. **Mai esporre su `0.0.0.0` o su rete condivisa.**

---

## 7. URL principali da provare

Verificati con `curl` (loopback, sessione autenticata come
`demo_admin`) durante questa validazione:

| URL | Esito |
|-----|-------|
| `/accounts/login/` | HTTP 200 (non autenticato) |
| `/` (dashboard) | HTTP 302 → login (non autenticato); HTTP 200 dopo login |
| `/documents/` | HTTP 200 (dopo login) |
| `/projects/` | HTTP 200 (dopo login) |
| `/ecn/` | HTTP 200 (dopo login) |
| `/static/css/tailwind.css` | HTTP 200 (file statico servito correttamente) |

Nessun errore 500 riscontrato su nessuna delle pagine principali.

---

## 8. Flusso progetto — verificato

**Sì, verificato con azione reale.** `demo_admin` (nessun gruppo, nessuna
membership) ha:

1. Verificato `can_manage_folder` sulla root folder di `PRJ-DEMO-001` →
   `True` (bypass superuser).
2. Creato uno snapshot `ProjectRevision` (`create_project_revision`).
3. Popolato lo snapshot con i documenti correnti del progetto
   (`populate_project_revision_from_current_documents` → 2 documenti
   congelati).
4. Emesso lo snapshot (`issue_project_revision` → stato `issued`,
   `is_current=True`).

**Nota importante sul dataset `demo_full`:** il comando esistente crea
2 progetti (`PRJ-DEMO-001`, `PRJ-DEMO-ALPHA`) ma **zero** `ProjectRevision`
— la funzionalità di snapshot progetto (VH-1→VH-4) non viene esercitata
da `demo_full`. Questo non è un bug: è semplicemente uno scenario che il
comando demo esistente non copre. Colmato in questa validazione con
un'azione diretta, a dimostrazione che la funzionalità è disponibile e
funzionante — ma per una demo "pronta all'uso" servirebbe un piccolo
scenario aggiuntivo in `demo_full` (vedi §19).

---

## 9. Progetti revisionabili: sì/no — CHIARIMENTO

**Sì, ma con un meccanismo diverso dai documenti**, da non confondere:

- **Documenti**: ciclo `DRAFT → IN_APPROVAL → APPROVED/REJECTED`, con
  `DocumentVersion` come revisione vera e propria soggetta ad
  approvazione.
- **Progetti**: `Project.version`/`Project.revision` sono **campi
  manuali** (asse versione e asse revisione indipendenti); `ProjectRevision`
  è uno **snapshot immutabile** (tipo `version` o `revision`) creato con
  `create_project_revision` → popolato con
  `populate_project_revision_from_current_documents` → emesso con
  `issue_project_revision`. Non c'è un ciclo di approvazione dedicato
  per lo snapshot di progetto: una volta `issued`, diventa immutabile
  (`_IMMUTABLE_STATUSES`).

In demo: mostrare "Storico progetto" nel `project_detail` per vedere
versioni/revisioni salvate, distinto dallo storico documenti.

---

## 10. Flusso documento — verificato

**Sì, verificato con azione reale** (non solo dal dataset `demo_full`,
che già ne contiene 13 in vari stati):

1. `demo_admin` verifica `can_view_folder`/`can_create_document_in_folder`
   su `QUA-PROC` → `True` (bypass superuser).
2. Crea `Document` (`TASK017-DEMO-ADMIN-DOC`), associato alla cartella.
3. Crea `DocumentVersion` "00" (stato `draft`).

---

## 11. Flusso revisione — verificato

**Sì.** La versione creata al punto precedente parte da `draft`. Il
dataset `demo_full` dimostra anche `DEMO-MULTI-001` (3 revisioni,
storico completo con `superseded`) e `DEMO-REJECT-001` (revisione
rifiutata).

---

## 12. Flusso approvazione/firma — verificato

**Sì, verificato con azione reale.** `demo_admin`:

1. Invia la propria versione in approvazione
   (`submit_version_for_approval`), assegnando **sé stesso** come
   approvatore.
2. Approva (`approve_version`) — possibile perché
   `approvals/services.py` fa bypass esplicito per `is_superuser` anche
   se l'utente non è tra gli approvatori assegnati (righe 57, 81, 160,
   232).
3. Risultato: `DocumentVersion.status = 'approved'`, `is_current=True`,
   `Document.current_version` aggiornato.

Non esiste firma digitale nel progetto (per design, vedi `CLAUDE.md`) —
l'approvazione è l'equivalente funzionale.

---

## 13. Flusso ECN — verificato

**Sì**, in due modi:

1. **Dataset esistente**: `demo_full` crea 8 `ChangeNotice` che coprono
   **tutti e 6 gli stati** (`draft`, `ccb_preparation`, `under_review`,
   `approved`, `rejected`, `closed`), incluso un caso di ECN che ha
   originato una revisione (`DEMO-ECN-EXEC`).
2. **Permessi verificati per `demo_admin`**: `can_create_ecn(demo_admin,
   documento) → True`, `can_view_ecn(demo_admin, ecn_esistente) → True`
   (entrambi via bypass superuser). Non è stata creata una nuova ECN da
   zero in questa validazione (il dataset già copre tutti gli stati
   possibili) — i permessi confermano che `demo_admin` potrebbe farlo.

`can_view_ecn` **non è stata toccata** in questo task (fuori scope per
istruzione esplicita).

---

## 14. Revisione senza ECN — verificata

**Sì.** `DEMO-NOSCOPE-001` (creato da `demo_full`) è un documento con
`requires_ecn_for_revision=False`: 2 revisioni approvate **senza**
passare da un'ECN. Anche il documento creato da `demo_admin` in questa
validazione usa `requires_ecn_for_revision=False` +
`_bypass_ecn_check=True`, confermando che il gate ECN è correttamente
bypassabile per singolo documento.

---

## 15. Audit log — verificato

**Sì.** Il dataset `demo_full` genera **86 voci** `AuditLog`. Le azioni
di `demo_admin` in questa validazione ne hanno aggiunte **5**:
`REVISION_CREATED`, `SUBMITTED_FOR_APPROVAL`, `APPROVED` (documento),
`create_project_revision`, `issue_project_revision` — tutte con
timestamp, utente e oggetto corretti, consultabili via query diretta
(`AuditLog.objects.filter(user=demo_admin)`) o via Django Admin.

---

## 16. Cosa funziona oggi con un singolo superuser

- Visualizzare qualunque cartella/progetto/documento/ECN (bypass
  superuser diffuso e coerente).
- Creare documenti in qualunque cartella.
- Creare revisioni, inviarle in approvazione assegnando sé stesso,
  approvarle.
- Creare/emettere snapshot di progetto (versione o revisione).
- Verificare (permessi) la creazione/visibilità ECN — il dataset demo
  già mostra ECN in tutti gli stati.
- Vedere l'audit trail delle proprie azioni.
- **Nessuna azione del flusso richiesto ha richiesto un secondo
  account.**

---

## 17. Cosa non è ancora coperto / gap

- `demo_full` non crea `ProjectRevision` di esempio (§8) — colmabile con
  un piccolo scenario aggiuntivo, non bloccante (dimostrato funzionante
  manualmente).
- Le deroghe "sanatoria" (selezione di sé stesso come approvatore/CCB
  via UI) richiedono `DOCUMENTALE_DEMO_MODE=true` **e** username esatto
  `supervisor_demo` — **non** funzionano per `demo_admin` con
  quell'username diverso, a meno di impostare anche
  `DOCUMENTALE_DEMO_SUPERVISOR_USERNAME=demo_admin`. Non bloccante per
  il flusso richiesto (che non passa da sanatoria), ma va tenuto
  presente se si vuole mostrare anche quella funzionalità con
  `demo_admin`.
- Compatibilità PostgreSQL non toccata da questa validazione (SQLite
  isolato per design, coerente con `docs/ai/DEPLOY_REHEARSAL_PLAN.md`).

---

## 18. Bug bloccanti per la demo

**Nessuno riscontrato.** Tutte le pagine principali rispondono 200 (o
302 atteso per redirect login), nessun errore 500, nessuna eccezione
nelle azioni dirette sul modello.

---

## 19. Modifiche minime consigliate per rendere la demo più fluida

1. Aggiungere a `demo_full.py` uno scenario minimo che crei almeno una
   `ProjectRevision` (versione e/o revisione) per uno dei progetti
   demo, così la UI "Storico progetto" non risulta vuota out-of-the-box.
2. Documentare in `README.md`/`PROJECT_HANDOFF.md` (breve sezione,
   facoltativa) il comando `python manage.py demo_full --reset
   --no-email --settings=config.demo_settings` come modo consigliato
   per una demo locale isolata, rimandando a questo file per i dettagli.
3. Se si vuole mostrare la sanatoria con `demo_admin` invece di
   `supervisor_demo`: impostare
   `DOCUMENTALE_DEMO_SUPERVISOR_USERNAME=demo_admin` nell'ambiente
   della demo (non necessario per il flusso base richiesto).

Nessuna di queste è bloccante: sono rifiniture, non correzioni.

---

## 20. Prossimo task consigliato

Nessun task tecnico bloccante per la demo. Se si vuole procedere:

- Task facoltativo (basso rischio): estendere `demo_full` con lo
  scenario `ProjectRevision` mancante (§19, punto 1).
- Altrimenti: la demo è presentabile così com'è con `demo_full` +
  `demo_admin`/`supervisor_demo`, nessuna azione Station aggiuntiva
  necessaria prima di una presentazione.

---

## Riferimenti

- `documents/management/commands/demo_full.py`,
  `documents/management/commands/demo_company.py` — infrastruttura demo
  esistente riusata.
- `config/demo_settings.py` — isolamento DB/media per questa validazione.
- `docs/ai/DEPLOY_REHEARSAL_PLAN.md` — piano deploy separato (TASK-016),
  non sovrapposto: quel piano riguarda un deploy di produzione, questo
  file riguarda la demo funzionale.
- `docs/ai/PERMISSIONS_AUDIT.md`, `docs/ai/ECN_PERMISSIONS_AUDIT.md` —
  stato permessi cartella/ECN, non toccato da questo task.
