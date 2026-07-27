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

### Review — 2026-07-10 — TASK-022 Flusso ECN semplice per revisioni rapide

**Reviewer:** Claude Code
**Diff / branch:** task/documentale-simple-ecn-flow
**Esito:** Approvato

**Osservazioni:**

- Scope rispettato: diff confinato a `ecn/`, `documents/` (solo i file
  elencati nello scope di TASK-022), `templates/documents/`,
  `templates/ecn/`, `docs/ai/`. Nessun file fuori
  `projects/documentale-workcopy`.
- `create_new_revision`, i service CCB (`configure_ccb`,
  `submit_change_notice`, `approve_change_notice`,
  `reject_change_notice`, `close_change_notice`) e `can_create_ecn`/
  `can_view_ecn` non sono stati toccati — confermato via `git diff`
  che il flusso ECN standard non ha ricevuto modifiche funzionali.
- Nuova migrazione (`0004_changenotice_flow_type`) additiva, valore di
  default `STANDARD`: nessun impatto sui dati esistenti.
- `requires_ecn_for_revision`/`ecn_exemption` mantenuti nel
  modello/form per compatibilità, rimossi solo dal template di
  creazione documento — coerente con la decisione tecnica documentata
  in `TASKS.md`.
- Nessun secret, credenziale, comando Git distruttivo o installazione
  di pacchetti nel diff.
- Test: 718/718 (`documents ecn` mirato) e 1261/1261 (suite completa)
  verdi; `pip check` pulito; regressioni Station verdi.
- `RUN_LOG.md` e `TASKS.md` aggiornati con l'esito di TASK-022.

**Azioni richieste prima del commit:**

- Nessuna.

---

### Review — 2026-07-22 — TASK-028 Istruttoria CCB: impatto sul costruito e applicabilità

**Reviewer:** Claude Code
**Diff / branch:** task/documentale-ccb-dossier-impact-fields
**Esito:** Approvato

**Osservazioni:**

- Scope rispettato: diff confinato a `ecn/` (model, form, service, view,
  test) e ai tre template `ecn_ccb_dossier.html`, `ecn_detail.html`,
  `ecn_review_form.html` dove il dossier è già mostrato in sola lettura;
  più l'aggiornamento di `docs/ai/TASKS.md` per questo task. Nessun altro
  file toccato.
- I due nuovi campi (`ccb_constructed_impact`, `ccb_applicability`) sono
  `TextField(blank=True)`, stesso pattern e stesso livello di
  obbligatorietà (opzionali) dei campi di impatto secondari già esistenti
  — `validate_for_submit()` non modificato, `ccb_class`/`ccb_requirements`/
  `ccb_technical_impact` restano gli unici obbligatori prima dell'invio.
- Migrazione (`0005_changenotice_ccb_applicability_and_more`) puramente
  additiva, nessun default distruttivo, nessun impatto sui dati esistenti.
- Nessun secret, credenziale, comando Git distruttivo o installazione di
  pacchetti nel diff.
- Test: suite `ecn` **340/340 PASS** (comprese le 5 nuove aggiunte per
  questo task).
- `TASKS.md` e questo log aggiornati con l'esito.

**Azioni richieste prima del commit:**

- Nessuna.

---

### Review — 2026-07-22 — TASK-029 Documento: flag che blocca la richiesta di ECN semplice

**Reviewer:** Claude Code
**Diff / branch:** task/documentale-block-simple-ecn-flag
**Esito:** Approvato

**Osservazioni:**

- Scope rispettato: diff confinato a `documents/` (model, form,
  permissions, view, test), `ecn/services.py` + `ecn/views.py` (gate
  ECN semplice), `templates/documents/new_document.html` e
  `document_detail.html`, più `docs/ai/TASKS.md` per questo task.
- Permesso `can_edit_simple_ecn_flag` deliberatamente più ristretto di
  `can_edit_document_metadata`, come richiesto dall'operatore — verificato
  che un Document Manager (che pure può modificare titolo/descrizione/
  schema) non ha il campo nel form, nemmeno forzandolo via POST raw
  (il campo non è dichiarato in `Meta.fields`, quindi Django lo ignora
  in `cleaned_data`; l'assegnazione esplicita in view è dietro
  `if 'allows_simple_ecn' in form.fields`).
- Doppio gate sul percorso ECN semplice (service **e** vista, non solo
  nascondere il bottone) — coerente con lo stile difensivo già presente
  nel resto del progetto (es. `can_view_archived_document`).
