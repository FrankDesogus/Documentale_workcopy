# Decision Log

Registro delle decisioni tecniche rilevanti (formato ADR — Architecture Decision Record).
Ogni decisione ha uno stato: `Proposto`, `Accettato`, `Superato`, `Rifiutato`.

---

### ADR-001 — Solo stdlib Python

**Data:** 2026-06-29
**Stato:** Accettato

**Contesto:**
Il tool deve girare nell'ambiente della stazione senza installare pacchetti.

**Decisione:**
Usare esclusivamente la stdlib Python (pathlib, argparse, sys).

**Motivazione:**
Zero dipendenze esterne = zero rischi di conflitti, zero installazioni, massima portabilità.

**Alternative considerate:**
- `rich` per output colorato: scartato (dipendenza esterna non necessaria).
- `click` per CLI: scartato (argparse stdlib è sufficiente per questo scope).

**Conseguenze:**
Output markdown semplice, senza colori ANSI. Accettabile per il caso d'uso.

---

### ADR-002 — Entry point singolo `summary.py`

**Data:** 2026-06-29
**Stato:** Accettato

**Contesto:**
Progetto piccolo, scope limitato.

**Decisione:**
Singolo file `summary.py` come entry point, senza package structure.

**Motivazione:**
Evitare complessità non necessaria per un tool con 3-4 funzioni.

**Alternative considerate:**
- Package con `src/station_summary/`: scartato (overkill per questo scope).

**Conseguenze:**
Tutto il codice in un file. Accettabile finché il file resta sotto ~150 righe.

---

<!-- Aggiungi le decisioni qui sotto in ordine cronologico -->
