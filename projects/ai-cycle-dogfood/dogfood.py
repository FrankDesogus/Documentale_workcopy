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


def count_by_field(items: list, field: str) -> dict:
    """
    Riceve una lista di dizionari e il nome di un campo.
    Restituisce un dizionario che mappa ogni valore del campo al suo conteggio.

    Comportamenti da gestire:
    - lista vuota → ritorna {}
    - item senza il campo richiesto → conta sotto la chiave None
    - item con valore None per il campo → conta sotto la chiave None
      (stesso bucket dei campi mancanti)
    """
    result = {}
    for item in items:
        value = item.get(field)
        result[value] = result.get(value, 0) + 1
    return result


if __name__ == "__main__":
    import sys
    print("dogfood.py: run scripts/test.sh to test", file=sys.stderr)
    sys.exit(1)