- Migrazione (`0007_document_allows_simple_ecn`) additiva con
  `default=True`: nessun impatto sui documenti esistenti, nessuna
  regressione sul flusso ECN semplice già disponibile.
- Corretto un bug preesistente scoperto durante la verifica a video
  (commento Django multi-riga `{# #}` reso come testo visibile in
  `new_document.html`, introdotto in TASK-022) — fix di una riga,
  strettamente nella stessa sezione già in modifica per questo task,
  non fuori scope.
- Nessun secret, credenziale, comando Git distruttivo nel diff.
- Test: suite `documents`+`ecn` **744/744 PASS**.
- Verifica a video completa (vedi TASKS.md); dato demo mutato durante
  la verifica ripristinato al valore di default.

**Azioni richieste prima del commit:**

- Nessuna. Stessa nota di merge sequenziale su `docs/ai/TASKS.md`/
  `REVIEW_LOG.md` già segnalata per gli altri branch task di questa sessione
  (TASK-028, TASK-030): nessun conflitto sul codice applicativo.

---

### Review — 2026-07-22 — TASK-030 ECN: form voto CCB in due riquadri separati

**Reviewer:** Claude Code
**Diff / branch:** task/documentale-ecn-review-form-ui
**Esito:** Approvato

**Osservazioni:**

- Scope rispettato: unico file applicativo toccato è
  `templates/ecn/ecn_review_form.html`, più l'aggiornamento di
  `docs/ai/TASKS.md` per questo task. Nessuna modifica a form/service/
  view Python — la richiesta era di sola presentazione.
- Verificato che `ecn/forms.py:ChangeNoticeReviewForm` e
  `ecn/views.py:ecn_review` non necessitano modifiche: i due `<form>`
  separati inviano gli stessi nomi di campo (`action`, `comment`,
  `ccb_notes`) del form unico precedente — la validazione server
  (motivo obbligatorio se `action == reject`) resta quella già
  verificata in TASK-027, invariata.
- Pattern replicato 1:1 da `templates/approvals/approval_detail.html`
  (già in produzione in questo progetto per lo stesso tipo di
  decisione sulle revisioni documento): due riquadri colorati, due
  form indipendenti, asterisco + `required` HTML sul campo
  obbligatorio.
- Verificato a video: submit vuoto bloccato dal browser (nessuna
  richiesta di rete), submit con motivazione porta l'ECN a
  `REJECTED` con motivo visibile nel dettaglio.
- Nessun secret, credenziale, comando Git distruttivo nel diff.
- Test: suite `ecn` **336/336 PASS**, nessun test esistente modificato
  (comportamento server invariato).

**Azioni richieste prima del commit:**

- Nessuna.

---

### Review — 2026-07-27 — TASK-031 Servizio centrale di policy PDF

**Reviewer:** Claude Code
**Diff / branch:** task/documentale-pdf-approval-foundation
**Esito:** Approvato

**Osservazioni:**

- Primo task della feature "sorgente / PDF di rappresentazione / PDF
  approvato" (vedi `docs/ai/PDF_APPROVAL_DECISION.md` per l'analisi
  completa che motiva le soglie). Solo logica pura in questo task: nessun
  modello, nessuna vista, nessuna dipendenza nuova.
- `documents/pdf_policy.py`: un'unica funzione (`get_pdf_strategy`)
  centralizza la decisione — nessun `if` sparso sulle estensioni altrove
  nel codice. Estensioni classificate in insiemi nominati
  (`RELIABLE_EXTENSIONS`, `OFFICE_EXTENSIONS`, `RISKY_EXTENSIONS`),
  estendibili senza toccare la logica.
- La disponibilità del convertitore (`soffice`) è iniettabile
  (`converter_available`) e mai assunta dall'estensione: nei test è
  sempre mockata, mai dipendente da `shutil.which` reale — coerente col
  vincolo "i test non devono dipendere da programmi esterni sulla
  macchina di CI".
- Verificato localmente (non rappresentativo dell'ambiente reale, vedi
  decisione): `soffice`/`libreoffice` presenti su questa macchina Linux,
  ma non si può assumere lo stesso su Windows (sviluppo, da `CLAUDE.md`)
  né sul server di produzione.
- Nessun secret, nessun comando Git distruttivo nel diff.
- Test: `documents.tests_pdf_policy` **12/12 PASS**; suite `documents`
  completa **414/414 PASS** (nessuna regressione).

**Azioni richieste prima del commit:**

- Nessuna.

---

### Review — 2026-07-27 — TASK-032 Modelli/migrazioni PDF e firma visiva

