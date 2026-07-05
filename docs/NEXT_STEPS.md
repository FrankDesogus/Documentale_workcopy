# Next Steps — AI Software Station

Documento delle decisioni aperte e della roadmap immediata.
Aggiornato il 2026-07-05.

---

## Stato attuale

Workflow AI end-to-end **validato con collaudo reale** (Cursor Agent come
implementatore, Claude Code come reviewer, commit gated), mergiato su `main`.

Disponibile e funzionante:

| Comando | Scopo |
|---------|-------|
| `scripts/task-intake.sh` | trasforma un'idea libera in bozza strutturata |
| `scripts/cursor-prompt.sh` | genera il prompt operativo per Cursor Agent da `TASKS.md` |
| `scripts/ai-review.sh` | genera il prompt di review con verdetto machine-readable |
| `scripts/ai-cycle.sh --dry-run` | mostra i comandi del ciclo senza eseguirli |
| `scripts/ai-cycle.sh --run` | esegue il ciclo assistito: prompt → Cursor Agent → test → review → log |
| `scripts/commit-if-approved.sh` | commit locale gated, solo se review APPROVED + test PASS |
| `scripts/ai-cycle-log.sh` | log Markdown locale di ogni ciclo in `logs/ai-cycles/` |
| `docs/templates/TASKS.template.md` | formato standard di `docs/ai/TASKS.md` |
| `scripts/new-project.sh` | scaffold completo (AGENTS.md, CLAUDE.md, cursor rules, ecc.) |
| `scripts/station-status.sh` | fotografia read-only dello stato della Station |
| `scripts/station-next-task.sh` | suggerisce il prossimo task e il comando `ai-cycle` pronto |
| `scripts/new-ai-project.sh` | scaffold leggero (README, TASKS.md, test.sh placeholder) |

Progetti pilota: `demo-minimal`, `task-cli-pilot`, `cursor-prompt-builder`,
`log-analyzer`, `station-summary`, `ai-cycle-dogfood` (quest'ultimo usato per
il collaudo end-to-end reale, TASK-002 implementato da Cursor Agent).

---

## Cosa manca davvero

1. **Uso su un progetto software reale più grande.** Tutti i pilota sono
   piccoli tool a scopo di validazione workflow. Manca ancora un caso d'uso
   con complessità paragonabile a un progetto vero.
2. **Selezione automatica del prossimo task su più progetti.** `station-next-task.sh`
   funziona per singolo progetto; non esiste ancora un comando che scansioni
   tutta la Station e proponga cosa fare dopo in assoluto.
3. **Dashboard/status più matura.** `station-status.sh` copre lo stato base
   (branch, helper, progetti, log); manca storicizzazione, metriche di
   durata dei cicli, o output non testuale.
4. **MCP e modello locale (Ollama).** Rimandati, nessun caso d'uso attivo.

---

## Cosa NON fare ora

- Non introdurre automazioni che bypassino la decisione umana su merge e push.
- Non configurare MCP o Ollama senza un caso d'uso specifico.
- Non aggiungere dipendenze esterne ai progetti pilota.
- Non rendere `ai-cycle.sh` più autonomo (es. commit automatico) senza nuova
  validazione esplicita: il commit resta sempre gated via `commit-if-approved.sh`.

---

## Roadmap consigliata

```
1. Progetto software reale più grande
   └── scripts/new-ai-project.sh (scaffold leggero) o new-project.sh (scaffold completo)
   └── scripts/station-next-task.sh --project <nome>
   └── scripts/ai-cycle.sh --run per ogni task
   └── review + commit-if-approved.sh

2. Selezione automatica multi-progetto (facoltativo)
   └── Solo se l'uso quotidiano di station-next-task.sh per singolo progetto
       risulta insufficiente.

3. MCP / modello locale
   └── Solo quando c'è un caso d'uso concreto.
```

---

## Data ultima revisione

2026-07-05 (aggiornato post merge `workflow-automation-v1` — aggiunti helper
operativi `station-status`, `station-next-task`, `new-ai-project`).
