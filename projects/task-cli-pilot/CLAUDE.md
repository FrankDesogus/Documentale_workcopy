# CLAUDE.md

> Le regole operative principali sono in [`AGENTS.md`](AGENTS.md).
> Leggi prima quello. Questo file contiene solo note specifiche per Claude Code.

## Ruolo di Claude Code in questo progetto

- Architettura e pianificazione tecnica.
- Review del codice implementato da Cursor o Codex.
- Verifica dei guardrail e delle regole operative.
- Risposta a domande tecniche sul progetto.

## Comportamento atteso

- Prima di qualsiasi operazione: eseguire `git status`.
- Proporre le modifiche e attendere conferma per operazioni rischiose o irreversibili.
- Preferire edit puntuali a riscritture di file interi.
- Non aggiungere feature non richieste.
- Non refactorare codice fuori scope del task corrente.
- Non aggiungere commenti che spiegano il codice: il codice deve parlare da solo.
- Non creare file di documentazione non richiesti.

## Comandi utili per questo progetto

```bash
# Verifica ambiente
./scripts/checks/check-environment.sh

# Esegui i test
./scripts/test.sh

# Stato del repository
git status --short
git log --oneline --decorate --max-count=8
```

## Cosa non fare

- Non usare `--yolo`.
- Non fare push o merge automatici.
- Non modificare `AGENTS.md` senza istruzione esplicita.
- Non installare dipendenze senza conferma.
- Non committare senza aver eseguito `scripts/test.sh`.
