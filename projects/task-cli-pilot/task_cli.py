#!/usr/bin/env python3
import argparse
import json
import sys
from pathlib import Path
from typing import Any, Dict, List

TASKS_FILE = Path("tasks.json")


def load_tasks(path: Path) -> List[Dict[str, Any]]:
    if not path.exists():
        return []
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def save_tasks(path: Path, tasks: List[Dict[str, Any]]) -> None:
    with path.open("w", encoding="utf-8") as f:
        json.dump(tasks, f, indent=2)
        f.write("\n")


def cmd_add(tasks: List[Dict[str, Any]], text: str) -> int:
    if tasks:
        new_id = max(task["id"] for task in tasks) + 1
    else:
        new_id = 1
    tasks.append({"id": new_id, "text": text, "done": False})
    print(f"Added task #{new_id}: {text}")
    return new_id


def cmd_list(tasks: List[Dict[str, Any]]) -> None:
    if not tasks:
        print("No tasks.")
        return
    for task in tasks:
        checkbox = "[x]" if task.get("done") else "[ ]"
        print(f"{checkbox} {task['id']} — {task['text']}")


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="task-cli-pilot",
        description="Task manager CLI — AI Software Station pilot",
        add_help=True,
    )
    parser.add_argument(
        "--version",
        action="version",
        version="task-cli-pilot 0.1.0",
    )

    subparsers = parser.add_subparsers(dest="command")

    add_p = subparsers.add_parser("add", help="Add a new task")
    add_p.add_argument("text", help="Task description")

    subparsers.add_parser("list", help="List all tasks")

    done_p = subparsers.add_parser("done", help="Mark a task as done")
    done_p.add_argument("id", type=int, help="Task ID")

    delete_p = subparsers.add_parser("delete", help="Delete a task")
    delete_p.add_argument("id", type=int, help="Task ID")

    subparsers.add_parser("clear", help="Clear all tasks")

    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        sys.exit(1)

    if args.command in ("add", "list"):
        tasks = load_tasks(TASKS_FILE)
        if args.command == "add":
            cmd_add(tasks, args.text)
            save_tasks(TASKS_FILE, tasks)
        else:
            cmd_list(tasks)
        sys.exit(0)

    print("task-cli-pilot: not yet implemented", file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    main()
