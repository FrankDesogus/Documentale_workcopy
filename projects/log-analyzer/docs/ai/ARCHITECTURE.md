# Architecture — log-analyzer

## Contesto

CLI tool che legge i file di documentazione AI dei progetti della stazione e produce
un riepilogo dello stato. Singolo file Python, zero dipendenze esterne.

## Componenti principali

| Componente | Responsabilità |
|------------|----------------|
| `log_analyzer.py` | Entry point, parsing argomenti, scansione progetti, output |
| `scripts/test.sh` | Test automatici: struttura + comportamento CLI |

## Struttura interna di `log_analyzer.py`

```
find_projects(projects_dir: Path) → List[Path]
  — restituisce le sottodirectory che contengono docs/ai/TASKS.md

parse_tasks(tasks_path: Path) → Dict[str, List[Dict]]
  — parsing TASKS.md; dict con chiavi "backlog", "in_corso", "completati"
  — ogni elemento: {"id": str, "titolo": str}

parse_last_run(run_log_path: Path) → Optional[Dict]
  — parsing RUN_LOG.md; ultima entry ### Run — YYYY-MM-DD
  — campi: data, task, agente, esito_test

parse_last_review(review_log_path: Path) → Optional[Dict]
  — parsing REVIEW_LOG.md; ultima entry ### Review — YYYY-MM-DD
  — campi: data, reviewer, esito

summarize_project(project_dir: Path) → Dict
  — aggrega i risultati per un singolo progetto

format_summary(summaries: List[Dict]) → str
  — formatta l'output testuale leggibile

main()
  — argparse + dispatch
```

## Flusso

```
argomenti CLI
  → find_projects() o singolo --project
    → per ogni progetto: summarize_project()
      → parse_tasks() + parse_last_run() + parse_last_review()
        → format_summary()
          → stdout (o file con --output)
```

## Formato input

- `docs/ai/TASKS.md`: tabelle markdown con sezioni `## Backlog`, `## In corso`, `## Completati`
- `docs/ai/RUN_LOG.md`: sezioni `### Run — YYYY-MM-DD ...` con `**Agente:**`, `**Task:**`, esito test
- `docs/ai/REVIEW_LOG.md`: sezioni `### Review — YYYY-MM-DD ...` con `**Esito:**`

## Formato output (testo)

```
== log-analyzer ==
Tasks: 2 completati | 1 in corso | 3 backlog
Ultimo run: 2026-06-29 — TASK-003 — Agente: Cursor Agent — Esito: PASS
Ultima review: 2026-06-29 — Reviewer: Claude Code — Esito: Approvato
```

## Dipendenze esterne

Nessuna. Solo Python standard library (`argparse`, `pathlib`, `re`, `sys`, `typing`).

## Decisioni rilevanti

Vedi `DECISIONS.md`.

## Data ultima revisione

2026-06-29
