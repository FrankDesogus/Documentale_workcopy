# Session handoff — 2026-07-29/30 (TASK-036 completo, tutte le 4 fasi)

> File non tracciato/non committato: creato per far ripartire una nuova
> finestra di contesto (o un agente diverso) senza dover ricostruire quanto
> verificato in questa sessione. Non sostituisce `PROJECT_HANDOFF.md`
> (fermo a giugno/luglio) né `docs/ai/TASKS.md` (fonte di verità sui task).

## Repo e branch

- Repo: `Ai-Station.git` (monorepo Station), non `Documentale_workcopy.git`
  (repo nidificato indipendente in `projects/Documentale_revisione/`, **da
  non toccare**).
- Path: `projects/documentale-workcopy` (minuscolo).
- Branch: `task/documentale-pdf-workflow`. HEAD `7e2ec76`. Working tree
  pulito (solo questo file, non tracciato per sua natura). **Nessun push
  eseguito**: 7 commit locali nuovi rispetto al checkpoint `33bef54`.

## Funzionalità completata in questa sessione: Applicabilità ECN obbligatoria

Tutte e 4 le fasi di TASK-036 sono complete, verificate indipendentemente
e committate. Spec e Esiti completi in `docs/ai/TASKS.md` (cerca
`TASK-036`, `TASK-036-2`, `TASK-036-3`, `TASK-036-4`).

| Fase | Cosa | Chi | Commit |
|---|---|---|---|
| TASK-036 | Modello, service, form, view, admin, template principali, CSS | Claude Code | `14fd0e7` |
| TASK-036-2 | Bugfix critico `ApplicabilityFieldsMixin` + fix ~66 chiamate test rotte | Claude Code | `36edeb8` |
| TASK-036-3 | Template rimanenti (dashboard, quality, configure_ccb, new_revision, ecn_my) + 3 email | Codex | `c18eeb4` |
| TASK-036-4 | Test dedicati (34 nuovi metodi, Parti A-G) | Codex | `b9a5797` |

Più 2 commit di solo fix cosmetico su `TASKS.md` (hash/attribuzione
riempiti dopo il fatto): `b2ef524`, `7e2ec76`.

**Ogni fase è stata verificata indipendentemente da Claude Code**
(diff letto riga per riga, suite ri-eseguita da zero), non solo sulla
base del report dell'agente esecutore.

**Bug reale scoperto e corretto in questa sessione** (TASK-036-2):
`ApplicabilityFieldsMixin` dichiarava i campi form a livello di classe;
essendo un mixin non-`forms.BaseForm`, il metaclass Django non li
raccoglieva mai in `base_fields` — l'obbligatorietà dell'applicabilità non
era realmente applicata lato server per nessuno dei 3 form. Corretto
iniettando i campi in `__init__` (stesso pattern di
`SanatoriaFieldsMixin`). C'è un test di regressione dedicato
(`test_regression_mixin_fields_are_injected_and_required_on_all_forms` in
`ecn/tests.py`, TASK-036-4).

**Stato finale verificato da Claude Code (ultima esecuzione)**:
`python manage.py check` → pulito. `makemigrations --check --dry-run` →
nessuna modifica mancante. `python manage.py test ecn documents approvals
notifications projects --keepdb -v1` → **1432/1432 PASS** (554s).
`accounts` non incluso in questo giro (non referenzia i service ECN,
verificato via grep) — se serve un numero definitivo su tutta la suite,
eseguilo separatamente.

## Nessun lavoro aperto su questa funzionalità

TASK-036/036-2/036-3/036-4 sono tutte in "Completati" in
`docs/ai/TASKS.md`. Non ci sono Parti mancanti rispetto alla spec
originale. Prossimi passi possibili (nessuno pianificato, da decidere con
l'operatore):
- Decidere se/quando mergiare `task/documentale-pdf-workflow` su `main`
  (contiene anche il lavoro precedente PDF/ECN semplice, non solo
  l'applicabilità — non è un merge "solo di questa feature").
- Eventuale push del branch (mai fatto in questa sessione).
- `PROJECT_HANDOFF.md` resta non aggiornato rispetto a tutto questo lavoro
  (non solo l'applicabilità — è indietro da prima di questa sessione).

## Ambiente locale — già pronto, non rifare

- `.venv` in `projects/documentale-workcopy/.venv` (Python 3.14.5).
- `node_modules`/`package-lock.json` presenti (gitignored), CSS già
  compilato in `static/css/tailwind.css`.
- `.env`: `DEBUG=True`, `DOCUMENTALE_DEMO_MODE=true`, sqlite3
  (`db.sqlite3`, non versionato, già migrato incluso `0006_applicability`).
- Dataset demo: `python manage.py demo_full --reset --no-email`. Login:
  `supervisor_demo` / `demo1234`.
- Server dev: verifica con `ps aux | grep runserver` prima di avviarne uno
  nuovo — in sessioni precedenti ne è rimasto uno su `127.0.0.1:8001`
  (non la 8000, occupata dall'altra copia).

## Regole permanenti del progetto (AGENTS.md / CLAUDE.md)

Non pushare mai in automatico, non fare merge o rebase, non modificare
`main` senza autorizzazione esplicita, non usare `git reset --hard`/
`restore`/`checkout --` distruttivi senza autorizzazione esplicita.

## Come riprendere in una nuova finestra di contesto

Punta a questo file e a `docs/ai/TASKS.md` (sezioni TASK-036*): branch,
venv, `.env`, migrazioni, dataset demo, `node_modules` e server sono già
pronti su disco.
