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

---

## Orchestrazione del ciclo operativo (dry-run)

Per visualizzare in un colpo solo tutti i comandi del ciclo operativo per un task:

```bash
./scripts/ai-cycle.sh \
  --project <nome-progetto> \
  --task TASK-XXX \
  --dry-run
```

Lo script valida le precondizioni (branch ≠ main, working tree pulito, task in Backlog o In corso)
e mostra i comandi del ciclo nell'ordine corretto: generazione prompt Cursor, generazione prompt
review, esecuzione test, snapshot git. Non esegue nulla automaticamente.

Errori gestiti: branch main, working tree sporco, progetto inesistente, task non trovato, task già
in Completati. In tutti i casi: exit 1 con messaggio chiaro.

**Versione 1: solo --dry-run.** Nessun lancio automatico di agenti, nessuna modifica file,
nessuna operazione Git oltre la lettura del branch e dello status.

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
