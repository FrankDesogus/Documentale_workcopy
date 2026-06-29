#!/usr/bin/env python3
"""Generate a markdown report of the AI Software Station state."""

import argparse
import pathlib
import sys

__version__ = "0.1.0"


def scan_projects(station_dir) -> list:
    projects_dir = pathlib.Path(station_dir) / "projects"
    if not projects_dir.is_dir():
        return []
    return sorted(p.name for p in projects_dir.iterdir() if p.is_dir())


def scan_scripts(station_dir) -> list:
    scripts_dir = pathlib.Path(station_dir) / "scripts"
    if not scripts_dir.is_dir():
        return []
    return sorted(p.name for p in scripts_dir.iterdir() if p.is_file() and p.suffix == ".sh")


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="summary",
        description="Generate a markdown report of the AI Software Station state.",
    )
    parser.add_argument(
        "--version", action="version", version=f"%(prog)s {__version__}"
    )
    parser.parse_args()
    print("station-summary: not yet implemented — run TASK-003 next.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
