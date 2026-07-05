# Testing status — Documentale Workcopy

Stato onesto della validazione della test suite in questa copia Station.
Aggiornato: 2026-07-05 (TASK-003 — suite Django validata end-to-end).

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

## Esito reale della suite Django (TASK-003 — 2026-07-05)

**PASS reale, non solo comportamento corretto dello script:**

```
== 0/3 — Verifica dipendenze Python (requirements.txt) ==
OK — dipendenze di requirements.txt importabili.

== 1/3 — Compilazione e sintassi Python ==
OK — compilazione/sintassi Python superata.
(1 SyntaxWarning non bloccante, vedi "Problemi minori noti" sotto)

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
```

**Comando eseguito:** `scripts/test.sh` con la venv `.venv` attivata
(Python 3.14.5, pip 26.1.1). **1207 test, tutti passati, 0 fallimenti,
0 errori.** Durata: ~8 minuti e mezzo.

### Problemi minori noti (non bloccanti, non corretti — fuori scope)

- `documents/versioning.py:9` — `SyntaxWarning: "\d" is an invalid escape
  sequence` durante `compileall`: una regex scritta come stringa normale
  invece che raw string (`r"..."`). Non impedisce l'esecuzione né i test
  (tutti passano), è un warning del futuro Python. **Non corretto in questo
  task** (modificherebbe codice applicativo, fuori scope di TASK-003) —
  candidato per un piccolo task correttivo dedicato in futuro.
- Molti messaggi informativi "Email non inviata: utente X senza indirizzo
  email" durante i test: comportamento atteso del backend email `locmem`
  con utenti di test senza indirizzo configurato, non un errore.
- Un messaggio "Errore durante apply: Errore simulato in test atomicità.
  Nessuna modifica applicata." è l'output atteso di un test che verifica
  esplicitamente il rollback transazionale (simula un errore apposta) — non
  un fallimento.

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
- Il warning cosmetico in `documents/versioning.py` resta da correggere in
  un task dedicato (non applicativo/bloccante).

## Interpretazione corretta di "test PASS" per questo progetto

Da questo momento, un "TESTS: PASS" riportato da una review su
`documentale-workcopy` **può** riferirsi a una suite Django reale verde,
**se e solo se** l'esecuzione è avvenuta con la venv `.venv` (o equivalente
con le dipendenze installate) attiva. Se `scripts/test.sh` viene eseguito
con l'interprete di sistema (senza dipendenze), fallirà di nuovo con
"dipendenze mancanti" — quel fallimento resta corretto e atteso, e va
distinto esplicitamente da un vero fallimento della suite applicativa.

## Prossimo passo

- Task piccolo, facoltativo: correggere il `SyntaxWarning` in
  `documents/versioning.py:9` (una riga, cambiare stringa in raw string).
- Procedere con i task della roadmap in `docs/ai/PROJECT_ANALYSIS.md`
  (es. migrazione permessi cartella, pulizia dipendenze inutilizzate,
  allineamento documentazione).
