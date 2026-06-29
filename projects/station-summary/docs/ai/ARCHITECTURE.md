# Architettura

## Contesto

`station-summary` è un tool CLI Python che ispeziona il filesystem locale
della AI Software Station e produce un report markdown dello stato corrente.
Non dipende da API esterne né da database.

## Componenti principali

| Componente | Responsabilità |
| ---------- | -------------- |
| `summary.py` | Entry point CLI: parsing argomenti, orchestrazione, output |
| Rilevamento progetti | Scansione di `projects/` per ottenere la lista dei progetti |
| Rilevamento helper | Scansione di `scripts/` per ottenere la lista degli helper |
| Generatore report | Composizione del report markdown da dati rilevati |

## Flusso dei dati

```
argv
  → argparse (--help, --version, --output, --station-dir)
    → scan projects/
    → scan scripts/
      → build report dict
        → render markdown
          → stdout o file
```

## Dipendenze esterne

| Dipendenza | Versione | Motivo |
| ---------- | -------- | ------ |
| Python stdlib | ≥3.8 | pathlib, argparse, sys |

## Decisioni rilevanti

Vedi [`DECISIONS.md`](DECISIONS.md).

## Diagramma

```
summary.py
  ├── scan_projects(station_dir)  →  [project names]
  ├── scan_scripts(station_dir)   →  [script names]
  └── render_report(data)         →  markdown string
```

## Data ultima revisione

2026-06-29
