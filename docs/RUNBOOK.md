# Runbook operativo

## Scopo

Questo documento descrive come usare la AI Software Station in modo controllato.

## Prima di iniziare qualsiasi lavoro

Eseguire sempre:

```bash
git status
```

Il repository deve essere pulito prima di avviare un ciclo automatico o semi-automatico.

## Check ambiente

Eseguire prima di qualsiasi ciclo di lavoro:

```bash
./scripts/checks/check-environment.sh
```

## Creazione di un nuovo progetto

I progetti software andranno creati dentro:

```text
projects/
```

Ogni progetto dovrà contenere almeno:

- `AGENTS.md`;
- `CLAUDE.md`;
- `.cursor/rules/project-rules.mdc`;
- `docs/ai/PROJECT_BRIEF.md`;
- `docs/ai/ARCHITECTURE.md`;
- `docs/ai/TASKS.md`;
- `docs/ai/DECISIONS.md`;
- `docs/ai/REVIEW_LOG.md`;
- `docs/ai/RUN_LOG.md`;
- `scripts/test.sh`.

### Generare un progetto dai template

Usare lo script `scripts/new-project.sh` per creare la struttura di base da zero:

```bash
./scripts/new-project.sh nome-progetto
```

Per verificare cosa verrebbe creato senza creare nulla:

```bash
./scripts/new-project.sh --dry-run nome-progetto
```

Lo script valida il nome, verifica che la directory non esista già, copia i template e rende eseguibile `scripts/test.sh`. Non esegue `git add` né commit: la revisione e il commit restano all'operatore umano.

## Intake di un nuovo progetto

Per trasformare un'idea libera in una bozza strutturata pronta per Claude Code:

```bash
./scripts/task-intake.sh \
  --project-name <nome-progetto> \
  --title "Titolo breve" \
  --request "Descrizione libera di cosa vuoi costruire." \
  --output /tmp/<nome-progetto>-intake.md
```

Il comando genera un file Markdown di intake con:

- richiesta originale;
- proposta di task iniziali;
- prompt pronto da passare a Claude Code per scaffold e TASKS.md;
- guardrail e vincoli standard.

**Nessun agente AI viene invocato.** L'operatore deve revisionare il file prima di procedere.

---

## Generazione prompt per Cursor Agent

Per generare un prompt operativo da passare a Cursor Agent, usare il wrapper dalla root del repository:

```bash
./scripts/cursor-prompt.sh --project projects/<nome-progetto> --task TASK-XXX
```

Per salvare il prompt su file (consigliato):

```bash
./scripts/cursor-prompt.sh \
  --project projects/<nome-progetto> \
  --task TASK-XXX \
  --output /tmp/cursor-task.md
```

In alternativa, puntare direttamente a un file TASKS.md:

```bash
./scripts/cursor-prompt.sh \
  --tasks-file projects/<nome-progetto>/docs/ai/TASKS.md \
  --task TASK-XXX \
  --output /tmp/cursor-task.md
```

**Nota:** usare sempre su task in Backlog o In corso.
Sui task già spostati nella sezione Completati, alcune colonne (es. "Agente previsto")
possono essere assenti perché la tabella ha struttura diversa.

---

## Generazione prompt di review per Claude Code

Dopo che Cursor Agent ha completato un task, generare un prompt di review strutturato:

```bash
./scripts/ai-review.sh \
  --project projects/<nome-progetto> \
  --task TASK-XXX \
  --output /tmp/review-prompt.md
```

Per stampare il prompt su stdout (utile per copiarlo direttamente):

```bash
./scripts/ai-review.sh \
  --project projects/<nome-progetto> \
  --task TASK-XXX \
  --stdout
```

Il prompt generato include: contesto repository/branch, file da leggere, comandi di verifica,
checklist review, istruzioni per commit locale se approvato, e divieti espliciti (no push, merge, reset).
Lo script non chiama agenti, non modifica file e non esegue operazioni Git.

### Verdetto macchina-leggibile (obbligatorio)

Ogni review generata da `ai-review.sh` richiede a Claude Code di chiudere l'output
con un blocco a valori fissi, letto poi da `scripts/commit-if-approved.sh`:

```
REVIEW_VERDICT: APPROVED | CHANGES_REQUESTED | BLOCKED
SCOPE: OK | ISSUES
TESTS: PASS | FAIL | NOT_RUN
SECURITY_GUARDRAILS: OK | ISSUES
DOCS_LOGS: OK | ISSUES | NOT_NEEDED
COMMIT_READY: YES | NO
```

Regole di coerenza:

- `COMMIT_READY: YES` solo se insieme `REVIEW_VERDICT: APPROVED`, `TESTS: PASS`,
  `SECURITY_GUARDRAILS: OK`.
- `REVIEW_VERDICT: APPROVED` **non basta** se `COMMIT_READY: NO`.
- `TESTS: NOT_RUN` o `TESTS: FAIL` ⇒ `COMMIT_READY: NO` (nessun commit automatico).
- `SCOPE: ISSUES` o `SECURITY_GUARDRAILS: ISSUES` ⇒ verdetto ≠ APPROVED e `COMMIT_READY: NO`.

La review verifica concretamente scope (`git diff`/`git status`), test, guardrail di
sicurezza (secret, comandi Git distruttivi, dipendenze), e documentazione/log.

---

## Orchestrazione del ciclo operativo

### Modalità dry-run (v1)

Per visualizzare tutti i comandi del ciclo senza eseguirli:

```bash
./scripts/ai-cycle.sh \
  --project <nome-progetto> \
  --task TASK-XXX \
  --dry-run
```

