#!/usr/bin/env python3
import argparse
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional


def find_projects(projects_dir: Path) -> List[Path]:
    if not projects_dir.is_dir():
        return []
    return sorted(
        p for p in projects_dir.iterdir()
        if p.is_dir() and (p / "docs" / "ai" / "TASKS.md").exists()
    )


_SECTION_KEYS = {
    "backlog": "backlog",
    "in corso": "in_corso",
    "completati": "completati",
}


def _split_row(line: str) -> List[str]:
    line = line.strip()
    if not line.startswith("|") or not line.endswith("|"):
        return []
    return [c.strip() for c in line[1:-1].split("|")]


def _is_separator(cols: List[str]) -> bool:
    return bool(cols) and all(re.match(r"^-+$", c) for c in cols if c)


def parse_tasks(tasks_path: Path) -> Dict[str, List[Dict[str, str]]]:
    result: Dict[str, List[Dict[str, str]]] = {
        "backlog": [],
        "in_corso": [],
        "completati": [],
    }
    if not tasks_path.is_file():
        return result

    current_section: Optional[str] = None
    titolo_col: Optional[int] = None

    for line in tasks_path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped.startswith("## "):
            current_section = _SECTION_KEYS.get(stripped[3:].strip().lower())
            titolo_col = None
            continue

        if current_section is None:
            continue

        cols = _split_row(line)
        if not cols or _is_separator(cols):
            continue

        if cols[0].upper() == "ID":
            titolo_col = next(
                (i for i, h in enumerate(cols) if h.lower() == "titolo"),
                1 if len(cols) > 1 else None,
            )
            continue

        if not cols[0].startswith("TASK-"):
            continue

        title = ""
        if titolo_col is not None and titolo_col < len(cols):
            title = cols[titolo_col]
        result[current_section].append({"id": cols[0], "titolo": title})

    return result


_RUN_HEADER_RE = re.compile(
    r"^### Run — (\d{4}-\d{2}-\d{2})(?:\s+\d{2}:\d{2})?\s*—\s*(.*)$"
)
_REVIEW_HEADER_RE = re.compile(
    r"^### Review — (\d{4}-\d{2}-\d{2})(?:\s+\d{2}:\d{2})?\s*—\s*(.*)$"
)


def _normalize_test_outcome(text: str) -> str:
    upper = text.upper()
    if "FAIL" in upper or "FALLIT" in upper:
        return "FAIL"
    if "PASS" in upper or "PASSATI" in upper:
        return "PASS"
    return text.strip()


def _parse_run_body(lines: List[str]) -> Dict[str, str]:
    entry: Dict[str, str] = {}
    in_code = False
    code_lines: List[str] = []
    capture_esito = False

    for line in lines:
        stripped = line.strip()
        agente_m = re.match(r"^\*\*Agente:\*\*\s*(.+)$", stripped)
        if agente_m:
            entry["agente"] = agente_m.group(1).strip()
            continue
        task_m = re.match(r"^\*\*Task:\*\*\s*(.+)$", stripped)
        if task_m:
            task_text = task_m.group(1).strip()
            id_m = re.search(r"(TASK-\d+)", task_text)
            entry["task"] = id_m.group(1) if id_m else task_text
            continue
        if "**Esito test" in stripped and "scripts/test.sh" in stripped:
            capture_esito = True
            continue
        if capture_esito:
            if not in_code:
                if stripped.startswith("```"):
                    in_code = True
                continue
            if stripped == "```":
                entry["esito_test"] = _normalize_test_outcome("\n".join(code_lines))
                capture_esito = False
                in_code = False
                code_lines = []
                continue
            code_lines.append(line)

    if capture_esito and code_lines:
        entry["esito_test"] = _normalize_test_outcome("\n".join(code_lines))

    return entry


def _parse_review_body(lines: List[str]) -> Dict[str, str]:
    entry: Dict[str, str] = {}
    for line in lines:
        stripped = line.strip()
        reviewer_m = re.match(r"^\*\*Reviewer:\*\*\s*(.+)$", stripped)
        if reviewer_m:
            entry["reviewer"] = reviewer_m.group(1).strip()
            continue
        esito_m = re.match(r"^\*\*Esito:\*\*\s*(.+)$", stripped)
        if esito_m:
            entry["esito"] = esito_m.group(1).strip()
    return entry


