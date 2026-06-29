# AI Workflow

Questo documento descrive il ciclo operativo della AI Software Station.
È il riferimento autoritativo per tutti gli agenti che lavorano nel repository.

---

## 1. Principio centrale

**Il repository è la fonte della verità.**

Gli agenti non devono lavorare su memoria volatile di chat o su assunzioni implicite.
Ogni decisione, piano, implementazione e review deve essere tracciato in file versionati.

Le fonti di verità sono, in ordine:

1. **File versionati** — codice, documentazione, configurazione.
2. **Diff Git** — cosa è cambiato e perché.
3. **Task documentati** — `docs/ai/TASKS.md` di ogni progetto.
4. **Test automatici** — gate duro, non opzionale.
5. **Review** — `docs/ai/REVIEW_LOG.md` di ogni progetto.
6. **Commit** — ogni commit deve essere atomico e significativo.

Un agente che non trova risposta in questi file deve fermarsi e chiedere all'operatore,
non procedere per assunzione.

---

## 2. Ruoli

### Operatore umano

L'operatore è l'unica autorità finale.

Responsabilità esclusive:

- Definire obiettivi e priorità.
- Approvare decisioni architetturali importanti.
- Autorizzare merge su branch protetti.
- Autorizzare push verso remote.
- Risolvere ambiguità o situazioni di rischio.
- Decidere quando introdurre nuovi strumenti (MCP, modelli locali, script autonomi).

### Claude Code

**Ruolo:** architetto tecnico, planner, reviewer principale.

Deve:

- Leggere `AGENTS.md`, `CLAUDE.md` e `docs/ai/*` prima di ogni operazione.
- Proporre piani espliciti prima di modifiche ampie o rischiose.
- Fare review severe dei diff prima di ogni commit.
- Bloccare task ambigui, fuori scope o privi di test.
- Non fare push, merge o operazioni distruttive senza istruzione esplicita.
- Non committare senza conferma dell'operatore.

Non deve mai:

- Procedere per assunzione su task ambigui.
- Modificare file fuori scope del task corrente.
- Aggiungere feature non richieste.

### Cursor Desktop

**Ruolo:** IDE interattivo per l'operatore.

Usato quando l'operatore vuole vedere e guidare le modifiche in tempo reale.
Non è un agente autonomo in questo contesto.

### Cursor Agent CLI

**Ruolo:** implementatore scriptabile.

Deve:

- Implementare un solo task alla volta.
- Lavorare sempre su un branch dedicato (mai su `main` direttamente).
- Eseguire i test al termine dell'implementazione.
- Fermarsi e segnalare se i test falliscono.

Non deve:

- Fare push.
- Fare merge.
- Usare `--yolo` o modalità permissive salvo test isolati esplicitamente autorizzati.
- Implementare più task in una singola sessione senza conferma.

### Codex CLI / OpenAI / OneAI

**Ruolo:** decompositore di task, prompt engineer operativo, reviewer indipendente.

Deve:

- Trasformare obiettivi ad alto livello in task piccoli e operativi.
- Generare prompt strutturati per Cursor Agent.
- Fare review indipendente rispetto a Claude Code — prospettiva secondaria, non subordinata.
- Verificare che il lavoro sia nello scope definito.
- Lavorare sempre su file e diff, mai su memoria di chat.

### Git

**Ruolo:** fonte della verità tecnica.

Regole operative:

- Un branch per task (naming: `task/<progetto>-<descrizione>`).
- Commit atomici con messaggio in inglese.
- Merge solo fast-forward dove possibile.
- Nessun push senza autorizzazione esplicita dell'operatore.
- I branch di task vengono eliminati dopo il merge, con `-d` (non `-D`).

### Test / lint / build

**Ruolo:** gate duro.

Un task non è completo se i test falliscono.
Nessun commit viene proposto con test in rosso.
`shellcheck` e `shfmt` sono obbligatori su ogni script bash.

### Modello locale (futuro, opzionale)

**Ruolo futuro:** supporto leggero offline.

Casi d'uso candidati:

- Riassunti di log.
- Pre-review di diff semplici.
- Analisi di errori ripetitivi.
- Lavoro offline senza dipendenza da API esterne.

Non deve mai:

- Essere il reviewer finale.
- Decidere architettura.
- Approvare commit o merge.

Da introdurre solo quando il workflow base è stabile e c'è un caso d'uso concreto.

### MCP (futuro, opzionale)

