<!--
  Template standard per docs/ai/TASKS.md dei progetti della AI Software Station.
  Copia questo file in projects/<nome>/docs/ai/TASKS.md e compila i campi.

  COMPATIBILITÀ CON GLI STRUMENTI (importante):
  - scripts/cursor-prompt.sh (prompt_builder.py) legge:
      * le TABELLE (serve una riga header che inizi con "ID");
      * la SEZIONE DETTAGLIO di un task, trovata dall'heading che contiene il
        task ID e catturata FINO AL PROSSIMO heading di livello ## o ###.
  - Regola d'oro: l'heading di dettaglio è di livello ### e contiene l'ID
    (es. "### TASK-001 — Titolo — Agente"). Le sotto-sezioni del dettaglio
    (Obiettivo, Scope, ecc.) DEVONO essere di livello #### (quattro cancelletti),
    altrimenti interrompono l'estrazione del dettaglio.
  - scripts/ai-review.sh usa Scope/Test/Guardrail per compilare il verdetto.
-->

# Tasks

## In corso

| ID | Titolo | Agente | Branch | Note |
| -- | ------ | ------ | ------ | ---- |
|    |        |        |        |      |

## Backlog

| ID | Titolo | Priorità | Note |
| -- | ------ | -------- | ---- |
| TASK-001 | Titolo breve del task | media | nota facoltativa |

## Completati

| ID | Titolo | Commit | Data |
| -- | ------ | ------ | ---- |

---

## Dettaglio task

<!-- Un blocco "### TASK-XXX — Titolo — Agente" per ogni task.
     Sotto-sezioni SEMPRE a livello #### (vedi nota in testa al file). -->

### TASK-001 — Titolo breve del task — Cursor Agent

#### Obiettivo

Descrivi in una-due frasi il risultato atteso.

#### Scope

- Cosa rientra nel task.
- Confini espliciti (cosa NON toccare).

#### File coinvolti

- `percorso/file-da-modificare`
- Non modificare: `test_*.py`, `scripts/test.sh`.

#### Acceptance criteria

- [ ] Criterio verificabile 1.
- [ ] Criterio verificabile 2.

#### Test richiesti

- `./scripts/test.sh` esce con codice 0.
- Copertura del comportamento introdotto dal task.

#### Guardrail

- No push, no merge, no reset --hard, no git clean.
- No dipendenze esterne, no installazioni, no accesso di rete.
- No commit da parte dell'implementatore.
- Non modificare file fuori scope.

#### Note operative

Eventuali indicazioni aggiuntive per l'implementatore.

---

## Regole di aggiornamento

- Sposta un task da Backlog a "In corso" solo quando inizia il lavoro.
- Un solo task "In corso" per agente alla volta.
- Sposta in "Completati" solo dopo test e review positivi (verdetto APPROVED,
  COMMIT_READY: YES).
- Registra sempre il commit di riferimento nei task completati.
