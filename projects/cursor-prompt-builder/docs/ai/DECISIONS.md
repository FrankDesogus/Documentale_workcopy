# Decision Log — cursor-prompt-builder

Registro delle decisioni tecniche rilevanti (formato ADR).
Ogni decisione ha uno stato: `Proposto`, `Accettato`, `Superato`, `Rifiutato`.

---

### ADR-001 — Singolo file `prompt_builder.py`, solo stdlib

**Data:** 2026-06-29
**Stato:** Accettato

**Contesto:**
Terzo progetto pilota della stazione. Deve validare il ciclo con Cursor Agent
come implementatore. Scope piccolo e controllabile.

**Decisione:**
Singolo file `prompt_builder.py`, solo stdlib Python.

**Motivazione:**
- Zero dipendenze, nessun virtualenv.
- Facile da revisionare interamente in una review.
- Abbastanza strutturato (argparse, parsing markdown, templating) da essere
  un test reale per Cursor Agent.

**Alternative considerate:**
- Più moduli: scartato, overkill per questo scope.
- Jinja2 per templating: scartato, dipendenza esterna.

**Conseguenze:**
- Tutto in un file; se il progetto cresce oltre 200 righe, rivalutare.

---

### ADR-002 — Parsing TASKS.md con regex su tabella markdown

**Data:** 2026-06-29
**Stato:** Accettato

**Contesto:**
`TASKS.md` usa tabelle markdown. Serve estrarre una riga per ID task.

**Decisione:**
Parsing testuale con `re` della stdlib: cerca la riga della tabella che
contiene l'ID cercato e ne estrae le colonne.

**Motivazione:**
- Nessuna dipendenza da parser markdown esterno.
- Il formato delle tabelle nella stazione è uniforme e controllato.

**Conseguenze:**
- Fragile se il formato della tabella cambia. Accettabile per un pilota.

<!-- Aggiungi le decisioni successive qui sotto -->
