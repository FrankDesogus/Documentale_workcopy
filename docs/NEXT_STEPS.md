# Next Steps — AI Software Station

Documento delle decisioni aperte e della roadmap immediata.
Aggiornato il 2026-06-29.

---

## Stato attuale

Sono stati completati e mergiati su `main`:

| Progetto | Descrizione | Test |
|----------|-------------|------|
| `demo-minimal` | CLI Python minimale (`--version`, `--name`) | 14/14 |
| `task-cli-pilot` | Task manager CLI (add, list, done, delete, clear) | 35/35 |
| `cursor-prompt-builder` | Generatore di prompt operativi per Cursor Agent da TASKS.md | 35/35 |

Il ciclo manuale è stato validato end-to-end tre volte:
scaffold → implementazione → test → review → commit → merge.

Wrapper di stazione disponibile: `./scripts/cursor-prompt.sh`

Documentazione di stazione completa:
`ARCHITECTURE.md`, `SECURITY.md`, `RUNBOOK.md`, `AI_WORKFLOW.md`, `NEXT_STEPS.md`.

Template aggiornati con ruoli formali di tutti gli agenti.

---

## Decisioni aperte

### 1. Cursor Agent come implementatore ufficiale

**Stato:** ✓ DECISO — 2026-06-29

Il prossimo progetto viene implementato da Cursor Agent.
Claude Code opera solo come architetto, planner e reviewer.
Questo è il primo test reale del ciclo multi-agente completo.

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

**Stato:** ✓ COMPLETATO — 2026-06-29

`cursor-prompt-builder` — generatore di prompt operativi per Cursor Agent da `TASKS.md`.
Implementato con ciclo multi-agente reale (Claude Code + Cursor Agent).
Wrapper di stazione: `./scripts/cursor-prompt.sh`.

Il quarto progetto è da pianificare: un problema concreto dell'operatore,
non un esercizio costruito apposta per testare il workflow.

---

## Roadmap consigliata

Ordine basato su dipendenze e valore immediato:

```
1. Quarto progetto reale
   └── Usa new-project.sh per lo scaffold
   └── Usa cursor-prompt.sh per generare i prompt operativi
   └── Cursor Agent implementa
   └── Claude Code + OneAI fanno review

2. ai-review.sh (dry-run)
   └── Prerequisito soddisfatto: tre cicli con Cursor completati

3. ai-cycle.sh (dry-run)
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

2026-06-29 (aggiornato post cursor-prompt-builder)
