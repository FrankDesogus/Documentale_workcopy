#!/usr/bin/env python3
import argparse
import sys


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

    parser.parse_args()

    print("task-cli-pilot: not yet implemented", file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    main()
