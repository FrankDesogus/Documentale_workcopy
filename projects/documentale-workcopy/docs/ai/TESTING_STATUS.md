# Testing status — Documentale Workcopy

Stato onesto della validazione della test suite in questa copia Station.
Aggiornato: 2026-07-07 (TASK-010 — suite corrente **1208/1208 PASS**).

## Stato attuale

- Test runner reale: `scripts/test.sh`. Esegue, dalla root del progetto:
  0) verifica dipendenze `requirements.txt` importabili; 1)
  `python -m compileall`; 2) `manage.py check`; 3) `manage.py test`.
- Settings di test dedicati: `config/test_settings.py`. Nessun `.env` reale
  richiesto o letto (`SECRET_KEY` fittizia impostata via variabile
  d'ambiente prima dell'import di `config.settings`).
- Nessun database reale: i test Django usano SQLite `:memory:` (mai un
  file persistente, mai `db.sqlite3`).
- **Ambiente di test dedicato creato (TASK-003):** virtualenv locale in
  `projects/documentale-workcopy/.venv` (già ignorata da `.gitignore`,
  pattern `.venv/` preesistente — mai committata). Dipendenze installate
  con `pip install -r requirements.txt` **solo in questa venv**, mai a
  livello di sistema, nessun `sudo`. Il progetto sorgente originale non è
  stato toccato.

## Esito reale della suite Django

### TASK-003 (2026-07-05) — 1207/1207 PASS

```
Ran 1207 tests in 489.755s
OK
Tutti i controlli completati con successo.
```

Comando: `scripts/test.sh` con `.venv` attivata. 0 fallimenti, 0 errori,
0 warning. Durata: ~8 minuti e mezzo.

### TASK-004 (2026-07-06) — 1206/1207 PASS, 1 fallimento indipendente noto

```
Ran 1207 tests in 480.905s
FAILED (failures=1)
```

**Il fix di TASK-004 (SyntaxWarning) è verificato corretto e senza
regressioni.** L'unico fallimento presente
(`test_document_list_shows_approval_date`) è stato **dimostrato
indipendente** dal fix con un test di controllo A/B (stesso test isolato,
eseguito sia con il fix sia con il file originale ripristinato: fallisce
identicamente in entrambi i casi) — vedi "Problemi minori noti" per i
dettagli tecnici (bug di fuso orario pre-esistente nel test, non nel fix).
Questo fallimento è transitorio: dipende dall'orario di esecuzione
(confine di mezzanotte CEST/UTC), non da uno stato del codice.

### TASK-005 (2026-07-06) — 1207/1207 PASS (test fragile corretto)

```
Ran 1207 tests in 502.104s
OK
Tutti i controlli completati con successo.
```

Fix: in `documents/tests.py`,
`v.approved_at.strftime('%d/%m/%Y')` → `timezone.localtime(v.approved_at).strftime('%d/%m/%Y')`,
per confrontare lo stesso valore localizzato (Europe/Rome) che il template
mostra davvero, invece del datetime UTC grezzo. Solo il test modificato:
nessuna view/modello/template toccato. Test mirato isolato: PASS. Suite
completa: **1207/1207 PASS**, 0 warning, `manage.py check` pulito.

### Problemi minori noti

- ~~`documents/versioning.py:9` — `SyntaxWarning`~~ **Corretto in TASK-004**
  (2026-07-06): docstring di modulo reso raw string (`"""` → `r"""`).
  Nessuna modifica di comportamento (verificato con `ast.parse` +
  `-W error::SyntaxWarning`: nessun warning residuo; la regex già compilata
  `_RE_NUMERIC` era già corretta).
- Molti messaggi informativi "Email non inviata: utente X senza indirizzo
  email" durante i test: comportamento atteso del backend email `locmem`
  con utenti di test senza indirizzo configurato, non un errore.
- Un messaggio "Errore durante apply: Errore simulato in test atomicità.
  Nessuna modifica applicata." è l'output atteso di un test che verifica
  esplicitamente il rollback transazionale (simula un errore apposta) — non
  un fallimento.
- ~~`documents.tests.DocumentDetailApprovalTests.test_document_list_shows_approval_date`
  fragile su confine di fuso orario~~ **Corretto in TASK-005** (2026-07-06):
  vedi sopra. Trovato in TASK-004 (confrontava `v.approved_at.strftime(...)`
  UTC grezzo con il rendering del template, localizzato in Europe/Rome —
  vicino alla mezzanotte CEST/CET le due date potevano differire di un
  giorno; dimostrato indipendente dal fix di TASK-004 con test di controllo
  A/B), corretto usando `timezone.localtime()` nell'assert. Bug era solo
  nel test, mai nella logica applicativa di produzione (il template
  localizza correttamente).

### TASK-006 → TASK-009 (2026-07-06 / 2026-07-07) — 1208/1208 PASS

