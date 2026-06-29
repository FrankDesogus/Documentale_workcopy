#!/usr/bin/env python3
"""AI cycle dogfood project — validates ai-cycle.sh --run orchestration."""


def summarize_status(items: list) -> dict:
    result = {}
    for item in items:
        status = item.get("status")
        if status is None:
            continue
        result[status] = result.get(status, 0) + 1
    return result


if __name__ == "__main__":
    import sys
    print("dogfood.py: run scripts/test.sh to test", file=sys.stderr)
    sys.exit(1)
