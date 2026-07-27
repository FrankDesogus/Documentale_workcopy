# Decisione tecnica — Sorgente / PDF di rappresentazione / PDF approvato

Data: 2026-07-27
Autore: Claude Code (coordinatore Station)
Stato: proposta per TASK-031→TASK-039 (vedi `docs/ai/TASKS.md`)

## 1. Stato di partenza verificato

- **Formati sorgente ammessi oggi**: nessuno. `DocumentFile`/`DocumentVersion.file` e
  `documents/forms.py` (`file = forms.FileField(required=False, ...)`) non hanno
  alcun `FileExtensionValidator` né whitelist di estensioni: il sistema accetta
  qualunque file. Non introduco una whitelist di upload (fuori scope): la policy
  PDF deve quindi funzionare per estensione/mime **osservata**, non per una lista
  pre-approvata.
- **Concetto riutilizzabile già esistente**: `ApprovalRequestAttachment` con
  `AttachmentType.SIGNATURE_TEMPLATE` ("Modello da firmare") — upload manuale
  opzionale di un file arbitrario in `submit_for_approval`, non tipizzato PDF, non
  legato da un checksum al sorgente, senza conferma né congelamento. Questa
  feature va **sostituita/assorbita** dal nuovo concetto di "PDF di
  rappresentazione", non affiancata: unico punto di verità per il file mostrato
  agli approvatori.
- **Ambiente locale (questa macchina, sviluppo/demo Claude Code)**: Linux,
  `/usr/bin/soffice` e `/usr/bin/libreoffice` presenti. **Non rappresentativo
  dell'ambiente reale**: `CLAUDE.md` dichiara sviluppo su **Windows** con
  PyCharm; il deploy di produzione è "PostgreSQL compatibile per futuro
  deploy" ma l'OS del server non è specificato in `docs/ai/DEPLOYMENT_READINESS.md`.
  **Assunzione esplicita**: non si può assumere che LibreOffice sia installato
  né in sviluppo (Windows) né in produzione. La policy deve rilevare la
  disponibilità a runtime (`shutil.which`), mai assumerla dall'estensione.
- **Dipendenze Python attuali** (`requirements.txt`): Django, gunicorn, psycopg,
  psycopg-binary, python-decouple, sqlparse, tzdata, asgiref. Nessuna libreria
  di manipolazione PDF/immagini. `pillow` è stata **rimossa deliberatamente**
  in TASK-009 (`docs/ai/DEPENDENCIES_AUDIT.md` §6/§"pillow — dubbia") perché
  non referenziata nel codice, con rischio esplicitamente annotato: *"rischio
  se in futuro si aggiungono thumbnail/anteprima immagini o si convertono
  campi in ImageField senza reintrodurre Pillow"*. Quel futuro è ora: la
  reintroduco per la validazione delle firme PNG (dimensioni, modalità,
  trasparenza, file corrotto). Non è una libreria nuova mai vista nel progetto,
  è la stessa già rimossa con motivazione ora superata da un requisito reale.

## 2. Fonti tecniche consultate

Ambiente sandboxato senza accesso di rete per la ricerca esterna in questa
sessione. Non ho potuto consultare la documentazione ufficiale online in
tempo reale; le affermazioni sottostanti si basano su conoscenza consolidata
di questi strumenti (ampiamente documentata) più verifica locale diretta
(`which`, `pip list`, lettura codice). Punti che richiedono verifica manuale
successiva sono segnalati esplicitamente.

- **LibreOffice headless (`soffice --headless --convert-to pdf`)**: percorso
  di conversione documentato dal progetto The Document Foundation, uso comune
  in backend server per conversione batch docx/odt/xlsx/pptx → PDF. Verificato
  localmente: binario presente su questa macchina (`/usr/bin/soffice`).
  **Da verificare manualmente**: presenza su Windows di sviluppo e sul server
  di produzione reale; comportamento di font mancanti; tempo di conversione
  sotto carico.
- **reportlab**: libreria Python pura per generazione PDF (testo, immagini,
  form semplici), nessuna dipendenza da binari esterni, licenza BSD-style
  (edizione open source), attivamente mantenuta, ampiamente usata in Django
  per generare PDF programmaticamente. Adatta sia per "PDF di rappresentazione
  affidabile" di sorgenti testuali/immagine sia per costruire la pagina finale
  del PDF approvato.
