# Handoff — riconciliazione con il lavoro svolto nella AI Software Station

Data: 2026-07-28. Da leggere subito dopo `git fetch`/`git pull` di questo branch.

## Contesto — due storie Git indipendenti, non fondere alla cieca

Questo branch (`task/documentale-pdf-ecn-integration`) è stato sviluppato in
una copia di lavoro dentro la AI Software Station, partita da un import
sanitizzato del progetto (commit `6c86432 Import Documentale workcopy`) e
sviluppata **in parallelo**, non in sequenza, rispetto a questo repository
(`documentale-new` / `main`).

**Le due storie Git non hanno un antenato comune** (`git merge-base main
task/documentale-pdf-ecn-integration` fallisce con "no merge base"). Un
`git merge --allow-unrelated-histories` produrrebbe conflitti su quasi ogni
file toccato da entrambe le parti, perché Git non ha un contenuto di
riferimento da cui fare un merge a tre vie — **non tentarlo**. La
riconciliazione va fatta **feature per feature**, confrontando manualmente
(`git show`/`diff` tra i commit specifici) come già fatto per il primo caso
qui sotto.

## Caso già confrontato e risolto: TASK-029 vs "AREA A" (allow_simple_ecn)

Entrambi i rami hanno implementato, indipendentemente, la stessa funzione:
un flag per documento che vieta l'ECN a flusso semplice (l'ECN standard
resta sempre permesso).

- **Qui** (`main`, TASK-029, commit `f4e4e40`): `Document.allows_simple_ecn`,
  modificabile dopo la creazione **solo da superuser o supervisor_demo**
  (`can_edit_simple_ecn_flag`), campo nascosto del tutto per autori/manager
  nel form metadati.
- **Nel branch Station** (TASK-037, `Document.allow_simple_ecn` — nome
  diverso, stessa semantica): inizialmente modificabile da chiunque avesse
  `can_edit_document_metadata` (autori/manager inclusi).

**Decisione presa (operatore, 2026-07-28): adottare la restrizione già
presente qui in TASK-029** — solo superuser/supervisor_demo dopo la
creazione, l'autore può comunque impostarlo in fase di creazione documento.
Il branch Station è stato **allineato** a questo comportamento (stesso
`can_edit_simple_ecn_flag`, stesso pattern di campo dinamico nel form).

**Nessuna azione richiesta qui per questo punto specifico** — la vostra
versione è già quella corretta/di riferimento. Restano solo due differenze
cosmetiche non funzionali se in futuro si volesse un'unica base di codice:
nome campo (`allows_simple_ecn` qui vs `allow_simple_ecn` nel branch
Station) e nome migrazione.

## Bug trovato durante il confronto, già corretto in ENTRAMBI i lati

Un commento Django `{# ... #}` multi-riga in `templates/documents/
new_document.html` non veniva nascosto da Django (limite reale e
verificato: il tag breve non supporta più righe, il testo veniva mostrato
sulla pagina). **Qui è già stato corretto** (parte dello stesso commit
TASK-029). Nel branch Station è stato corretto separatamente ora
(conversione a `{% comment %}...{% endcomment %}`). Nessuna azione
necessaria qui.

## Caso da confrontare con lo stesso metodo, non ancora fatto

**TASK-026** qui (`7a2ff6f`, "Confine full project history to a
permission-gated Archivio progetti section") sembra la **stessa identica
funzionalità** del TASK 2 sviluppato nel branch Station (spostare lo
storico snapshot/baseline del progetto fuori dal dettaglio ordinario, in
una nuova vista "Archivio progetti"/storico). Nomi diversi
(`archive_project_detail.html` qui vs `project_history.html` nel branch
Station) — **va confrontato con lo stesso metodo usato sopra per
TASK-029** prima di decidere quale versione tenere. Non ho fatto questo
confronto qui: è il prossimo passo naturale, con lo stesso approccio
(`git show <commit> --stat`, poi diff dei singoli file, poi decisione
esplicita all'operatore).

## Altro lavoro presente nel branch Station, assente qui

Non ancora confrontato con l'eventuale lavoro equivalente qui (se esiste).
Elenco solo per consapevolezza, senza dettaglio implementativo — chiedere
all'operatore quali di questi portare, con lo stesso metodo di confronto
prima di scrivere codice:

- Flusso PDF di rappresentazione / PDF approvato con registro firme visive
  (TASK-023→035): conversione automatica per formati semplici, upload
  manuale per gli altri, gate all'invio in approvazione con campo di
  caricamento inline quando manca il PDF, generazione PDF approvato con
  registro e firme visive dopo l'approvazione finale.
- Chiusura automatica dell'ECN generalizzata a standard **e** semplice
  (qui probabilmente esiste già solo per lo standard via TASK-025 "chiusura
  ECN solo con revisione collegata approvata" — da confrontare), con
  notifica email ai membri CCB effettivamente assegnati.
- Rinomina etichetta stato ECN "In Revisione CCB" → "In Valutazione CCB"
  (solo la label, nessun dato toccato).
- Documento di design (solo analisi, nessun codice) per permessi granulari
  cartelle/progetti — potrebbe essere utile come riferimento anche qui,
  indipendentemente da cosa si decide di implementare.

## Come procedere

1. Non fare merge automatico tra i due rami.
2. Per ogni punto della sezione "da confrontare": ripetere il metodo usato
   per TASK-029 — leggere entrambe le implementazioni, evidenziare le
   differenze concrete, proporre una decisione, aspettare conferma
   dall'operatore prima di scrivere codice.
3. Se si decide di portare qui una funzionalità assente, reimplementarla
   adattandola alla base di codice locale (non copiare/incollare alla
   cieca file da un repo con storia diversa).
