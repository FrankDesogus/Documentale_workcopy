#!/usr/bin/env python3
import argparse
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional


def find_tasks_file(project_dir: Optional[str], tasks_file: Optional[str]) -> Path:
    if tasks_file:
        return Path(tasks_file)
    if project_dir:
        return Path(project_dir) / "docs" / "ai" / "TASKS.md"
    raise ValueError("either --project or --tasks-file is required")


def resolve_project_dir(project_dir: Optional[str], tasks_path: Path) -> Path:
    if project_dir:
        return Path(project_dir).resolve()
    resolved = tasks_path.resolve()
    if (
        resolved.name == "TASKS.md"
        and len(resolved.parents) >= 2
        and resolved.parent.name == "ai"
        and resolved.parent.parent.name == "docs"
    ):
        return resolved.parent.parent.parent
    return resolved.parent


def find_repo_root(start: Path) -> Path:
    current = start.resolve()
    for candidate in [current, *current.parents]:
        if (candidate / ".git").is_dir():
            return candidate
    return current


def project_rel_path(project_dir: Path, repo_root: Path) -> str:
    try:
        return str(project_dir.resolve().relative_to(repo_root.resolve()))
    except ValueError:
        return str(project_dir)


def expected_branch(task: Dict[str, str], project_dir: Path) -> str:
    for key in ("Branch", "Branch atteso", "branch"):
        value = task.get(key, "").strip()
        if value:
            return value
    return f"task/{project_dir.name}"


def _split_row(line: str) -> List[str]:
    line = line.strip()
    if not line.startswith("|") or not line.endswith("|"):
        return []
    return [c.strip() for c in line[1:-1].split("|")]


def _is_separator(cols: List[str]) -> bool:
    return bool(cols) and all(re.match(r"^-+$", c) for c in cols if c)


def parse_task(tasks_md: str, task_id: str) -> Optional[Dict[str, str]]:
    lines = tasks_md.splitlines()
    for i, line in enumerate(lines):
        cols = _split_row(line)
        if not cols or cols[0] != task_id:
            continue
        for j in range(i - 1, -1, -1):
            header_cols = _split_row(lines[j])
            if not header_cols:
                break
            if _is_separator(header_cols):
                continue
            if header_cols[0].upper() == "ID":
                return dict(zip(header_cols, cols))
        return {"ID": cols[0], "Titolo": cols[1] if len(cols) > 1 else ""}
    return None


def extract_task_detail(tasks_md: str, task_id: str) -> Optional[str]:
    """
    Estrae la sezione dettaglio di un task da TASKS.md.

    Cerca una riga heading (## o ###) che contenga task_id,
    e restituisce tutto il contenuto fino al prossimo heading di livello >= 2.
    Restituisce None se non trova la sezione.

    Esempi di heading accettati:
      ### TASK-001 — Scaffold + test base — Claude Code
      ### TASK-001 — Implementa summarize_status — Cursor Agent
      ## TASK-001 — Titolo
    """
    lines = tasks_md.splitlines()
    start = None
    heading_re = re.compile(r"^#{2,3}\s")
    task_re = re.compile(r"^#{2,3}\s.*\b" + re.escape(task_id) + r"\b")

    for i, line in enumerate(lines):
        if task_re.match(line):
            start = i
            break

    if start is None:
        return None

    detail_lines = [lines[start]]
    for line in lines[start + 1:]:
        if heading_re.match(line):
            break
        detail_lines.append(line)

    content = "\n".join(detail_lines).strip()
    return content if content else None


def build_read_first(project_dir: Path, project_rel: str) -> List[str]:
    """
    File da consigliare per la lettura, relativi al progetto TARGET (mai al
    builder stesso). docs/ai/TASKS.md è sempre incluso perché è la fonte del
    task; gli altri documenti di scaffold sono inclusi solo se esistono
    davvero sul disco, per non inventare file su progetti con scaffold
    leggero (es. new-ai-project.sh, onboard-existing-project.sh).
    """
    read_first = [f"{project_rel}/docs/ai/TASKS.md"]
    optional_docs = [
        "AGENTS.md",
        "docs/ai/PROJECT_BRIEF.md",
        "docs/ai/ARCHITECTURE.md",
        "scripts/test.sh",
    ]
    read_first.extend(
        f"{project_rel}/{doc}" for doc in optional_docs if (project_dir / doc).exists()
    )
    return read_first