- **pypdf**: libreria pura Python per manipolare PDF esistenti (unire pagine,
  leggere metadati) — necessaria per "prendere il PDF di rappresentazione
  congelato + aggiungere una pagina" senza toccare le pagine originali.
  Nessuna dipendenza binaria, licenza permissiva, attivamente mantenuta
  (fork moderno di PyPDF2).
- **Pillow**: già discussa in `DEPENDENCIES_AUDIT.md`, licenza permissiva
  (HPND), standard de facto per validazione/manipolazione immagini in Python/
  Django.

Nessuno strumento cloud o commerciale è stato considerato necessario: la
combinazione reportlab + pypdf + Pillow (tutte pure-Python, nessun servizio
esterno, nessun costo di licenza, footprint contenuto) copre l'intera
generazione documentale richiesta senza dipendere da LibreOffice per il
percorso "affidabile". LibreOffice resta un **potenziamento opzionale**
rilevato a runtime, mai un requisito.

## 3. Classificazione delle strategie (non delle estensioni)

Il servizio centrale (`documents/pdf_policy.py`, TASK-031) espone
`get_pdf_strategy(document_file) -> PdfStrategyDecision` con
`strategy`, `converter`, `requires_confirmation`, `reason`,
`error` opzionale. Le strategie:

| Strategia | Quando | Conferma autore | Note |
|---|---|---|---|
| `NATIVE_PDF` | Il sorgente è già un PDF (estensione `.pdf` + verifica header `%PDF-`) | No (è il file stesso) | `representation_pdf` = stesso `DocumentFile` del sorgente, nessuna copia |
| `AUTO_RELIABLE` | `.txt` (reportlab, impaginazione testuale deterministica) o immagini raster comuni `.png/.jpg/.jpeg` (una pagina, nessuna ambiguità di layout) | No, ma l'autore può comunque rivedere l'anteprima | Nessun binario esterno richiesto: funziona identico ovunque giri Python |
| `AUTO_UNCERTAIN` | `.docx/.odt/.xlsx/.ods/.pptx/.odp` **e** LibreOffice rilevato (`shutil.which('soffice')`) | **Sì, obbligatoria** | Fedeltà non garantita: font, macro, impaginazione possono differire dal file originale aperto nel software nativo |
| `MANUAL_REQUIRED` | Formati noti ma intrinsecamente rischiosi da convertire automaticamente (CAD/DWG, formati con macro come `.docm/.xlsm`, PSD, formati desktop-publishing) **oppure** formato Office valido ma LibreOffice non disponibile in questo ambiente | — | Motivo mostrato esplicitamente ("conversione non disponibile in questo ambiente" vs "formato troppo rischioso per l'automazione") |
| `UNSUPPORTED` | Estensione sconosciuta/non gestita dalla policy | — | Dato che non esiste whitelist di upload, questo è il fallback di sicurezza: mai un crash, sempre "carica tu il PDF" |
| `CONVERSION_FAILED` | Esito di un tentativo reale di conversione (non della sola policy): il convertitore individuato ha fallito (processo non-zero, output vuoto/corrotto) | — | Errore diagnostico salvato per l'autore/admin, fallback immediato a upload manuale |

