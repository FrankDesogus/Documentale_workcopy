# Tasks

## In corso

| ID | Titolo | Agente | Branch | Note |
| -- | ------ | ------ | ------ | ---- |
|    |        |        |        |      |

## Backlog

| ID | Titolo | Priorità | Note |
| -- | ------ | -------- | ---- |

## Completati

| ID | Titolo | Commit | Data |
| -- | ------ | ------ | ---- |
| TASK-001 | Implementa summarize_status | — | 2026-06-29 |

---

## Dettaglio task

### TASK-001 — Implementa summarize_status — Cursor Agent

**Scope:** implementare la funzione `summarize_status(items)` in `dogfood.py`.

**Specifica:**

```python
def summarize_status(items: list) -> dict:
    """
    Riceve una lista di dizionari, ognuno con almeno la chiave "status".
    Restituisce un dizionario che mappa ogni valore di status al suo conteggio.

    Esempio:
        items = [{"status": "PASS"}, {"status": "FAIL"}, {"status": "PASS"}]
        # ritorna {"PASS": 2, "FAIL": 1}

    Comportamenti da gestire:
    - lista vuota → ritorna {}
    - item senza chiave "status" → ignorato (non conta)
    - valori None → ignorati
    """
```

**File da modificare:**
- `dogfood.py`: sostituire il `raise NotImplementedError` con l'implementazione reale.
- Non modificare `test_dogfood.py`.
- Non modificare `scripts/test.sh`.
- Non fare commit.

**Test:** eseguire `scripts/test.sh` dopo l'implementazione. Devono passare tutti.

**Criteri di completamento:**
- `python3 dogfood.py` non dà errori.
- `scripts/test.sh` esce con codice 0.

---

## Regole di aggiornamento

- Sposta un task da Backlog a "In corso" solo quando inizia il lavoro.
- Un solo task "In corso" per agente alla volta.
- Sposta in "Completati" solo dopo test e review positivi.
- Registra sempre il commit di riferimento nei task completati.
