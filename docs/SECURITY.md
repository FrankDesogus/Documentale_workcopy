# Sicurezza e guardrail

## Principio generale

La stazione AI deve automatizzare il lavoro, non rimuovere il controllo umano.
Git, test, review e log sono i blocchi di sicurezza principali.

## Regole obbligatorie

- Nessun push automatico.
- Nessun merge automatico.
- Nessun lavoro diretto su `main` per task di sviluppo.
- Nessun comando distruttivo senza conferma umana.
- Nessun commit se i test falliscono.
- Nessun commit se la review è respinta.
- Nessun segreto versionato.
- Ogni ciclo automatico deve partire da working tree pulito.

## Comandi vietati o sensibili

Questi comandi devono essere bloccati o richiedere conferma esplicita:

- `rm -rf`
- `git reset --hard`
- `git clean -fdx`
- `git push --force`
- `chmod 777`
- uso abituale di `--yolo`
- uso di `danger-full-access`
- modifica di file `.env` o segreti

## Gestione dei segreti

Non devono mai essere versionati:

- file `.env`;
- API key;
- certificati;
- chiavi private;
- token di accesso;
- credenziali aziendali.

Le credenziali devono stare in variabili d’ambiente, secret manager o file locali ignorati da Git.

## Policy dati

Prima di usare agenti cloud su un repository, valutare se contiene codice aziendale, dati sensibili o informazioni riservate.
Per repository sensibili, valutare sandboxing, limitazioni cloud e uso di modelli locali solo per compiti leggeri.

## Regola per gli script futuri

Gli script di automazione non devono mai eseguire push, merge o comandi distruttivi senza conferma umana.
