# Next Steps — AI Software Station

Documento delle decisioni aperte e della roadmap immediata.
Aggiornato dopo la chiusura di `task-cli-pilot` (2026-06-29).

---

## Stato attuale

Sono stati completati e mergiati su `main`:

| Progetto | Descrizione | Test |
|----------|-------------|------|
| `demo-minimal` | CLI Python minimale (`--version`, `--name`) | 14/14 |
| `task-cli-pilot` | Task manager CLI (add, list, done, delete, clear) | 35/35 |

Il ciclo manuale è stato validato end-to-end due volte:
scaffold → implementazione → test → review → commit → merge.

Documentazione di stazione completa:
`ARCHITECTURE.md`, `SECURITY.md`, `RUNBOOK.md`, `AI_WORKFLOW.md`, `NEXT_STEPS.md`.

Template aggiornati con ruoli formali di tutti gli agenti.

---

## Decisioni aperte

### 1. Cursor Agent come implementatore ufficiale

**Stato:** non ancora validato in pratica.

Finora Claude Code ha implementato tutto. Il workflow prevede Cursor Agent come
implementatore, ma non è mai stato usato davvero su un task di codice reale.

**Domanda per l'operatore:** il prossimo progetto viene affidato a Cursor Agent
per l'implementazione, con Claude Code solo come reviewer?

**Impatto:** se sì, il prossimo progetto è il test reale del ciclo multi-agente.

---

### 2. `scripts/ai-review.sh` (stub dry-run)

**Stato:** non ancora creato.

Script che automatizza la fase di review: raccoglie il diff, prepara il contesto,
invoca Claude Code in modalità review. In questa fase: solo dry-run (stampa
cosa farebbe, senza eseguire nulla).

**Prerequisito:** almeno un ciclo completo con Cursor Agent come implementatore.

**Rischio:** basso se rimane in dry-run. Medio se viene reso operativo.

---

### 3. `scripts/ai-cycle.sh` (stub dry-run)

**Stato:** non ancora creato.

Script che orchestra l'intero ciclo: branch → implementazione → test → review →
commit → stop. In questa fase: solo dry-run.

**Prerequisito:** `ai-review.sh` stabile e validato.

**Rischio:** medio anche in dry-run — definisce il confine tra workflow manuale
e semi-automatico. Va introdotto solo dopo che il workflow manuale è rodato.

---

### 4. MCP (Model Context Protocol)

**Stato:** rimandato.

Nessun caso d'uso attivo che richieda MCP. Le directory `mcp/` e `agents/`
sono ancora placeholder.

**Quando rivalutare:** quando un progetto reale richiede accesso a strumenti
esterni (file system remoto, API, database) che gli agenti attuali non coprono.

---

### 5. Modello locale (Ollama o equivalente)

**Stato:** rimandato.

`local-models/` è ancora un placeholder.

**Quando rivalutare:** quando c'è un caso d'uso concreto (pre-review offline,
riassunti di log, lavoro senza connessione) e il workflow base è stabile.

---

### 6. Terzo progetto pilota

**Stato:** da pianificare.

Il terzo progetto dovrebbe essere più reale dei due pilota: un problema concreto
dell'operatore, non un esercizio costruito apposta per testare il workflow.

**Criterio di scelta:**
- Scope definibile in 3-5 task
- Nessuna dipendenza esterna obbligatoria
- Implementabile con Python o Bash
- Utile nella pratica quotidiana dell'operatore

**Candidati possibili** (decidere con l'operatore):
- Wrapper CLI per operazioni git ripetitive nella stazione
- Script di analisi dei log dei cicli AI
- Generatore di prompt operativi per Cursor Agent da `TASKS.md`

---

## Roadmap consigliata

Ordine basato su dipendenze e valore immediato:

```
1. Decidere se Cursor Agent implementa il prossimo progetto
   └── Se sì → avviare terzo progetto con Cursor come implementatore
   └── Se no → continuare con Claude Code, rivalutare dopo

2. Terzo progetto reale
   └── Usa new-project.sh per lo scaffold
   └── OneAI decompone i task
   └── Cursor implementa (o Claude Code se non ancora pronto)
   └── Claude Code + OneAI fanno review

3. ai-review.sh (dry-run)
   └── Solo dopo il primo ciclo con Cursor come implementatore

4. ai-cycle.sh (dry-run)
   └── Solo dopo ai-review.sh stabile

5. MCP / modello locale
   └── Solo quando c'è un caso d'uso concreto
```

---

## Cosa NON fare ora

- Non introdurre `ai-cycle.sh` operativo prima di avere 3+ cicli manuali rodati.
- Non configurare MCP senza un caso d'uso specifico.
- Non installare Ollama senza un progetto che lo richieda.
- Non creare automazioni che bypassino la decisione umana su merge e push.
- Non aggiungere dipendenze esterne ai progetti pilota.

---

## Data ultima revisione

2026-06-29
