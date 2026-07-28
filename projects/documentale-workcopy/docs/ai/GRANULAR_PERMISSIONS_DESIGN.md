# Permessi granulari per cartelle e progetti — documento di decisione tecnica

**Stato: analisi e proposta, NESSUN CODICE SCRITTO. In attesa di approvazione.**

Data: 2026-07-28. Branch: `task/documentale-pdf-ecn-integration` (worktree di analisi).

Riferimenti preesistenti che questo documento estende, non ripete:
`docs/ai/PERMISSIONS_AUDIT.md` (TASK-006/007, 2026-07-06/08),
`docs/ai/ECN_PERMISSIONS_AUDIT.md` (TASK-013/014, 2026-07-08).

---

## 1. Modello autorizzativo corrente

Il sistema ha **già, oggi, due meccanismi paralleli e non sincronizzati**:

1. **`FolderPermissionGrant`** (`projects/models.py:80-203`) — il meccanismo "modulare":
   per-cartella, per-utente-o-gruppo, per singolo `permission_code` (12 codici:
   `read_published`, `view_history`, `view_obsolete_documents`, `view_projects`,
   `view_folder_ecns`, `create_draft`, `submit_for_approval`,
   `eligible_document_approver`, `manage_rejected_drafts`,
   `manage_project_documents`, `request_ecn`, `manage_folder`), con `effect`
   (ALLOW/DENY), `inherit_to_children` ed `expires_at`.
2. **`ProjectFolderMembership`** (`projects/models.py:206-249`) — il meccanismo
   "legacy": un ruolo (`reader/author/approver/auditor/manager`) per utente per
   cartella, tradotto a runtime in un insieme di `permission_code` tramite
   `_LEGACY_ROLE_PERMISSIONS` (`projects/resolver.py:40-84`), consultato **solo
   se** nessun `FolderPermissionGrant` decide lungo la catena di cartelle **e**
   il chiamante passa `include_legacy_fallback=True` (lo fanno, oggi, tutti i
   call site di produzione).