**Ruolo futuro:** integrazione controllata con strumenti esterni.

Da rimandare finché il workflow manuale non è rodato e stabile.
Ogni MCP introdotto deve avere uno scope definito e un guardrail esplicito.

---

## 3. Ciclo operativo manuale (attivo)

Il ciclo attuale è manuale e controllato dall'operatore ad ogni passaggio.

```
1. Operatore   →  definisce obiettivo e scope
2. Claude Code →  struttura architettura e lista task (docs/ai/TASKS.md)
3. OneAI       →  trasforma in task operativo; usa `./scripts/cursor-prompt.sh` per generare il prompt
4. Cursor      →  implementa su branch dedicato
5. Cursor      →  esegue test automatici (scripts/test.sh)
6. Claude Code →  review del diff (docs/ai/REVIEW_LOG.md)
7. OneAI       →  review indipendente
8. Claude Code →  propone commit
9. Operatore   →  approva commit
10. Operatore  →  autorizza merge su main
```

Ad ogni passaggio un agente può fermarsi e segnalare un problema all'operatore.
Nessun agente deve "proseguire comunque" in caso di dubbio.

---

## 4. Ciclo semi-automatico futuro (non ancora attivo)

In futuro sarà possibile orchestrare il ciclo tramite script (`ai-cycle.sh`, `ai-review.sh`).

Requisiti minimi prima di introdurre il ciclo semi-automatico:

- Almeno 2-3 cicli manuali completati e documentati su progetti reali.
- `AI_WORKFLOW.md` consolidato e validato dall'operatore.
- `ai-review.sh` in dry-run testato e approvato.

Vincoli che il ciclo semi-automatico dovrà rispettare sempre:

- Partire da working tree pulito.
- Lavorare su branch task dedicato.
- Implementare un solo task per esecuzione.
- Eseguire i test e bloccarsi in caso di fallimento.
- Non fare push automatico.
- Non fare merge automatico.
- Fermarsi e notificare l'operatore in caso di errore o ambiguità.

---

## 5. Guardrail

Questi vincoli si applicano a tutti gli agenti, in ogni fase.

| Vincolo | Note |
|---------|------|
| Nessun push automatico | Solo l'operatore autorizza push |
| Nessun merge automatico | Solo l'operatore autorizza merge |
| Nessun comando distruttivo | `reset --hard`, `clean -fdx`, `push --force` vietati |
| Niente segreti versionati | Chiavi, token, password non entrano mai nel repo |
| Niente lavoro diretto su `main` | Feature e fix sempre su branch dedicato |
| Commit solo con test verdi | Gate duro, non negoziabile |
| Review obbligatoria | Almeno Claude Code; idealmente anche OneAI |
| Stop su ambiguità | Chiedere all'operatore, non procedere per assunzione |

---

## 6. Stati del workflow

Ogni task in `docs/ai/TASKS.md` deve avere uno stato esplicito.

| Stato | Significato |
|-------|-------------|
| `PLANNED` | Task definito, non ancora assegnato |
| `READY` | Task assegnato, branch creato, pronto per implementazione |
| `IN_PROGRESS` | Implementazione in corso |
| `NEEDS_REVIEW` | Implementazione completata, in attesa di review |
| `NEEDS_FIX` | Review completata, richieste correzioni |
| `APPROVED` | Review positiva, in attesa di autorizzazione merge |
| `DONE` | Mergiato su main, branch eliminato |
| `BLOCKED` | Task bloccato da dipendenza esterna o ambiguità — richiede intervento operatore |

---

## 7. Roadmap immediata

Task aperti consigliati, in ordine di priorità:

| ID | Titolo | Priorità |
|----|--------|----------|
| TASK-STATION-004 | Definire formalmente ruolo OneAI/Codex in `templates/AGENTS.md` | Alta |
| TASK-STATION-005 | Creare `docs/NEXT_STEPS.md` con decisioni aperte | Media |
| TASK-STATION-006 | Creare `scripts/ai-review.sh` in modalità read-only/dry-run | Media |
| TASK-STATION-007 | Creare `scripts/ai-cycle.sh` in modalità dry-run | Bassa |
| TASK-STATION-008 | Secondo progetto pilota con ciclo multi-agente reale | Alta |

Il task 008 (secondo progetto pilota) è prioritario rispetto a 006 e 007:
è più utile validare il ciclo manuale con agenti reali che automatizzarlo prematuramente.
