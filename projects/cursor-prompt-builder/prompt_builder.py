#!/usr/bin/env python3
import argparse
import sys


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

    print("cursor-prompt-builder: not yet implemented", file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    main()