L'algoritmo di risoluzione (`PermissionResolver._resolve`,
`projects/resolver.py:197-255`) è **già** esattamente ciò che TASK 3 chiede di
progettare da zero: cammina dalla cartella corrente verso la radice
(estraendo gli antenati dal `path` materializzato), applica ad ogni livello la
precedenza `user_deny > user_allow > group_deny > group_allow`, e il **primo
livello che decide vince** (la cartella più specifica sovrascrive quelle più
generali, non c'è unione/merge tra livelli). Solo se nessun livello modulare
decide interviene il fallback legacy, e **solo sulla cartella esatta**, senza
risalire agli antenati.

Questo significa che l'infrastruttura dati e l'algoritmo di precedenza/
ereditarietà **esistono già e sono in produzione** dietro `PermissionResolver`.
Ciò che manca — e che è il vero oggetto di questo task — non è un nuovo
modello dati, ma:

- nessuna UI applicativa per creare/modificare grant (solo Django Admin, non
  gated da permessi applicativi — vedi §2);
- nessun collegamento a livello `Project` (il modello è cartella-centrico;
  un progetto eredita i permessi della sua `root_folder`, ma non esiste un
  concetto di grant "sul progetto" distinto da "sulla sua cartella radice" —
  probabilmente corretto, va solo reso esplicito, vedi §5);
- nessun audit trail sui grant stessi;
- il fallback legacy resta attivo ovunque, non è stato pianificato quando
  disattivarlo (Fase 3/4 di TASK-007, mai iniziate).

## 2. Problemi e limiti

| # | Problema | Evidenza |
|---|---|---|
| P1 | **Nessuna UI applicativa** per gestire i grant: l'unico modo per assegnare un `FolderPermissionGrant` oggi è Django Admin. | `FolderPermissionGrantAdmin` (`projects/admin.py:105-119`) è l'unico punto di scrittura applicativo oltre al comando di backfill una-tantum. |
| P2 | **Admin come backdoor non auditata**: nessun `ModelAdmin` per `FolderPermissionGrant`/`ProjectFolderMembership` sovrascrive `has_*_permission` — qualunque `is_staff` con il permesso Django standard su quel modello può creare/modificare/eliminare grant, bypassando ogni funzione di permesso applicativa, senza lasciare traccia nel sistema di audit del dominio (solo il `LogEntry` generico di Django, non integrato con `AuditLog`/lo storico). | Confermato per assenza di override in `projects/admin.py`; confrontare con `auditlog/admin.py` che invece blocca le mutazioni per `AuditLog`. |
| P3 | **Nessun audit trail dominio-specifico** per grant/membership: nessuna chiamata a `create_audit_log`/`AuditLog.objects.create` in `projects/services.py` per queste operazioni (l'unico scrittore è il comando di backfill, batch, non granulare per singola concessione). | Verificato per assenza di funzioni `def .*(grant|permission)` in `projects/services.py`. |
| P4 | **Due sistemi non sincronizzati**: creare una `ProjectFolderMembership` non genera (né aggiorna né elimina) automaticamente il `FolderPermissionGrant` corrispondente, e viceversa. L'unico ponte è un comando manuale, idempotente ma non automatico, con una mappatura **più conservativa** (esclude 6 dei 12 codici) di quella usata a runtime dal fallback. | `docs/ai/PERMISSIONS_AUDIT.md` §3.2 — confermato ancora vero oggi. |
| P5 | **Codice che bypassa interamente il resolver**: `get_folder_role`/`has_folder_role` (`projects/permissions.py:15-49`) e `ecn.permissions.can_view_ecn` (righe 91-93, uso diretto di `AUTH_ROLES` legacy) — una nuova UI di concessione granulare non avrebbe alcun effetto su questi percorsi finché non vengono migrati. | `docs/ai/ECN_PERMISSIONS_AUDIT.md` — la migrazione di `can_view_ecn` è stata esplicitamente rimandata perché nessun `permission_code` attuale rappresenta "auditor+manager" senza sovra-concedere. |
| P6 | **Fallback legacy non disattivabile**: anche con una UI granulare perfetta, un `ProjectFolderMembership` preesistente continuerebbe a produrre accesso secondo la mappatura legacy finché il fallback resta attivo — un utente potrebbe vedere un comportamento che la nuova UI non mostra affatto (nessun grant visibile, eppure l'accesso è concesso lo stesso dal fallback). Rischio di **confusione operativa**, non di sicurezza (il fallback non concede più del legacy stesso). | `docs/ai/PERMISSIONS_AUDIT.md` R3/G5. |
| P7 | **`archive_document_list` filtra in Python**, non a livello di queryset, e pagina la lista in memoria dopo il filtro — non un problema di sicurezza, ma un limite di scalabilità se il numero di documenti crescesse molto (rilevante perché una UI granulare tenderà ad aumentare il numero di combinazioni utente/cartella da valutare). | `documents/views.py:138-140`. |
| P8 | **Nessun `permission_code` per "sola visibilità ECN per auditor/manager"** — un gap di dominio già noto, non risolvibile con la sola UI. | `docs/ai/ECN_PERMISSIONS_AUDIT.md`. |

## 3. Matrice delle operazioni da proteggere

Ricostruita dal codice attuale (non ipotizzata). "Oggi" = funzione già esistente; "via resolver?" = passa già dal `PermissionResolver` (quindi coperta nativamente da una UI sui grant) o bypassa (richiede lavoro aggiuntivo).

| Operazione | Funzione oggi | Via resolver? |
|---|---|---|
| Vedere una cartella / navigare | `get_visible_folder_ids` e affini | Sì |
| Vedere un progetto | `_assert_can_view_project` (`view_projects`) | Sì |
| Vedere lo storico di un progetto | stessa funzione di sopra (TASK 2) | Sì |
| Creare un documento in una cartella | `can_create_document_in_folder` (`create_draft`) | Sì |
| Modificare metadati documento | `can_edit_document_metadata` | Sì (con eccezioni per autore bozza) |
| Creare una nuova revisione | `can_create_revision` (`create_draft`) | Sì |
| Caricare un file su una revisione | nessuna funzione dedicata — eredita il gate della vista che la contiene | Indirettamente |
| Creare ECN standard | `can_create_ecn` — oggi **globale per gruppo**, non per cartella | **No** |
| Creare ECN semplice | stessa funzione + flag `Document.allow_simple_ecn` | **No** |
| Inviare in approvazione | `can_submit_for_approval` (`submit_for_approval`) | Sì |
| Vedere un documento (pubblicato) | `can_view_document` (`read_published`) | Sì |
| Vedere lo storico/Archivio di un documento | `can_view_archived_document` (`view_history`) | Sì |
| Scaricare il file sorgente | `can_download_version_file` | Sì |
| Scaricare PDF rappresentazione/approvato | `can_download_representation_pdf`/`can_download_approved_pdf` | Sì |
| Vedere l'audit di una cartella | `can_view_audit` | Sì |
| Votare/gestire CCB di un ECN | `can_configure_ccb`/`can_close_ecn`/ecc. | **No** — governance ECN è per-assegnazione (`ChangeNoticeApprover`), non per-cartella |
| Amministrare Django Admin | permesso Django standard, nessun collegamento applicativo | **No** |

**Conclusione**: la maggior parte delle operazioni sui *documenti* passa già dal resolver. Le operazioni ECN (creare, votare) sono **strutturalmente diverse** (globali per gruppo o per assegnazione individuale, non per cartella) — non vanno forzate nel modello a cartelle: sarebbe un errore di design imporre un unico permesso raccoglitore.

## 4. Alternative considerate

| Alternativa | Valutazione |
|---|---|
| **(A) Costruire un sistema di permessi granulari completamente nuovo, parallelo** | Scartata: duplicherebbe un'infrastruttura già esistente e testata (`FolderPermissionGrant`+resolver), raddoppiando la superficie di manutenzione e i rischi di incoerenza (esattamente il problema P4 che già esiste tra due sistemi). |
| **(B) Esporre in UI applicativa l'attuale `FolderPermissionGrant`, così com'è, senza modifiche al modello dati** | Percorribile ma insufficiente da sola: non risolve P2 (Admin backdoor), P3 (audit), P6 (fallback legacy confuso). |
| **(C) Estendere `FolderPermissionGrant` con audit dedicato + UI applicativa + piano esplicito di ritiro del fallback legacy, senza toccare l'algoritmo di precedenza/ereditarietà già in produzione** | **Raccomandata.** Vedi §5. |
| **(D) Livelli di accesso semplici (READ/CONTRIBUTE/MANAGE) invece di permessi per-azione** | Scartata come sostituto: il sistema attuale è già per-azione (12 codici) e alcuni ruoli storici non sono un sottoinsieme ordinato l'uno dell'altro (es. `approver` non è "meno" di `author`, è ortogonale) — un modello a 3 livelli lineari perderebbe espressività già presente. Può però essere offerto in UI come **preset** (vedi §13) sopra il modello granulare esistente, per ridurre la complessità percepita da chi assegna permessi senza eliminare la precisione sottostante. |
| **(E) ACL con solo allow, mai deny esplicito** | Scartata: il modello attuale supporta già DENY esplicito e la precedenza `deny > allow` a parità di specificità — rimuoverlo sarebbe una regressione, non un miglioramento, e romperebbe l'invariante "un manager non può essere escluso per errore da un allow più generico" solo se il deny è usato correttamente (vedi §10). |

## 5. Soluzione raccomandata

**Non un nuovo modello dati.** Completare l'infrastruttura esistente:

1. Aggiungere un **audit trail dedicato** per ogni scrittura di
   `FolderPermissionGrant` (create/update/delete), riusando
   `auditlog.services.create_audit_log` con una nuova azione dedicata (es.
   `FOLDER_PERMISSION_GRANTED`/`_REVOKED`/`_CHANGED`), scritto dal service
   layer (nuovo `projects/services.py:grant_folder_permission(...)`/
   `revoke_folder_permission(...)`), **mai da un `save()` diretto** — così
   l'Admin, se lasciato abilitato, resta un gap noto e circoscritto (P2)
   piuttosto che il canale primario.
2. Aggiungere una **UI applicativa** (form dedicato, non l'Admin) per
   assegnare/revocare grant durante creazione/modifica di cartella e
   progetto, che scrive esclusivamente tramite i nuovi service (mai
   `FolderPermissionGrant.objects.create` diretto da una view).
3. **Non introdurre un modello di permessi separato per `Project`**: un
   progetto la cui `root_folder` è popolata eredita i permessi di quella
   cartella (il codice lo fa già, `view_projects` è un `permission_code`
   sulla cartella radice). Rendere questo **esplicito in UI** ("i permessi
   di questo progetto sono quelli della sua cartella radice") invece di
   inventare una seconda gerarchia di permessi progetto-specifica che il
   dominio non conserva oggi.
4. **Pianificare, non eseguire in questo task**, il ritiro del fallback
   legacy: Fase 3 (migrare `get_folder_role`/`has_folder_role`/
   `ecn.can_view_ecn` sul resolver, introducendo se necessario un nuovo
   `permission_code` per "solo auditor/manager vedono l'ECN") e Fase 4
   (disattivare `include_legacy_fallback` di default) restano **task
   futuri separati**, esplicitamente fuori scope qui.
5. Chiudere P8 introducendo, solo quando si pianifica la Fase 3, un
   `permission_code` dedicato (es. `view_ecn_all`) invece di sovraccaricare
   `view_folder_ecns` (che oggi tutti e 5 i ruoli legacy possiedono).

## 6. Modello dati proposto

Nessuna nuova tabella per la concessione in sé. Estensione minima:

- `FolderPermissionGrant`: **nessun campo nuovo** — il modello attuale (user
  XOR group, permission_code, effect, inherit_to_children, expires_at) è
  già sufficiente per i requisiti funzionali descritti (leggere,
  interagire per singola azione, escludere esplicitamente via DENY).
- Nuova tabella leggera, opzionale, solo se si vuole uno storico
  "chi ha impostato questo grant e perché" oltre al generico `AuditLog`
  (probabilmente **non necessaria**: `AuditLog.changes` JSON già
  supporta old/new value liberi — riusarlo è coerente con come ogni altra
  parte del sistema registra le modifiche, evitando un'ennesima tabella
  di audit specializzata).

## 7. Precedenza allow/deny

**Non cambiare la regola esistente**, verificata corretta e già in
produzione: a parità di specificità di cartella, `deny` utente >
`allow` utente > `deny` gruppo > `allow` gruppo. Tra cartelle di
specificità diversa, **la più vicina all'oggetto decide**, senza fondere
i livelli — un grant su una sottocartella (anche se meno permissivo)
sovrascrive completamente qualunque decisione presa su una cartella
antenata, allow o deny che sia.

Conflitti espliciti richiesti dal task:
- gruppo permette, utente escluso esplicitamente → **vince l'esclusione
  utente** (regola già implementata).
- gruppo esclude, utente autorizzato direttamente → **vince l'utente**
  (già implementato, l'utente ha sempre precedenza sul gruppo a parità di
  livello).
- utente in più gruppi in conflitto (uno allow, uno deny) → **vince il
  deny di gruppo** anche se un altro gruppo darebbe allow, per lo stesso
  principio "deny vince a parità di specificità" — comportamento già
  implementato in `_evaluate_grants_at_level`, va solo **documentato
  esplicitamente in UI** con un esempio, perché è il caso meno intuitivo
  per chi assegna i permessi.

## 8. Ereditarietà

- **Cartella → sottocartella**: già implementata, un grant con
  `inherit_to_children=True` si propaga a tutti i discendenti (via `path`);
  con `inherit_to_children=False` si ferma alla cartella su cui è
  impostato.
- **Cartella → documento**: un documento eredita i permessi della sua
  `project_folder` diretta (non esiste un grant "sul documento" — corretto,
  nessuna richiesta di introdurne uno).
- **Progetto → documenti**: indiretta, via `root_folder` + discendenti
  (`get_project_document_folders`) — nessuna modifica necessaria.
- **Progetto → cartelle**: un progetto **è** la sua `root_folder`
  (relazione 1:1) più le sottocartelle sotto di essa — non serve una
  regola di ereditarietà separata "progetto verso cartelle", è la stessa
  regola cartella→sottocartella applicata a partire dalla root del
  progetto.
- **Documento associato sia a progetto sia a cartella generica
  contemporaneamente**: **non può accadere nel modello dati attuale** —
  `Document.project_folder` è un singolo FK, un documento appartiene a
  **una sola** cartella (che può essere dentro l'albero di un progetto o
  una cartella dipartimentale indipendente, mai entrambe). Nessuna regola
  di conflitto da progettare qui: il caso non esiste nel dominio.

## 9. Utenti e gruppi

Nessuna modifica ai gruppi Django esistenti. La UI deve permettere di
scegliere, per una concessione:
- un **utente specifico**, oppure
- un **gruppo Django esistente** (inclusi i gruppi già usati come ruoli
  globali: Document Authors/Approvers/Managers/Auditors, Quality
  Manager/Operator, ECN Proposers, Change Control Board),

mai entrambi sulla stessa riga (vincolo già garantito dal
`CheckConstraint` esistente sul modello). Non introdurre un concetto di
gruppo "locale alla cartella" — userebbe gruppi Django e basta, coerente
con l'unica strategia già in uso.

## 10. Ruoli speciali

Nessuna modifica alle regole già in vigore (verificate corrette,
esplicitamente testate contro il rischio di auto-esclusione):
- **superuser**: bypass totale, sempre, a ogni livello — invariato.
- **is_staff**: **mai** un bypass applicativo (regola MB1 già rigorosamente
  rispettata ovunque nel codice ispezionato) — solo accesso a Django Admin
  secondo i permessi Django standard.
- **Document Manager** (`is_document_manager`): bypass applicativo quasi
  ovunque tranne editing bozza altrui — è il ruolo equivalente ad "admin
  di dominio" già oggi, e la nuova UI di concessione deve **richiedere
  questo ruolo** (o superuser) per poter creare/modificare grant, così
  come già richiesto per creare cartelle/progetti.
- **Responsabile Qualità** (Quality Manager): bypass globale su ECN,
  nessun collegamento a cartelle — invariato, dominio separato.
- **Responsabile progetto/documento, creatore cartella**: oggi non hanno
  automaticamente pieni poteri sul *proprio* oggetto se non sono anche
  Document Manager — se questo si rivela un problema pratico, la
  correzione corretta è un grant esplicito assegnato a quell'utente al
  momento della creazione (owner = grant `manage_folder`/tutti i codici
  sulla propria cartella), **non** un nuovo bypass hardcoded — evita
  esattamente il rischio "tutti gli amministratori possono essere esclusi
  per errore" richiesto dal task: un grant esplicito è visibile e
  revocabile solo intenzionalmente, un bypass implicito nel codice non lo
  è.
- **Approvatori CCB**: restano governati per-assegnazione
  (`ChangeNoticeApprover`), non per-cartella — nessuna sovrapposizione con
  questo sistema, per design (vedi §3).

## 11. Default per i dati esistenti

Nessuna migrazione dati necessaria: cartelle/progetti/documenti esistenti
continuano a funzionare esattamente come oggi, perché:
- nessun `FolderPermissionGrant` esistente viene toccato;
- il fallback legacy resta attivo (nessuna disattivazione in questo
  task) — chi ha accesso oggi via `ProjectFolderMembership` continua ad
  averlo;
- la nuova UI è puramente additiva: permette di creare nuovi grant, non
  richiede che ne esista uno per continuare a funzionare come prima.

## 12. Strategia di migrazione

Nessuna migrazione schema (nessun campo nuovo). Migrazione **operativa**,
in fasi separate e already-scoped dal documento precedente, qui solo
riordinate rispetto a questo task:
1. (Questo design) — nessuna azione.
2. Task di implementazione futuro: service layer + audit (§5.1).
3. Task di implementazione futuro: UI applicativa (§5.2).
4. Task di implementazione futuro, **esplicitamente successivo e separato**:
   Fase 3/4 del ritiro del fallback legacy — richiede un audit preventivo
   di tutte le `ProjectFolderMembership` esistenti per assicurarsi che un
   backfill completo (tutti e 12 i codici, non il sottoinsieme
   conservativo attuale) sia stato eseguito prima di anche solo pianificare
   la disattivazione del fallback.

## 13. UI proposta

Form dedicato (non Django Admin) raggiungibile da creazione/modifica
cartella e progetto, con tre liste esplicite e visivamente distinte:
- **Lettura** (gruppi + utenti) → grant `read_published`
  (+ eventualmente `view_history`/`view_obsolete_documents` come
  checkbox avanzate, non di primo livello);
- **Operativo** (gruppi + utenti) → un **preset** che spunta insieme
  `create_draft`, `submit_for_approval`, `request_ecn`,
  `manage_project_documents` (i codici che oggi compongono il ruolo
  legacy "author"), con possibilità di espandere e deselezionare singoli
  codici per chi vuole precisione granulare;
- **Esclusi** (gruppi + utenti) → crea grant con `effect=DENY` per
  **tutti** i codici attualmente concessi a quell'utente/gruppo su quella
  cartella (non un singolo codice a scelta, per evitare di dover spiegare
  la precedenza per-codice in UI — un'esclusione è "questo utente non deve
  avere accesso qui", non un editor granulare di sottrazione).

Prevenzione di selezioni contraddittorie: se un utente/gruppo viene
aggiunto sia a "Operativo" sia a "Esclusi" nella stessa sottomissione,
il form rifiuta con un errore esplicito **prima** di scrivere qualunque
grant (mai una scrittura parziale).

## 14. Audit

Ogni scrittura passa dal nuovo service layer (§5.1), che registra, per
ogni grant creato/modificato/eliminato: azione (`FOLDER_PERMISSION_*`),
attore, cartella, utente-o-gruppo target, `permission_code`, `effect`,
`inherit_to_children`, valore precedente (se modifica/eliminazione),
timestamp — riusando `AuditLog`/`create_audit_log` esistente, senza
nuova tabella (vedi §6).

## 15. Prestazioni e caching

L'algoritmo attuale è già ottimizzato per il caso bulk
(`resolve_bulk`, al più 3 query indipendentemente dal numero di cartelle)
— nessuna nuova ottimizzazione richiesta per la sola aggiunta di una UI.
Unico punto da correggere quando si toccherà `archive_document_list`
(P7, fuori scope stretto di questo design ma segnalato): il filtro
per-oggetto in Python andrebbe convertito in filtro a livello di
queryset usando gli id bulk-risolti, come già fanno `document_list`/
`project_list`/`folder_list`.

## 16. Rischi di sicurezza

- **Amministrazione Django come backdoor (P2)**: resta un rischio residuo
  finché l'Admin per `FolderPermissionGrant`/`ProjectFolderMembership`
  non viene ristretto (`has_change_permission`/`has_delete_permission`
  a soli superuser) o quantomeno reso audit-visibile. Raccomandazione:
  restringere l'accesso Admin a questi due modelli a soli superuser
  come parte del task di implementazione, indipendentemente dalla nuova
  UI.
- **Validazione lato server obbligatoria**: la UI deve validare
  esattamente come descritto in §13 (nessuna scrittura se
  operativo/esclusi si sovrappongono) — mai fidarsi solo di JS lato
  client.
- **Nessun nuovo vettore introdotto** dal modello dati (nessun campo
  nuovo, nessuna nuova via di scrittura oltre al service layer proposto).

## 17. Task di implementazione proposti (per approvazione futura, non eseguiti ora)

1. Service layer `grant_folder_permission`/`revoke_folder_permission` +
   audit dedicato (§5.1, §14).
2. Restrizione Admin per i due modelli a soli superuser (§16).
3. UI applicativa di concessione (form + template, §13), collegata da
   creazione/modifica cartella e progetto.
4. Test dedicati (matrice §18).
5. (Task futuro, separato) Fase 3: migrare `get_folder_role`/
   `has_folder_role`/`ecn.can_view_ecn` sul resolver, introducendo
   `view_ecn_all` (P8).
6. (Task futuro, separato) Fase 4: pianificare/eseguire la disattivazione
   del fallback legacy.

## 18. Matrice dei test (per il task di implementazione, non eseguiti ora)

- Creazione grant utente/gruppo, lettura/operativo/esclusione, via nuovo
  service — persistenza corretta + audit scritto.
- Precedenza: utente-deny su gruppo-allow; utente-allow su gruppo-deny;
  due gruppi in conflitto (deny vince); cartella figlia sovrascrive
  cartella padre indipendentemente da allow/deny.
- Ereditarietà: `inherit_to_children=True` raggiunge i discendenti;
  `False` si ferma alla cartella impostata; grant sulla cartella stessa
  si applica sempre indipendentemente dal flag.
- Ruoli speciali: superuser bypassa sempre; is_staff non bypassa mai;
  Document Manager può creare/modificare grant; un utente normale non
  può.
- Form: submission con utente in operativo+esclusi contemporaneamente →
  errore, nessuna scrittura parziale.
- Retrocompatibilità: cartella/progetto/documento esistente senza alcun
  grant nuovo si comporta esattamente come prima (fallback legacy
  invariato).
- Admin: utente is_staff senza permesso Django esplicito non può toccare
  i due modelli; con permesso esplicito può ancora (rischio residuo
  documentato, non silenziato).
- Performance: `resolve_bulk` non degrada con N grant aggiuntivi
  (query count costante).
