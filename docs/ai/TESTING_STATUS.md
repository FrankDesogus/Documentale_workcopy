# Testing status — Documentale Workcopy

Stato onesto della validazione della test suite in questa copia Station.
Aggiornato: 2026-07-06 (TASK-004 — fix warning + scoperta test fragile).

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
- **Nuovo, trovato in TASK-004, NON corretto (fuori scope):**
  `documents.tests.DocumentDetailApprovalTests.test_document_list_shows_approval_date`
  è **fragile su confine di fuso orario**. Confronta
  `v.approved_at.strftime('%d/%m/%Y')` (datetime UTC, non convertito) con
  il rendering del template (localizzato in `Europe/Rome` via `USE_TZ` +
  `TIME_ZONE`). Vicino alla mezzanotte CEST/CET le due date possono
  differire di un giorno (osservato: run alle 22:09 UTC / 00:09 CEST,
  atteso "05/07/2026", trovato "06/07/2026" in pagina). **Dimostrato
  indipendente da qualunque modifica di questo task**: lo stesso test
  isolato fallisce identicamente anche con `documents/versioning.py`
  ripristinato alla versione originale (test di controllo A/B eseguito
  esplicitamente). Bug pre-esistente nel test suite del Documentale, non
  nella logica applicativa di produzione (il template localizza
  correttamente; è l'assert del test a non farlo). Non corretto qui:
  richiederebbe modificare `documents/tests.py`, fuori scope di TASK-004.
  Candidato per un piccolo task dedicato futuro (es. usare
  `django.utils.timezone.localtime()` nell'assert).

## Cosa è stato validato

- Sintassi bash dello script (`bash -n`), `shellcheck`/`shfmt` puliti,
  `py_compile` su `config/test_settings.py`.
- Comportamento fail-fast quando mancavano le dipendenze (validato prima di
  TASK-003: `exit 1` con elenco chiaro, nessun falso successo).
- **La suite Django reale del Documentale importato: 1207/1207 test PASS,
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
- Il test fragile su fuso orario (`test_document_list_shows_approval_date`)
  resta da correggere in un task dedicato (vedi "Problemi minori noti").

## Interpretazione corretta di "test PASS" per questo progetto

Da questo momento, un "TESTS: PASS" riportato da una review su
`documentale-workcopy` **può** riferirsi a una suite Django reale verde,
**se e solo se** l'esecuzione è avvenuta con la venv `.venv` (o equivalente
con le dipendenze installate) attiva. Se `scripts/test.sh` viene eseguito
con l'interprete di sistema (senza dipendenze), fallirà di nuovo con
"dipendenze mancanti" — quel fallimento resta corretto e atteso, e va
distinto esplicitamente da un vero fallimento della suite applicativa.

## Prossimo passo

- Task piccolo, facoltativo: correggere il test fragile su fuso orario in
  `documents/tests.py` (`test_document_list_shows_approval_date`), usando
  `django.utils.timezone.localtime()` nell'assert invece di `strftime`
  diretto su un datetime UTC.
- Procedere con i task della roadmap in `docs/ai/PROJECT_ANALYSIS.md`
  (es. migrazione permessi cartella, pulizia dipendenze inutilizzate,
  allineamento documentazione).