`requires_confirmation` è quindi **non** "tutti i PDF generati", ma
specificamente le conversioni `AUTO_UNCERTAIN` (fedeltà non garantita per
costruzione). Le conversioni `AUTO_RELIABLE` sono deterministiche e non hanno
libertà di layout da perdere; il PDF nativo non è nemmeno una conversione. Un
PDF caricato manualmente dall'autore è considerato "confermato" nel momento
stesso del caricamento (l'autore lo ha scelto e caricato consapevolmente):
non richiede un secondo passo di conferma esplicita, ma resta comunque
soggetto allo stesso congelamento/checksum di ogni altro rappresentazione.

## 4. Quando chiedere il PDF all'autore

Tre momenti distinti, mai un blocco unico:

1. **Avviso anticipato in bozza** (già alla creazione/modifica): il sistema
   calcola la strategia sul sorgente appena caricato e mostra subito lo stato
   (es. "conversione automatica non disponibile in questo ambiente: sarà
   necessario caricare un PDF prima dell'invio"). Non blocca il salvataggio
   della bozza.
2. **Richiesta di caricamento durante la preparazione**: se la strategia è
   `MANUAL_REQUIRED`/`UNSUPPORTED`/`CONVERSION_FAILED`, la UI della bozza
   mostra un pulsante di upload PDF dedicato, sempre disponibile (anche per
   `AUTO_RELIABLE`/`AUTO_UNCERTAIN`, come sostituzione volontaria della
   conversione automatica).
3. **Blocco obbligatorio all'invio** (TASK-035): `submit_version_for_approval`
   rifiuta se manca `representation_pdf`, se è disallineato dal sorgente
   corrente (checksum), o se richiede conferma non ancora data.

## 5. Criterio di conferma

- Conferma obbligatoria **solo** per `AUTO_UNCERTAIN` (vedi tabella sopra).
- PDF nativo (`NATIVE_PDF`) e conversioni `AUTO_RELIABLE`: nessuna conferma
  bloccante richiesta per l'invio, ma l'autore può comunque visualizzare/
  confermare volontariamente (stesso meccanismo, semplicemente non
  obbligatorio).
- PDF caricato manualmente: confermato implicitamente al caricamento.
- La conferma **non è una seconda approvazione**: è una dichiarazione
  dell'autore ("questo PDF rappresenta correttamente il sorgente"),
  registrata come `representation_pdf_confirmed_by`/`_at` su
  `DocumentVersion`.
- **Invalidazione**: qualunque sostituzione del sorgente (`version.file`
  cambia FK) invalida atomicamente `representation_pdf`,
  `representation_pdf_confirmed_by/_at` e impedisce l'invio finché non si
  ripete l'intero ciclo (analisi → conversione/upload → eventuale conferma).

## 6. Modello dati (sintesi, dettaglio in TASK-032)

Riuso di `DocumentFile` esistente (aggiungendo un campo `kind`:
`source`/`representation_pdf`/`approved_pdf`) invece di nuovi modelli file
paralleli — stesso schema di hash/mime/size già validato in produzione.
Nuovi campi su `DocumentVersion` per lo stato del ciclo PDF (rappresentazione,
conferma, PDF approvato, stato generazione). Nuovo modello `UserSignature`
(app `accounts`, oggi vuota) con righe immutabili (stesso pattern di
`DocumentFile`: una nuova riga per ogni sostituzione, mai edit in place) e
`is_active` per la firma corrente. Snapshot storico su `ApprovalDecision`:
`signature_used` (FK a `UserSignature`, immutabile per costruzione) +
`signature_display_name` (stringa congelata al momento della decisione,
perché `approver` resta un FK live a `User` e il nome visualizzato potrebbe
cambiare in futuro). Il progetto non modella "ruolo/qualifica" per utente
(nessun campo del genere in `accounts.models`, oggi 3 righe): il registro
userà l'etichetta fissa "Approvatore" per questo workflow — limite
esplicito, non un'invenzione di dominio.

## 7. Fallback e limiti dichiarati

- Se LibreOffice non è disponibile: nessun tentativo automatico per i formati
  Office, sempre `MANUAL_REQUIRED` con motivo esplicito — l'architettura resta
  la stessa (basta che `soffice` compaia nel `PATH` del server) senza
  modifiche al codice quando l'azienda deciderà di installarlo.
- Nessuna coda/worker asincrono introdotto: la generazione (conversione bozza,
  PDF approvato) gira in-request. Proporzionato al volume di una piccola
  azienda; se in futuro servisse asincronia, il servizio è già isolato
  (`documents/pdf_policy.py`, `documents/pdf_rendition.py`,
  `documents/approved_pdf.py`) e richiamabile da un task in background senza
  riscrivere la logica.
- Fedeltà delle conversioni Office non verificabile automaticamente al 100%:
  da qui l'obbligo di conferma umana per quel livello, non un test automatico
  di "somiglianza visiva".
