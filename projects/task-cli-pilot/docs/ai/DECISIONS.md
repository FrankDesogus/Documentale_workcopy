# Decision Log — task-cli-pilot

Registro delle decisioni tecniche rilevanti (formato ADR — Architecture Decision Record).
Ogni decisione ha uno stato: `Proposto`, `Accettato`, `Superato`, `Rifiutato`.

---

### ADR-001 — Singolo file `task_cli.py` con Python standard library

**Data:** 2026-06-29
**Stato:** Accettato

**Contesto:**
Secondo progetto pilota della stazione. Deve essere abbastanza reale da validare il workflow
multi-agente, ma abbastanza semplice da implementare in pochi task controllati.

**Decisione:**
Un singolo file `task_cli.py`, solo stdlib Python (argparse, json, sys, pathlib).

**Motivazione:**
- Zero dipendenze: nessun `pip install`, nessun virtualenv da gestire.
- Un file: facile da revisionare, facile da testare.
- Abbastanza complesso da richiedere più task e un ciclo di implementazione reale.

**Alternative considerate:**
- Più file/moduli: scartato, troppo strutturato per un pilota.
- `click` o `typer`: scartato, richiedono dipendenze esterne.
- SQLite invece di JSON: scartato, overkill per una lista di task personali.

**Conseguenze:**
- Tutta la logica è in un file; se il progetto cresce, si rivaluta la struttura.
- `tasks.json` è nella directory corrente al momento dell'esecuzione.

---

### ADR-002 — Storage JSON, non database

**Data:** 2026-06-29
**Stato:** Accettato

**Contesto:**
Serve persistenza tra esecuzioni senza installare nulla.

**Decisione:**
File `tasks.json` nella directory corrente. Formato: lista di oggetti con `id`, `text`, `done`.

**Motivazione:**
- Leggibile a occhio nudo.
- Modificabile manualmente se necessario.
- Nessuna dipendenza.

**Conseguenze:**
- `tasks.json` non va versionato (aggiunto a `.gitignore`).
- Il path del file dipende dalla directory corrente — comportamento accettabile per un pilota.

<!-- Aggiungi le decisioni successive qui sotto in ordine cronologico -->