Un test è stato aggiunto durante TASK-007 Fase 1 (regressione gap
permessi G1/G2), portando il totale da 1207 a **1208**. Da allora il
conteggio resta stabile a 1208/1208 PASS attraverso:

- TASK-007 Fase 1 — allineamento mapping backfill/compare permessi
  cartella (+1 test).
- TASK-007-2 — backfill esteso a tutti i permission code (2 test
  rinominati/aggiornati, nessuna variazione di conteggio).
- TASK-008 — audit dipendenze `requirements.txt` (solo documentazione,
  nessuna variazione).
- TASK-009 — rimozione `django-filter`, `djangorestframework`, `pillow`
  da `requirements.txt` (una alla volta, test completo dopo ogni step:
  1208/1208 PASS in ognuno, confermando che nessuna era realmente usata).

Dettaglio completo di ogni esecuzione in `docs/ai/RUN_LOG.md`.

## Cosa è stato validato

- Sintassi bash dello script (`bash -n`), `shellcheck`/`shfmt` puliti,
  `py_compile` su `config/test_settings.py`.
- Comportamento fail-fast quando mancavano le dipendenze (validato prima di
  TASK-003: `exit 1` con elenco chiaro, nessun falso successo).
- **La suite Django reale del Documentale importato: 1207/1207 test PASS
  (confermato più volte, ultima conferma TASK-005, 2026-07-06),
  `manage.py check` pulito, in un ambiente con le dipendenze reali
  installate in una venv dedicata e isolata.**
- Integrazione con gli helper Station (`station-project-readiness.sh`,
  `station-next-task.sh`, `station-status.sh`) e regressioni sugli altri
  progetti pilota.

## Cosa NON è ancora coperto

- La venv `.venv` è locale a questa sessione/macchina: non è committata
  (corretto, per design) e va ricreata da chi clona/riprende il lavoro
  (`python3 -m venv .venv && .venv/bin/pip install -r requirements.txt`).
  I cicli `ai-cycle.sh --run` futuri su questo progetto **non attivano
  automaticamente questa venv**: l'operatore deve farlo a mano, o
  `scripts/test.sh` fallirà di nuovo con "dipendenze mancanti" se lanciato
  con l'interprete di sistema.
- Compatibilità con PostgreSQL (target di produzione) non verificata: i
  test usano SQLite `:memory:` per design (nessun DB reale), non è stata
  fatta alcuna verifica specifica su PostgreSQL.

### TASK-012 (2026-07-08) — isolamento upload di test da `media/` reale

**Bug scoperto durante TASK-011** (audit deployment readiness): `config/
test_settings.py` non sovrascriveva `MEDIA_ROOT`, quindi ogni test che
carica un file (`FileField`) scriveva realmente in
`projects/documentale-workcopy/media/` — la stessa cartella usata in
sviluppo/produzione. Effetto osservato: **521 file accumulati** in
`media/` da run ripetuti della suite nel corso delle sessioni precedenti
(confermato dal pattern di naming Django `nomefile_XXXXXXX.ext`, generato
quando un file con lo stesso nome esiste già).

**Verificato che non fossero dati reali** prima di qualunque bonifica:
tutti i 521 file risultavano non tracciati e ignorati da git
(`git ls-files` vuoto su `media/`, `git status --ignored` conferma
l'intera cartella ignorata); nessun contenuto è stato aperto. Bonificati
con `git ls-files --others --ignored --exclude-standard` +
rimozione mirata (mai `git clean`), preservando solo la nota di sicurezza
`.gitkeep-note.txt` già presente nella cartella.

**Fix:** `config/test_settings.py` ora imposta
`MEDIA_ROOT = BASE_DIR / '.test-media'` (cartella isolata, in
`.gitignore`). `scripts/test.sh` pulisce `.test-media/` prima di ogni
run e di nuovo dopo un run riuscito (mai la `media/` reale). Verificato:
suite completa 1208/1208 PASS con `media/` reale **invariata** (0 nuovi
file) e `.test-media/` correttamente rimossa a fine run.

## Interpretazione corretta di "test PASS" per questo progetto

Da questo momento, un "TESTS: PASS" riportato da una review su
`documentale-workcopy` **può** riferirsi a una suite Django reale verde,
**se e solo se** l'esecuzione è avvenuta con la venv `.venv` (o equivalente
con le dipendenze installate) attiva. Se `scripts/test.sh` viene eseguito
con l'interprete di sistema (senza dipendenze), fallirà di nuovo con
"dipendenze mancanti" — quel fallimento resta corretto e atteso, e va
distinto esplicitamente da un vero fallimento della suite applicativa.

## Prossimo passo

Nessun problema noto residuo nella suite. Migrazione permessi cartella
(Fase 1/2), pulizia dipendenze e allineamento documentazione completati
(TASK-007→010). Procedere con il backlog corrente in `docs/ai/TASKS.md`
(prossimo: TASK-011 o come indicato da `station-next-task.sh`).