Lo script valida le precondizioni (branch ≠ main, working tree pulito, task in Backlog o In corso)
e mostra i comandi del ciclo nell'ordine corretto. Non esegue nulla automaticamente.

### Modalità run — esecuzione assistita (v2)

Per eseguire il ciclo completo in modo assistito e controllato:

```bash
./scripts/ai-cycle.sh \
  --project <nome-progetto> \
  --task TASK-XXX \
  --run
```

Il ciclo esegue nell'ordine:

1. Valida branch e working tree (blocca se non soddisfatte).
2. Valida progetto e task (blocca se task non in Backlog/In corso).
3. Genera il prompt Cursor Agent via `cursor-prompt.sh` → `/tmp/cursor-prompt-TASK-XXX.md`.
4. Lancia `claude -p --allowedTools "Read,Edit,Write,Bash"` con timeout 300s.
5. Esegue `scripts/test.sh` del progetto — **se i test falliscono, si ferma con exit 1**.
6. Genera il prompt di review via `ai-review.sh` → `/tmp/review-prompt-TASK-XXX.md`.
7. Mostra `git status` e `git diff --stat` come snapshot.

**Guardrail obbligatori di `--run`:**

- Mai push, merge, branch delete, `reset --hard`, `git clean`.
- Mai commit automatico.
- Si ferma immediatamente se i test falliscono.
- Il commit resta sempre a cura di Claude Code dopo review APPROVED.

Errori gestiti: branch main, working tree sporco, progetto inesistente, task non trovato, task già
in Completati, agent timeout/failure, test failure. In tutti i casi: exit 1 con messaggio chiaro.

---

## Commit locale controllato (`commit-if-approved.sh`)

Crea un commit **locale** solo se la review strutturata lo consente. Non fa mai
push né merge, non opera su `main`, non usa reset/clean.

```bash
./scripts/commit-if-approved.sh \
  --project <nome-progetto> \
  --task TASK-XXX \
  --review-file /tmp/review-prompt-TASK-XXX.md \
  [--paths "path1 path2"] \
  [--message "messaggio esplicito"] \
  [--dry-run]
```

Il commit è consentito **solo** se il review file contiene tutti:
`REVIEW_VERDICT: APPROVED`, `TESTS: PASS`, `SECURITY_GUARDRAILS: OK`,
`COMMIT_READY: YES`. Viene bloccato con messaggio chiaro su `CHANGES_REQUESTED`,
`BLOCKED`, `TESTS: FAIL`, `TESTS: NOT_RUN`, `COMMIT_READY: NO` o marker assenti
(le righe di legenda `A | B | C` del prompt grezzo vengono ignorate).

Precondizioni: branch ≠ `main`, working tree non vuoto, review file esistente.
Prima di committare mostra `git status` e i file staged. Con `--paths` si limita
lo staging; senza, viene usata la cartella del progetto. `--dry-run` valida e
mostra l'esito senza committare.

---

## Log centrale dei cicli AI (`ai-cycle-log.sh`)

Ogni `ai-cycle.sh --run` scrive automaticamente (STEP 8) un log Markdown sotto
`logs/ai-cycles/` con nome `YYYYMMDD-HHMMSS-<project>-<task>.md`. La cartella
`logs/` è gitignored: i log restano artefatti **locali**.

Lo script è anche invocabile a mano per registrare o simulare un ciclo:

```bash
./scripts/ai-cycle-log.sh \
  --project projects/<nome> --task TASK-XXX \
  --command "..." --agent-result "..." --tests-result PASS \
  --prompt-file /tmp/cursor-prompt-TASK-XXX.md \
  --review-file /tmp/review-prompt-TASK-XXX.md
```

Il log contiene: data/ora, branch, progetto, task, comando, esito agente, esito
test, prompt e review file, `git status` finale, note commit e la conferma
esplicita che non sono stati fatti push/merge/reset. L'accesso a Git è read-only.

---

## Template standard TASKS.md

Il template `docs/templates/TASKS.template.md` definisce il formato standard di
`docs/ai/TASKS.md`: tabelle **In corso / Backlog / Completati** più un blocco di
dettaglio per task.

**Convenzione critica per gli strumenti:** l'heading di dettaglio è di livello
`###` e contiene il task ID (`### TASK-XXX — Titolo — Agente`); le sotto-sezioni
(`Obiettivo`, `Scope`, `File coinvolti`, `Acceptance criteria`, `Test richiesti`,
`Guardrail`, `Note operative`) sono di livello `####`. Questo perché
`prompt_builder.py` cattura il dettaglio fino al primo heading `##`/`###`: usare
`###` per le sotto-sezioni troncherebbe l'estrazione. Il formato è validato su
`projects/ai-cycle-dogfood` (TASK-002).

---

## Flusso manuale iniziale

1. Scrivere o aggiornare il requisito in `docs/ai/PROJECT_BRIEF.md`.
2. Far preparare a Claude Code un piano tecnico.
3. Far decomporre il piano a Codex in task piccoli.
4. Far implementare un solo task a Cursor.
5. Eseguire `scripts/test.sh`.
6. Fare review con Claude e, se utile, con Codex.
7. Committare solo se test e review sono positivi.

## Regole Git

- Un branch per task.
- Un commit per task completato.
- Nessun push automatico.
- Nessun merge automatico.
- Nessun commit con working tree sporco non compreso.

## Regola di stop

Il ciclo deve fermarsi se:

- i test falliscono;
- la review respinge il diff;
- il task è ambiguo;
- vengono modificati file fuori scope;
- compaiono segreti o credenziali;
- un comando richiede privilegi o azioni distruttive non previste.
