#!/usr/bin/env python3
"""Generate a markdown report of the AI Software Station state."""

import argparse
import sys

__version__ = "0.1.0"


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="summary",
        description="Generate a markdown report of the AI Software Station state.",
    )
    parser.add_argument(
        "--version", action="version", version=f"%(prog)s {__version__}"
    )
    parser.parse_args()
    print("station-summary: not yet implemented — run TASK-002 next.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
