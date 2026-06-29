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
        try:
            return json.load(f)
        except json.JSONDecodeError as exc:
            print(f"Error: tasks.json is corrupt ({exc}).", file=sys.stderr)
            sys.exit(1)


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


def cmd_done(tasks: List[Dict[str, Any]], task_id: int) -> bool:
    for task in tasks:
        if task["id"] == task_id:
            task["done"] = True
            print(f"Task #{task_id} marked as done.")
            return True
    print(f"Error: task #{task_id} not found.", file=sys.stderr)
    return False


def cmd_clear(tasks: List[Dict[str, Any]]) -> None:
    tasks.clear()
    print("All tasks cleared.")


def cmd_delete(tasks: List[Dict[str, Any]], task_id: int) -> bool:
    for i, task in enumerate(tasks):
        if task["id"] == task_id:
            tasks.pop(i)
            print(f"Task #{task_id} deleted.")
            return True
    print(f"Error: task #{task_id} not found.", file=sys.stderr)
    return False


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

    tasks = load_tasks(TASKS_FILE)

    if args.command == "add":
        cmd_add(tasks, args.text)
        save_tasks(TASKS_FILE, tasks)
    elif args.command == "list":
        cmd_list(tasks)
    elif args.command == "done":
        if not cmd_done(tasks, args.id):
            sys.exit(1)
        save_tasks(TASKS_FILE, tasks)
    elif args.command == "delete":
        if not cmd_delete(tasks, args.id):
            sys.exit(1)
        save_tasks(TASKS_FILE, tasks)
    elif args.command == "clear":
        cmd_clear(tasks)
        save_tasks(TASKS_FILE, tasks)


if __name__ == "__main__":
    main()
