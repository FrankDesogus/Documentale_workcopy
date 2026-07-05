# Testing status — Documentale Workcopy

Stato onesto della validazione della test suite in questa copia Station.
Aggiornato: 2026-07-05 (TASK-002).

## Stato attuale

- Test runner reale creato: `scripts/test.sh` (non più placeholder). Esegue,
  dalla root del progetto: 0) verifica dipendenze `requirements.txt`
  importabili; 1) `python -m compileall`; 2) `manage.py check`; 3)
  `manage.py test`.
- Settings di test dedicati presenti: `config/test_settings.py`. Nessun
  `.env` reale richiesto o letto (`SECRET_KEY` fittizia impostata via
  variabile d'ambiente prima dell'import di `config.settings`).
- Nessun database reale: i test Django, quando eseguiti, usano SQLite
  `:memory:` (mai un file persistente, mai `db.sqlite3`).
- **Dipendenze Django mancanti nell'ambiente attuale della Station**: né il
  Python di sistema né una `.venv` dedicata dentro `documentale-workcopy`
  hanno Django/`requirements.txt` installati. Per guardrail esplicito,
  nessuna installazione automatica di pacchetti viene eseguita da questo
  workflow.

## Cosa è stato validato

- Sintassi bash dello script (`bash -n`).
- `shellcheck` e `shfmt -d` su `scripts/test.sh` → puliti.
- `python -m py_compile` su `config/test_settings.py` → OK.
- Comportamento fail-fast se mancano dipendenze: verificato che lo script
  esce con `exit 1` ed elenca chiaramente le dipendenze mancanti, invece di
  dare un falso successo (`exit 0`).
- Integrazione con gli helper Station (`station-project-readiness.sh`,
  `station-next-task.sh`, `station-status.sh`) e regressioni sugli altri
  progetti pilota (cursor-prompt-builder, log-analyzer, ai-cycle-dogfood).

## Cosa NON è stato ancora validato

- **La suite Django reale non è mai stata eseguita end-to-end.** Il
  progetto sorgente documenta ~1100–1200 test (`PROJECT_ANALYSIS.md`), ma
  in questa copia nessuno di questi test è stato effettivamente lanciato.
- `manage.py check` non è mai stato eseguito con successo qui (si ferma
  prima, per mancanza di Django).
- Non è nota la compatibilità completa delle dipendenze pinnate in
  `requirements.txt` con la versione di Python disponibile in un futuro
  ambiente di test (es. Python 3.14 di questo sistema vs Python 3.12 target
  di `DEPLOY.md`).
- Eventuali problemi di migrazioni o modelli in un ambiente di test pulito
  (mai provato: nessuna migrazione è mai stata applicata in questa copia).

## Interpretazione corretta di "test PASS" per questo progetto

Quando un ciclo AI Software Station riporta test/review positivi su
`documentale-workcopy`, questo significa **che lo script si comporta
correttamente** (controlli reali quando possibile, fallimento chiaro
quando mancano dipendenze) — **non** che la suite Django del Documentale
sia stata validata verde. Le due cose vanno tenute distinte esplicitamente
in ogni review futura su questo progetto, finché TASK-003 non sarà
completato.

## Prossimo passo

**TASK-003 — Preparare ambiente test dedicato Documentale** (vedi
`docs/ai/TASKS.md`):

1. Creare/documentare un virtualenv dedicato per `documentale-workcopy`
   (dentro la copia o fuori dalla Station, da decidere).
2. Installare le dipendenze da `requirements.txt` in modo controllato e
   autorizzato esplicitamente dall'operatore (questo workflow non installa
   pacchetti da solo).
3. Eseguire `./scripts/test.sh` in quell'ambiente e osservare l'esito reale.
4. Documentare qui l'esito (PASS reale, o eventuali fallimenti applicativi
   trovati) e aggiornare questo file di conseguenza.
5. Solo dopo, considerare la rete di sicurezza automatica completa per i
   cicli futuri su questo progetto.
