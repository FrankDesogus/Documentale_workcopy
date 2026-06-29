# AI Software Station

Stazione locale per sviluppo software assistito da AI.

## Obiettivo

- usare Claude Code per architettura, pianificazione e review;
- usare Codex/OpenAI per decomposizione dei task e review indipendente;
- usare Cursor come ambiente di implementazione;
- usare Git, test, lint, diff e log come fonte della verità;
- evitare automazioni fragili basate su copia-incolla tra chat.

## Documentazione

- [AI Workflow](docs/AI_WORKFLOW.md) — ciclo operativo, ruoli degli agenti, guardrail
- [Next Steps](docs/NEXT_STEPS.md) — decisioni aperte e roadmap immediata
- [Architecture](docs/ARCHITECTURE.md) — struttura della stazione
- [Security](docs/SECURITY.md) — guardrail di sicurezza
- [Runbook](docs/RUNBOOK.md) — operazioni comuni

## Regola principale

Il repository è la fonte della verità.
Ogni decisione importante deve finire in file versionati.

## Livelli operativi

1. Manuale / semi-guidato.
2. Multi-step controllato.
3. Quasi autonomo solo con guardrail forti.

## Guardrail base

- Nessun push automatico.
- Nessun merge automatico.
- Nessun comando distruttivo senza conferma umana.
- Nessun commit se test o review falliscono.
- Nessun segreto versionato.
