<!--
  Template per il TASKS.md iniziale generato da scripts/onboard-existing-project.sh
  quando si importa un progetto software reale già esistente.

  Placeholder sostituiti dallo script:
    imported-sample  -> nome tecnico del progetto (projects/<name>)
    Imported Sample -> titolo leggibile passato con --title

  Stesse regole di compatibilità di docs/templates/TASKS.template.md:
  l'heading di dettaglio è di livello ### e contiene l'ID; le sotto-sezioni
  del dettaglio sono SEMPRE di livello #### (altrimenti prompt_builder.py e
  gli helper di stazione troncano l'estrazione).
-->

# Tasks — Imported Sample

## In corso

_Nessun task in corso._

## Backlog

| ID | Titolo | Priorità | Note |
| -- | ------ | -------- | ---- |
| TASK-001 | Analisi iniziale progetto | alta | primo task obbligatorio dopo l'onboarding |

## Completati

| ID | Titolo | Commit | Data |
| -- | ------ | ------ | ---- |

---

## Dettaglio task

### TASK-001 — Analisi iniziale progetto — Cursor Agent

#### Obiettivo

Analizzare il progetto importato "Imported Sample" (imported-sample) e
produrre un report iniziale (`docs/ai/PROJECT_ANALYSIS.md`) che permetta di
pianificare il lavoro successivo con la AI Software Station.

#### Scope

- Solo analisi e lettura del codice esistente.
- Creare un solo file: `docs/ai/PROJECT_ANALYSIS.md`.
- Non modificare alcun file applicativo del progetto importato.
- Non modificare `docs/ai/TASKS.md` oltre a questo task: l'operatore
  trascrive la roadmap proposta nel Backlog dopo aver letto il report.

#### File coinvolti

- Creare: `docs/ai/PROJECT_ANALYSIS.md`.
- Non modificare: nessun altro file del progetto.

#### Cosa analizzare

- Struttura delle cartelle e organizzazione generale.
- Linguaggio/framework principale e versione, se rilevabile.
- Entry point (file principale, comando di avvio).
- Dipendenze dichiarate (es. requirements.txt, package.json, go.mod, Cargo.toml).
- Test esistenti, se presenti, e come si eseguono.
- Eventuali rischi tecnici o problemi evidenti (codice morto, TODO critici,
  segreti in chiaro, dipendenze obsolete).

#### Output richiesto

`docs/ai/PROJECT_ANALYSIS.md` con almeno queste sezioni:

- Panoramica del progetto.
- Stack tecnologico.
- Struttura cartelle (sintetica).
- Entry point.
- Dipendenze.
- Comandi di avvio/test, se rilevati.
- Rischi tecnici.
- Problemi evidenti.
- Roadmap proposta in task piccoli (elenco TASK-002, TASK-003, ... con una
  riga di descrizione ciascuno).
- Raccomandazione sul prossimo task da eseguire.

#### Acceptance criteria

- [ ] `docs/ai/PROJECT_ANALYSIS.md` creato con tutte le sezioni richieste.
- [ ] Nessun file applicativo del progetto modificato.
- [ ] Roadmap proposta con almeno 2-3 task futuri concreti.
- [ ] Raccomandazione esplicita sul prossimo task.

#### Test richiesti

- Task di sola analisi: non introduce codice, quindi non richiede nuovi test.
- Se `scripts/test.sh` esiste già ed esegue qualcosa di reale, deve
  continuare a uscire con lo stesso codice di prima (nessuna regressione).

#### Guardrail

- No push, no merge, no reset --hard, no git clean.
- No installazione di dipendenze, no accesso di rete, no esecuzione del
  codice applicativo del progetto importato.
- Non modificare file fuori scope.
- No commit da parte dell'implementatore.

#### Roadmap richiesta

L'output deve includere una proposta di roadmap in task piccoli e concreti,
pensata per essere trascritta a mano nel Backlog di questo `TASKS.md` una
volta che l'operatore l'ha rivista.

---

## Regole di aggiornamento

- Sposta un task da Backlog a "In corso" solo quando inizia il lavoro.
- Un solo task "In corso" per agente alla volta.
- Sposta in "Completati" solo dopo test e review positivi.
- Registra sempre il commit di riferimento nei task completati.