def _parse_last_log_entry(
    log_path: Path,
    header_re: re.Pattern,
    body_parser,
) -> Optional[Dict[str, str]]:
    if not log_path.is_file():
        return None

    last: Optional[Dict[str, str]] = None
    current_date: Optional[str] = None
    section_lines: List[str] = []

    def flush() -> None:
        nonlocal last
        if current_date is None:
            return
        entry = body_parser(section_lines)
        entry["data"] = current_date
        last = entry

    for line in log_path.read_text(encoding="utf-8").splitlines():
        match = header_re.match(line.strip())
        if match:
            flush()
            current_date = match.group(1)
            section_lines = []
            continue
        if current_date is not None:
            section_lines.append(line)

    flush()
    return last


def parse_last_run(run_log_path: Path) -> Optional[Dict[str, str]]:
    return _parse_last_log_entry(run_log_path, _RUN_HEADER_RE, _parse_run_body)


def parse_last_review(review_log_path: Path) -> Optional[Dict[str, str]]:
    return _parse_last_log_entry(
        review_log_path, _REVIEW_HEADER_RE, _parse_review_body
    )


def summarize_project(project_dir: Path) -> Dict:
    ai_dir = project_dir / "docs" / "ai"
    tasks = parse_tasks(ai_dir / "TASKS.md")
    last_run = parse_last_run(ai_dir / "RUN_LOG.md")
    last_review = parse_last_review(ai_dir / "REVIEW_LOG.md")
    return {
        "name": project_dir.name,
        "tasks": tasks,
        "last_run": last_run,
        "last_review": last_review,
    }


def _format_last_run(last_run: Optional[Dict[str, str]]) -> str:
    if not last_run:
        return "Ultimo run: nessuno"
    parts = [
        last_run.get("data", "—"),
        last_run.get("task", "—"),
    ]
    agente = last_run.get("agente")
    esito = last_run.get("esito_test")
    line = f"Ultimo run: {parts[0]} — {parts[1]}"
    if agente:
        line += f" — Agente: {agente}"
    if esito:
        line += f" — Esito: {esito}"
    return line


def _format_last_review(last_review: Optional[Dict[str, str]]) -> str:
    if not last_review:
        return "Ultima review: nessuna"
    line = f"Ultima review: {last_review.get('data', '—')}"
    reviewer = last_review.get("reviewer")
    esito = last_review.get("esito")
    if reviewer:
        line += f" — Reviewer: {reviewer}"
    if esito:
        line += f" — Esito: {esito}"
    return line


def format_summary(summaries: List[Dict]) -> str:
    blocks: List[str] = []
    for s in summaries:
        t = s["tasks"]
        block = [
            f"== {s['name']} ==",
            (
                f"Tasks: {len(t['completati'])} completati"
                f" | {len(t['in_corso'])} in corso"
                f" | {len(t['backlog'])} backlog"
            ),
            _format_last_run(s.get("last_run")),
            _format_last_review(s.get("last_review")),
        ]
        blocks.append("\n".join(block))
    return "\n\n".join(blocks) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="log-analyzer",
        description="Analyze AI station project logs and summarize task status.",
        add_help=True,
    )
    parser.add_argument(
        "--version",
        action="version",
        version="log-analyzer 0.1.0",
    )
    parser.add_argument(
        "--projects-dir",
        metavar="DIR",
        default="projects",
        help="root directory containing projects (default: projects/)",
    )
    parser.add_argument(
        "--project",
        metavar="NAME",
        help="analyze only this project",
    )
    parser.add_argument(
        "--output",
        metavar="FILE",
        help="write output to FILE instead of stdout",
    )

    args = parser.parse_args()

    projects_dir = Path(args.projects_dir)

    if args.project:
        target = projects_dir / args.project
        if not (target / "docs" / "ai" / "TASKS.md").exists():
            print(
                f"Error: project '{args.project}' not found or missing docs/ai/TASKS.md",
                file=sys.stderr,
            )
            sys.exit(1)
        project_dirs = [target]
    else:
        project_dirs = find_projects(projects_dir)
        if not project_dirs:
            print(
                f"Error: no projects found in '{projects_dir}'",
                file=sys.stderr,
            )
            sys.exit(1)

    summaries = [summarize_project(p) for p in project_dirs]
    output = format_summary(summaries)

    if args.output:
        output_path = Path(args.output)
        try:
            output_path.write_text(output, encoding="utf-8")
        except OSError as exc:
            print(
                f"Error: cannot write output file '{output_path}': {exc}",
                file=sys.stderr,
            )
            sys.exit(1)
        print(f"Summary written to {output_path}")
    else:
        print(output, end="")


if __name__ == "__main__":
    main()
