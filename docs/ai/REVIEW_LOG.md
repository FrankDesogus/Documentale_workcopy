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