**Reviewer:** Claude Code
**Diff / branch:** task/documentale-pdf-approval-foundation
**Esito:** Approvato

**Osservazioni:**

- Riuso deliberato di `DocumentFile` (nuovo campo `kind`, default
  `source`) invece di modelli file paralleli per rappresentazione/PDF
  approvato: stesso schema hash/mime/size già validato in produzione,
  nessuna duplicazione di concetti.
- Nuovi campi su `DocumentVersion` tutti nullable/con default: la
  migrazione (`0008_documentfile_kind_...`) è puramente additiva,
  `makemigrations --check --dry-run` pulito, nessuna revisione esistente
  toccata.
- Nuovo modello `accounts.UserSignature`: righe immutabili (stesso
  pattern di `DocumentFile` — sostituzione = nuova riga + `is_active`,
  mai edit in place), vincolo `UniqueConstraint` su `is_active=True` per
  utente. `accounts` era un'app scaffolding vuota (3 righe in
  `models.py`): questa è la sua prima estensione reale.
- `ApprovalDecision.signature_display_name`/`signature_used`: snapshot
  esplicito perché `approver` resta un FK live a `User` — se nome o
  firma cambiano in futuro, un PDF approvato già generato non deve
  cambiare. Popolazione automatica rimandata a TASK-036 (qui solo i
  campi dati, con test che verificano che restano vuoti finché nessuno
  li imposta).
- Reintrodotta `pillow==12.2.0` (stessa versione già presente prima
  della rimozione in TASK-009), necessaria per `ImageField` +
  validazione reale del PNG di firma. `DEPENDENCIES_AUDIT.md` aveva
  segnalato esplicitamente questo rischio al momento della rimozione
  ("rischio se in futuro si aggiungono ... campi ImageField"): non è
  una dipendenza nuova mai vista, è quel rischio che si materializza con
  un requisito reale.
- Admin aggiornato per i nuovi campi (readonly dove sono gestiti dal
  sistema, non dall'utente in admin).
- Nessun secret, nessun comando Git distruttivo nel diff.
- Test: `accounts` (nuovi) + `documents.tests_pdf_models` (nuovi) +
  `documents.tests_pdf_policy` + `approvals` (con 2 nuovi test per lo
  snapshot) eseguiti insieme: **77/77 PASS**.

**Azioni richieste prima del commit:**

- Nessuna.

---

### Review — 2026-07-27 — TASK-033 Firma visiva utente

**Reviewer:** Claude Code
**Diff / branch:** task/documentale-pdf-approval-foundation
**Esito:** Approvato

**Osservazioni:**

- `accounts/forms.py:UserSignatureUploadForm` usa `forms.ImageField`
  (verifica reale via Pillow, non solo estensione) e restringe
  esplicitamente a PNG + limite dimensioni/pixel, coerente con
  `docs/ai/PDF_APPROVAL_DECISION.md` §"firma visiva".
- Nessun URL scaricabile per la firma: la pagina di gestione mostra
  l'anteprima come **data URI** generato server-side dalla firma
  dell'utente stesso — non esiste alcuna vista `/media/...` né un
  endpoint di download da proteggere per questo primo task (il consumo
  da parte del generatore di PDF approvato in TASK-036 avviene
  internamente, mai via HTTP). Verificato con un test che asserisce
  l'assenza di `/media/` nella risposta.
- Rimozione = `is_active=False`, mai `delete()`: le righe storiche
  restano referenziabili da `ApprovalDecision.signature_used` già
  congelate (TASK-032). La sostituzione disattiva l'unica riga attiva
  precedente rispettando il vincolo di unicità del modello.
- Audit: `SIGNATURE_UPLOADED`/`SIGNATURE_REMOVED` via `create_audit_log`
  esistente, nessun contenuto binario nel log (solo nome file).
- Nuova route `firma/` (`accounts.urls`, incluse in `config/urls.py`) e
  link "La mia firma visiva" nel footer utente di `base.html`.
- Nessun secret, nessun comando Git distruttivo nel diff.
- Test: `accounts` **11/11 PASS** (nuovi: view upload valido/non-PNG/
  sovradimensionato/sostituzione/rimozione/anteprima-non-pubblica).
  Suite `documents accounts approvals ecn projects notifications`
  eseguita insieme per verificare che il link aggiunto a `base.html` non
  rompa altre pagine che estendono `base.html` (risultato riportato nel
  commit).

**Azioni richieste prima del commit:**

- Nessuna, in attesa solo della conferma della suite estesa in corso.

---