def build_prompt(
    task: Dict[str, str],
    project_dir: Path,
    task_id: str,
    tasks_md: str = "",
    tasks_path: Optional[Path] = None,
) -> str:
    project_dir = Path(project_dir).resolve()
    repo_root = find_repo_root(project_dir)
    repository = str(repo_root)
    project_rel = project_rel_path(project_dir, repo_root)
    branch = expected_branch(task, project_dir)

    title = task.get("Titolo", "").strip()
    agent = task.get("Agente previsto", task.get("Agente", "")).strip()
    notes = task.get("Note", "").strip()
    task_detail = extract_task_detail(tasks_md, task_id) if tasks_md else None

    if tasks_path is not None:
        tasks_md_display = project_rel_path(tasks_path, repo_root)
    else:
        tasks_md_display = f"{project_rel}/docs/ai/TASKS.md"

    read_first = build_read_first(project_dir, project_rel)

    extra_fields = []
    skip_keys = {"ID", "Titolo", "Agente previsto", "Agente", "Note", "Branch", "Branch atteso", "branch"}
    for key, value in task.items():
        if key in skip_keys or not value.strip():
            continue
        extra_fields.append(f"- {key}: {value.strip()}")

    lines = [
        f"Repository: {repository}",
        f"Branch atteso: {branch}",
        f"Progetto: {project_rel}",
        f"TASKS.md: {tasks_md_display}",
        f"Task ID: {task_id}",
        f"Titolo task: {title}",
        f"Agente previsto: {agent}",
    ]

    if notes:
        lines.append(f"Note task: {notes}")

    if extra_fields:
        lines.append("")
        lines.append("Dettagli task:")
        lines.extend(extra_fields)

    lines.extend([
        "",
        "Agisci come Cursor Agent implementatore. Implementa solo "
        f"{task_id}. Non fare commit.",
        "",
        "Prima di modificare file, leggi obbligatoriamente:",
        "",
    ])
    lines.extend(f"- {path}" for path in read_first)

    lines.extend([
        "",
        "File modificabili:",
        f"- Solo i file esplicitamente autorizzati per {task_id} "
        "nella documentazione di progetto e nel task corrente.",
        "",
        f"Obiettivo: {title}",
    ])
    if notes:
        lines.append(f"Note operative: {notes}")

    lines.extend([
        "",
        "Scope del task:",
        f"- Implementare quanto richiesto per {task_id}: {title}.",
    ])
    if notes:
        lines.append(f"- {notes}")

    if task_detail:
        lines.extend([
            "",
            "## Dettaglio completo del task (da TASKS.md)",
            "",
            task_detail,
        ])

    lines.extend([
        "",
        "Fuori scope:",
        "- File non elencati nel task o nella documentazione di progetto.",
        "- Altri task del backlog.",
        "- Automazioni Git, push, merge o commit.",
        "- Dipendenze esterne, installazioni o accesso alla rete.",
        "",
        "Test da eseguire:",
        "",
        f"cd {project_rel}",
        "./scripts/test.sh",
        "cd ../..",
        "",
        "Se i test falliscono: fermati, non aggiornare RUN_LOG.md come successo, "
        "riporta errore e stato.",
        "",
        "Se i test passano: aggiorna "
        f"{project_rel}/docs/ai/RUN_LOG.md con l'esito di {task_id}; "
        "non modificare TASKS.md, REVIEW_LOG.md o DECISIONS.md; non fare commit.",
        "",
        "Stop conditions:",
        "- Task ambiguo o contraddittorio.",
        "- Test falliti.",
        "- Modifiche fuori scope.",
        "- Segreti o credenziali nel diff.",
        "- Necessità di installare pacchetti non previsti.",
        "- Necessità di push, merge o operazioni Git distruttive.",
        "- Istruzioni contraddittorie.",
        "- Incertezza su cosa fare.",
        "",
        "Guardrail obbligatori:",
        "- no push;",
        "- no merge;",
        "- no git reset --hard;",
        "- no git clean;",
        "- no dipendenze esterne;",
        "- no installazioni;",
        "- no rete;",
        "- no automazioni Git;",
        "- no commit;",
        "- non modificare file fuori scope.",
    ])

    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="prompt-builder",
        description="Generate Cursor Agent prompts from TASKS.md",
        add_help=True,
    )
    parser.add_argument(
        "--version",
        action="version",
        version="cursor-prompt-builder 0.1.0",
    )
    parser.add_argument(
        "--project",
        metavar="DIR",
        help="path to the project directory (reads docs/ai/TASKS.md)",
    )
    parser.add_argument(
        "--tasks-file",
        metavar="FILE",
        help="path to a TASKS.md file (alternative to --project)",
    )
    parser.add_argument(
        "--task",
        metavar="ID",
        help="task ID to generate the prompt for (e.g. TASK-002)",
    )
    parser.add_argument(
        "--output",
        metavar="FILE",
        help="write prompt to FILE instead of stdout",
    )

    args = parser.parse_args()

    if not args.task:
        parser.error("--task is required")

    if not args.project and not args.tasks_file:
        parser.error("one of --project or --tasks-file is required")

    tasks_path = find_tasks_file(args.project, args.tasks_file)

    if not tasks_path.exists():
        print(f"Error: TASKS.md not found: {tasks_path}", file=sys.stderr)
        sys.exit(1)

    tasks_md = tasks_path.read_text(encoding="utf-8")
    task = parse_task(tasks_md, args.task)

    if task is None:
        print(f"Error: task '{args.task}' not found in {tasks_path}", file=sys.stderr)
        sys.exit(1)

    project_dir = resolve_project_dir(args.project, tasks_path)
    prompt = build_prompt(task, project_dir, args.task, tasks_md, tasks_path)

    if args.output:
        output_path = Path(args.output)
        try:
            output_path.write_text(prompt, encoding="utf-8")
        except OSError as exc:
            print(
                f"Error: cannot write output file '{output_path}': {exc}",
                file=sys.stderr,
            )
            sys.exit(1)
        print(f"Prompt written to {output_path}")
    else:
        print(prompt, end="")


if __name__ == "__main__":
    main()
