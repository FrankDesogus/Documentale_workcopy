# Tasks

## In corso

| ID | Titolo | Agente | Branch | Note |
| -- | ------ | ------ | ------ | ---- |
|    |        |        |        |      |

## Backlog

| ID | Titolo | Priorità | Note |
| -- | ------ | -------- | ---- |
| TASK-002 | Implementa count_by_field | media | Valida il formato TASKS standard |

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

### TASK-002 — Implementa count_by_field — Cursor Agent

#### Obiettivo

Aggiungere `count_by_field(items, field)` in `dogfood.py`: conta le occorrenze
dei valori di una chiave arbitraria, generalizzando `summarize_status`.

#### Scope

- Solo `dogfood.py`: nuova funzione `count_by_field`.
- Non modificare `test_dogfood.py` né `scripts/test.sh`.

#### File coinvolti

- `dogfood.py`

#### Acceptance criteria

- [ ] `count_by_field([{"k":"a"},{"k":"b"},{"k":"a"}], "k") == {"a": 2, "b": 1}`.
- [ ] Lista vuota → `{}`; item senza la chiave o con valore `None` → ignorato.

#### Test richiesti

- `./scripts/test.sh` esce con codice 0.

#### Guardrail

- No push, no merge, no reset --hard, no git clean.
- No dipendenze esterne, no installazioni, no rete, no commit.
- Non modificare file fuori scope.

#### Note operative

Task usato per validare il formato TASKS.template.md; l'implementazione può
essere svolta in un ciclo successivo.

---

## Regole di aggiornamento

- Sposta un task da Backlog a "In corso" solo quando inizia il lavoro.
- Un solo task "In corso" per agente alla volta.
- Sposta in "Completati" solo dopo test e review positivi.
- Registra sempre il commit di riferimento nei task completati.
