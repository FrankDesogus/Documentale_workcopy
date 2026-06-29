# Architettura — demo-minimal

## Contesto

Progetto demo per validare il ciclo AI Software Station. Non ha un'architettura
reale: la struttura è volutamente minimale.

## Componenti principali

| Componente      | Responsabilità                              |
| --------------- | ------------------------------------------- |
| `cli.py`        | Entry point CLI, stampa il messaggio        |
| `scripts/test.sh` | Esegue `cli.py` e verifica l'output      |

## Flusso dei dati

```
operatore → python cli.py → stdout: "Hello from demo-minimal." → exit 0
test      → subprocess(cli.py) → assert output → exit 0 / exit 1
```

## Dipendenze esterne

Nessuna. Python standard library only.

## Decisioni rilevanti

Vedi [`DECISIONS.md`](DECISIONS.md).

## Data ultima revisione

2026-06-29
