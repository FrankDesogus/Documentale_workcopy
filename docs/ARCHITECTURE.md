# Architettura della AI Software Station

## Principio centrale

Il repository è la fonte della verità.
Gli agenti AI devono lavorare su file, diff, test e commit, non su memoria volatile di chat.

## Ruoli principali

### Claude Code

- architettura;
- pianificazione;
- review tecnica;
- controllo dei guardrail tramite hook.

### Codex CLI

- decomposizione dei task;
- review indipendente;
- controllo qualità aggiuntivo.

### Cursor

- implementazione del codice;
- uso desktop per sviluppo interattivo;
- uso agent CLI per automazione controllata.

### Git

- branch per task;
- diff verificabili;
- commit solo dopo test e review.

### Test, lint e build

- gate obbligatorio;
- nessun task è completo senza verifica automatica.

### Modello locale

- opzionale;
- utile per riassunti, log e pre-review;
- non deve essere reviewer finale.
