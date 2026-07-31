# Documentale

Sistema documentale interno per la gestione di documenti qualità e di progetto.

## Frontend CSS

Il progetto usa Tailwind CSS v3 compilato da `src/css/main.css` → `static/css/tailwind.css`.

### Setup (prima volta)
```bash
npm install
```

### Sviluppo (watch + rebuild automatico)
```bash
npm run dev
```

### Build produzione
```bash
npm run build
```

### Avvio Django
```bash
python manage.py runserver
```

Il file `static/css/tailwind.css` è committato nel repository.
Non è necessario avere Node.js in produzione.

## Deploy e stato progetto

Per deploy su server vedi `DEPLOY.md`. Per lo stato del progetto, il
checkpoint corrente e i comandi di avvio vedi `PROJECT_HANDOFF.md` e
`AI_CONTEXT.md`. Per test e comandi di sviluppo vedi `AGENTS.md`,
`CLAUDE.md` e `docs/ai/TESTING_STATUS.md`.
