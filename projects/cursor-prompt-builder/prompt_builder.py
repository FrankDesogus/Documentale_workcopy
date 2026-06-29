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

    for key, value in task.items():
        print(f"{key}: {value}")

    print("[prompt generation not yet implemented — coming in TASK-003]",
          file=sys.stderr)


if __name__ == "__main__":
    main()
