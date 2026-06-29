# Decisions — log-analyzer

## ADR-001 — Singolo file Python

**Data:** 2026-06-29
**Stato:** Accettato

**Decisione:** Tutto il codice risiede in `log_analyzer.py`. Nessun pacchetto, nessun modulo separato.

**Motivazione:** Coerenza con gli altri progetti della stazione. Facilita review e distribuzione.

---

## ADR-002 — Parsing markdown testuale (no parser esterno)

**Data:** 2026-06-29
**Stato:** Accettato

**Decisione:** Parsing di TASKS.md, RUN_LOG.md e REVIEW_LOG.md tramite regex e scansione
linea per linea. Nessuna dipendenza a librerie markdown esterne.

**Motivazione:** I file hanno struttura controllata (prodotta dai template della stazione).
Un parser testuale semplice è sufficiente e non introduce dipendenze.

**Rischio:** Se il formato dei file devia dai template, il parsing può produrre risultati
incompleti. Mitigazione: i test usano fixture reali dei progetti esistenti.

---

## ADR-003 — Progetto ignorato se manca docs/ai/TASKS.md

**Data:** 2026-06-29
**Stato:** Accettato

**Decisione:** `find_projects()` include una directory sotto `projects/` solo se contiene
`docs/ai/TASKS.md`. Directory senza questo file vengono silenziosamente ignorate.

**Motivazione:** Evita errori su directory non-progetto. L'assenza di TASKS.md indica
che il progetto non è stato inizializzato con il template standard.
