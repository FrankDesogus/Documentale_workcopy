# Architecture — cursor-prompt-builder

## Contesto

Tool CLI che trasforma un task documentato in un prompt operativo per Cursor Agent.
Singolo file Python, zero dipendenze esterne.

## Componenti principali

| Componente | Responsabilità |
|------------|----------------|
| `prompt_builder.py` | Entry point, parsing argomenti, lettura TASKS.md, generazione prompt |
| `scripts/test.sh` | Test automatici: struttura + comportamento CLI |

## Struttura interna di `prompt_builder.py`

```
find_tasks_file(project_dir, tasks_file) → Path
  — risolve la sorgente TASKS.md da --project o --tasks-file

parse_task(tasks_md: str, task_id: str) → dict | None
  — estrae titolo, agente, note del task per ID

build_prompt(task: dict, project_dir: Path, task_id: str) → str
  — assembla il prompt operativo per Cursor Agent

main()
  — argparse + dispatch
```

## Flusso

```
argomenti CLI
  → find_tasks_file()
    → parse_task()
      → build_prompt()
        → stdout (o file con --output)
```

## Formato input (TASKS.md)

Tabella markdown con colonne ID, Titolo, Agente, Branch, Note.
Estrazione per corrispondenza testuale sull'ID nella colonna appropriata.

## Formato output

Testo plain, strutturato per essere incollato direttamente come prompt a Cursor Agent.

## Dipendenze esterne

Nessuna. Solo Python standard library.

## Decisioni rilevanti

Vedi [`DECISIONS.md`](DECISIONS.md).

## Data ultima revisione

2026-06-29
