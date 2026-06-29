# AGENTS.md

Questo file è la fonte della verità per tutti gli agenti AI che lavorano su questo progetto.
Ogni agente deve leggerlo prima di iniziare qualsiasi lavoro.

## Principio fondamentale

Il repository è la fonte della verità.
Gli agenti lavorano su file, diff, test e commit — non su memoria volatile di chat.

## Agenti autorizzati

| Agente      | Ruolo principale                                 |
| ----------- | ------------------------------------------------ |
| Claude Code | Architettura, pianificazione, review tecnica     |
| Codex CLI   | Decomposizione task, review indipendente, QA     |
| Cursor      | Implementazione del codice, sviluppo interattivo |

## Regole obbligatorie per tutti gli agenti

- Leggere `AGENTS.md` prima di iniziare qualsiasi task.
- Eseguire `git status` prima di ogni operazione: il working tree deve essere pulito.
- Lavorare su un branch dedicato per ogni task. Mai direttamente su `main`.
- Eseguire i test (`scripts/test.sh`) prima di ogni commit.
- Non committare se i test falliscono.
- Non fare push automatico.
- Non fare merge automatico.
- Non eseguire comandi distruttivi senza conferma umana esplicita.
- Non modificare file fuori scope del task corrente.
- Non versionare segreti, credenziali, chiavi API o file `.env`.
- Fermarsi e chiedere conferma se il task è ambiguo.

## Comandi vietati

Questi comandi non devono mai essere eseguiti senza conferma umana esplicita:

- `rm -rf`
- `git reset --hard`
- `git clean -fdx`
- `git push --force`
- `chmod 777`
- qualsiasi variante con `--yolo` o `--danger-full-access`

## Flusso di lavoro standard

1. Leggere `docs/ai/PROJECT_BRIEF.md` e `docs/ai/TASKS.md`.
2. Selezionare un singolo task dal backlog.
3. Creare un branch dedicato: `git checkout -b task/nome-task`.
4. Implementare solo ciò che il task richiede.
5. Eseguire `scripts/test.sh`.
6. Registrare l'esito in `docs/ai/RUN_LOG.md`.
7. Aprire una review (Claude Code e/o Codex).
8. Registrare la review in `docs/ai/REVIEW_LOG.md`.
9. Committare solo se test e review sono positivi.
10. Fermarsi. Attendere conferma umana prima di continuare.

## Condizioni di stop obbligatorie

Il ciclo deve fermarsi immediatamente se:

- i test falliscono;
- la review respinge il diff;
- il task è ambiguo o contraddittorio;
- vengono modificati file fuori scope;
- compaiono segreti o credenziali nel diff;
- un comando richiede privilegi o azioni distruttive non previste;
- l'agente è incerto su cosa fare.

## File di riferimento

| File                       | Scopo                                               |
| -------------------------- | --------------------------------------------------- |
| `docs/ai/PROJECT_BRIEF.md` | Descrizione del progetto e obiettivi                |
| `docs/ai/ARCHITECTURE.md`  | Architettura tecnica e decisioni                    |
| `docs/ai/TASKS.md`         | Lista dei task attivi e backlog                     |
| `docs/ai/DECISIONS.md`     | Log delle decisioni tecniche (ADR)                  |
| `docs/ai/REVIEW_LOG.md`    | Log delle review di codice                          |
| `docs/ai/RUN_LOG.md`       | Log delle esecuzioni dei cicli AI                   |
| `scripts/test.sh`          | Script di test (obbligatorio prima di ogni commit)  |
| `CLAUDE.md`                | Note specifiche per Claude Code                     |
