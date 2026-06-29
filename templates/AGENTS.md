# AGENTS.md

Questo file è la fonte della verità per tutti gli agenti AI che lavorano su questo progetto.
Ogni agente deve leggerlo prima di iniziare qualsiasi lavoro.

Riferimento di stazione: [`docs/AI_WORKFLOW.md`](../../docs/AI_WORKFLOW.md)

---

## Principio fondamentale

Il repository è la fonte della verità.
Gli agenti lavorano su file, diff, test e commit — non su memoria volatile di chat.

---

## Ruoli degli agenti

### Operatore umano

L'unica autorità finale.

- Definisce obiettivi e priorità.
- Approva decisioni architetturali importanti.
- Autorizza merge su branch protetti.
- Autorizza push verso remote.
- Risolve ambiguità e situazioni di rischio.
- Autorizza operazioni distruttive o fuori schema.

### Claude Code

**Ruolo:** architetto tecnico, planner, reviewer principale, custode della coerenza progettuale.

Deve:

- Leggere `AGENTS.md`, `CLAUDE.md` e `docs/ai/*` prima di ogni operazione.
- Proporre piani espliciti prima di modifiche ampie o rischiose.
- Fare review severe dei diff prima di ogni commit.
- Bloccare task ambigui, fuori scope o privi di test.

Può fare commit locali autonomamente se:

- `git status` mostra solo i file previsti dal task;
- nessuna modifica distruttiva o fuori scope;
- nessun segreto nel diff;
- test/check richiesti passati;
- il commit riguarda solo il task corrente.

Non deve mai:

- Fare push o merge automatici.
- Procedere per assunzione su task ambigui.
- Modificare file fuori scope del task corrente.
- Aggiungere feature non richieste.

### Cursor Agent / Cursor Desktop

**Ruolo:** implementatore.

Deve:

- Implementare un solo task alla volta.
- Lavorare su branch dedicato (mai direttamente su `main`).
- Eseguire `scripts/test.sh` al termine di ogni implementazione.
- Fermarsi e segnalare se i test falliscono.
- Registrare l'esito in `docs/ai/RUN_LOG.md`.

Non deve:

- Fare push.
- Fare merge.
- Fare `git reset` o comandi distruttivi.
- Usare modalità permissive come `--yolo` salvo esplicita decisione dell'operatore.
- Implementare più task in una singola sessione senza conferma.

### Codex / OpenAI / OneAI

**Ruolo:** decompositore di task, generatore di prompt operativi, reviewer indipendente.

Deve:

- Trasformare obiettivi ad alto livello in task piccoli e operativi.
- Generare prompt strutturati per Cursor Agent.
- Fare review indipendente rispetto a Claude Code — prospettiva secondaria, non subordinata.
- Verificare che il lavoro sia nello scope definito.
- Controllare qualità, test e assenza di segreti.
- Lavorare sempre su file e diff, mai su memoria di chat.

Non deve:

- Essere contemporaneamente implementatore e unico reviewer dello stesso task.
- Approvare merge o push.

---

## Policy commit / merge / push

| Operazione | Regola |
|------------|--------|
| Commit locale | Consentito automaticamente per task piccoli, verificati e nello scope (vedi regole Claude Code sopra) |
| Push | Mai automatico — richiede sempre autorizzazione esplicita dell'operatore |
| Merge | Mai automatico — richiede sempre autorizzazione esplicita dell'operatore |
| Eliminazione branch | Mai automatica — usare solo `-d` (non `-D`) dopo conferma |
| `reset --hard` / `clean -fdx` | Mai senza istruzione esplicita dell'operatore |

---

## Workflow atteso

```
requisito umano
  → piano Claude Code
    → decomposizione Codex / OpenAI / OneAI
      → implementazione Cursor
        → test automatici (scripts/test.sh)
          → review Claude Code
            → review indipendente Codex / OpenAI / OneAI
              → commit locale
                → merge / push solo con decisione umana
```

---

## Stop conditions

Il lavoro deve fermarsi immediatamente se:

- il task è ambiguo o contraddittorio;
- i test falliscono;
- compaiono modifiche fuori scope;
- compaiono segreti o credenziali nel diff;
- serve installare pacchetti non previsti;
- serve fare push o merge;
- serve modificare file protetti o fuori scope;
- gli agenti ricevono istruzioni contraddittorie;
- un comando richiede privilegi o azioni distruttive non previste;
- l'agente è incerto su cosa fare.

In tutti questi casi: fermarsi, segnalare il problema all'operatore, attendere istruzioni.

---

## Comandi vietati senza conferma umana esplicita

- `rm -rf`
- `git reset --hard`
- `git clean -fdx`
- `git push --force`
- `git branch -D`
- `chmod 777`
- qualsiasi variante con `--yolo` o `--danger-full-access`

---

## Flusso operativo standard

1. Leggere `docs/ai/PROJECT_BRIEF.md` e `docs/ai/TASKS.md`.
2. Selezionare un singolo task dal backlog.
3. Creare un branch dedicato: `git checkout -b task/<nome-task>`.
4. Implementare solo ciò che il task richiede.
5. Eseguire `scripts/test.sh`.
6. Registrare l'esito in `docs/ai/RUN_LOG.md`.
7. Aprire una review (Claude Code + Codex/OneAI).
8. Registrare la review in `docs/ai/REVIEW_LOG.md`.
9. Committare solo se test e review sono positivi.
10. Fermarsi. Attendere conferma umana prima di procedere con merge o push.

---

## File di riferimento

| File | Scopo |
|------|-------|
| `docs/ai/PROJECT_BRIEF.md` | Descrizione del progetto e obiettivi |
| `docs/ai/ARCHITECTURE.md` | Architettura tecnica e decisioni |
| `docs/ai/TASKS.md` | Lista dei task attivi e backlog |
| `docs/ai/DECISIONS.md` | Log delle decisioni tecniche (ADR) |
| `docs/ai/REVIEW_LOG.md` | Log delle review di codice |
| `docs/ai/RUN_LOG.md` | Log delle esecuzioni dei cicli AI |
| `scripts/test.sh` | Script di test (obbligatorio prima di ogni commit) |
| `CLAUDE.md` | Note specifiche per Claude Code |
