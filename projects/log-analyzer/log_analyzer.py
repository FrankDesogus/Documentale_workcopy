#!/usr/bin/env python3
import argparse
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


def parse_tasks(tasks_path: Path) -> Dict[str, List[Dict[str, str]]]:
    result: Dict[str, List[Dict[str, str]]] = {
        "backlog": [],
        "in_corso": [],
        "completati": [],
    }
    # placeholder — implementato in TASK-002
    return result


def parse_last_run(run_log_path: Path) -> Optional[Dict[str, str]]:
    # placeholder — implementato in TASK-003
    return None


def parse_last_review(review_log_path: Path) -> Optional[Dict[str, str]]:
    # placeholder — implementato in TASK-003
    return None


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


def format_summary(summaries: List[Dict]) -> str:
    # placeholder — implementato in TASK-004
    lines = []
    for s in summaries:
        lines.append(f"== {s['name']} ==")
        t = s["tasks"]
        lines.append(
            f"Tasks: {len(t['completati'])} completati"
            f" | {len(t['in_corso'])} in corso"
            f" | {len(t['backlog'])} backlog"
        )
        lines.append("")
    return "\n".join(lines)


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
