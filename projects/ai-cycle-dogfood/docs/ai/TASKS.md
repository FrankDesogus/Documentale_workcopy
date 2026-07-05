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
| TASK-002 | Implementa count_by_field | <da aggiornare col commit> | 2026-07-05 |

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
dei valori di un campo arbitrario, generalizzando `summarize_status`.

#### Scope

- Solo `dogfood.py`: nuova funzione `count_by_field`.
- Aggiungere/aggiornare test in `test_dogfood.py` per la nuova funzione (senza
  toccare i test esistenti di `summarize_status`).
- Non modificare `scripts/test.sh`.

#### File coinvolti

- `dogfood.py`
- `test_dogfood.py`

#### Specifica

```python
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
```

#### Acceptance criteria

- [ ] `count_by_field([{"k":"a"},{"k":"b"},{"k":"a"}], "k") == {"a": 2, "b": 1}`.
- [ ] Lista vuota → `{}`.
- [ ] Item senza la chiave `field` → conteggiato sotto `None`.
- [ ] Item con valore `None` per `field` → conteggiato sotto `None` (stesso
      bucket dei campi mancanti, non ignorato).
- [ ] Nessuna dipendenza esterna.

#### Test richiesti

- `./scripts/test.sh` esce con codice 0.
- Nuovi test in `test_dogfood.py` per `count_by_field` che coprono i casi sopra.

#### Guardrail

- No push, no merge, no reset --hard, no git clean.
- No dipendenze esterne, no installazioni, no rete, no commit.
- Non modificare file fuori scope.

#### Note operative

Comportamento deliberatamente diverso da `summarize_status` (che ignora
None/campo mancante): qui None/mancante sono un bucket valido, per validare
che il workflow gestisca una spec puntuale e non solo un pattern ricalcato.

---

## Regole di aggiornamento

- Sposta un task da Backlog a "In corso" solo quando inizia il lavoro.
- Un solo task "In corso" per agente alla volta.
- Sposta in "Completati" solo dopo test e review positivi.
- Registra sempre il commit di riferimento nei task completati.
