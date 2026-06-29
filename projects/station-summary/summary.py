#!/usr/bin/env python3
"""Generate a markdown report of the AI Software Station state."""

import argparse
import datetime
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


def render_report(data: dict) -> str:
    projects = data.get("projects", [])
    scripts = data.get("scripts", [])
    lines = [
        "# AI Software Station — Report",
        "",
        f"Data generazione: {datetime.date.today().isoformat()}",
        "",
        "## Progetti",
        "",
    ]
    lines += [f"- {p}" for p in projects] if projects else ["_Nessun progetto rilevato._"]
    lines += [
        "",
        "## Helper",
        "",
    ]
    lines += [f"- {s}" for s in scripts] if scripts else ["_Nessun helper rilevato._"]
    lines += [
        "",
        f"**Stato:** {len(projects)} progetti, {len(scripts)} helper",
        "",
    ]
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="summary",
        description="Generate a markdown report of the AI Software Station state.",
    )
    parser.add_argument(
        "--version", action="version", version=f"%(prog)s {__version__}"
    )
    parser.add_argument(
        "--output", metavar="FILE", help="Write report to FILE instead of stdout."
    )
    args = parser.parse_args()

    station_dir = pathlib.Path(__file__).resolve().parent.parent.parent
    data = {
        "projects": scan_projects(station_dir),
        "scripts": scan_scripts(station_dir),
    }
    report = render_report(data)

    if args.output:
        try:
            with open(args.output, "w", encoding="utf-8") as fh:
                fh.write(report)
        except OSError as e:
            print(f"Error: {e}", file=sys.stderr)
            return 1
        print(f"Report written to {args.output}")
    else:
        print(report)
    return 0


if __name__ == "__main__":
    sys.exit(main())
