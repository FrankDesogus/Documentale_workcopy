# Decision Log

Registro delle decisioni tecniche rilevanti (formato ADR — Architecture Decision Record).
Ogni decisione ha uno stato: `Proposto`, `Accettato`, `Superato`, `Rifiutato`.

---

## Template

### ADR-000 — Titolo della decisione

**Data:** YYYY-MM-DD
**Stato:** Proposto | Accettato | Superato | Rifiutato

**Contesto:**
<!-- Quale problema o situazione ha reso necessaria questa decisione -->

**Decisione:**
<!-- Cosa si è deciso di fare -->

**Motivazione:**
<!-- Perché questa scelta rispetto alle alternative -->

**Alternative considerate:**
<!-- Altre opzioni valutate e perché non scelte -->

**Conseguenze:**
<!-- Impatto tecnico, vincoli futuri, trade-off accettati -->

---

<!-- Aggiungi le decisioni qui sotto in ordine cronologico, partendo da ADR-001 -->

### ADR-001 — Python standard library + argparse per la CLI

**Data:** 2026-06-29
**Stato:** Accettato

**Contesto:**
Il progetto demo richiede una CLI minimale senza dipendenze esterne, eseguibile
con il Python già presente nell'ambiente (3.14.5).

**Decisione:**
Usare Python standard library con `argparse` per il parsing degli argomenti.
Un singolo file `cli.py` nella root del progetto.

**Motivazione:**
- Python è già installato e verificato dall'ambiente della stazione.
- `argparse` è parte della standard library: zero dipendenze esterne.
- Un solo file è sufficiente per la portata del demo.
- Bash puro avrebbe reso il parsing di `--name` e `--version` più verboso.

**Alternative considerate:**
- Bash puro: scartato perché `argparse` offre parsing più robusto e leggibile.
- Python con `click` o `typer`: scartato perché richiederebbero `pip install`.

**Conseguenze:**
- `python cli.py` richiede Python 3 nel PATH.
- Nessuna dipendenza da installare.
- Per progetti futuri con CLI più complesse, rivalutare l'uso di `click`.
