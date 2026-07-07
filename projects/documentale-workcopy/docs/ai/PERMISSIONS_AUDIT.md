# Audit permessi cartella/documenti — TASK-006

**Data:** 2026-07-06  
**Progetto:** `projects/documentale-workcopy`  
**Scope:** sola analisi (nessuna modifica applicativa)  
**Obiettivo:** mappare lo stato attuale del doppio sistema permessi e preparare TASK-007 (migrazione controllata).

> **Aggiornamento (TASK-010, 2026-07-07):** TASK-007 Fase 1 (allineamento
> mapping backfill/compare) e Fase 2 (backfill esteso reale, tutti i 6
> permission code prima esclusi ora inclusi) sono **completate**. Il gap
> G1/G2 descritto in questo documento è chiuso per tutti i ruoli dopo
> backfill esteso. **Il fallback legacy (`include_legacy_fallback=True`)
> resta attivo** — non è stato rimosso. Fase 3 (refactor
> `ecn/permissions.py` su resolver) e Fase 4 (rimozione fallback) restano
> task futuri non ancora pianificati in dettaglio. Vedi
> `docs/ai/TASKS.md` (sezioni TASK-007/Fase 1 e TASK-007-2) e
> `docs/ai/RUN_LOG.md` per il dettaglio delle esecuzioni.

---

## 1. Sintesi esecutiva

Il Documentale gestisce i permessi per-cartella con **due modelli dati coesistenti**:

| Sistema | Modello | Granularità | Stato |
|--------|---------|-------------|-------|
| **Legacy** | `ProjectFolderMembership` | Ruolo unico per `(cartella, utente)` | Ancora fonte di verità operativa via fallback |
| **Modulare** | `FolderPermissionGrant` | Grant per `(cartella, utente\|gruppo, permission_code, effect)` | Attivo in produzione tramite `PermissionResolver`, ma spesso vuoto finché non backfillato |

Il resolver modulare (`projects/resolver.py`) è **integrato nelle funzioni pubbliche** di `projects/permissions.py` e `documents/permissions.py` con `include_legacy_fallback=True`. Finché questo flag resta attivo, ogni decisione modulare assente viene risolta leggendo la membership legacy e convertendo il ruolo tramite `_LEGACY_ROLE_PERMISSIONS`.

**Rischio principale (PROJECT_ANALYSIS.md #4):** backfill, compare e runtime usano **tre mapping diversi**. Un backfill + compare “verde” **non garantisce** parità comportamentale se si rimuove il fallback legacy senza ulteriori grant o refactor.

**Raccomandazione per TASK-007:** non rimuovere il fallback finché non si estende il backfill (o un compare ampliato) a **tutti** i `permission_code` di `_LEGACY_ROLE_PERMISSIONS`, e finché `get_folder_role` / `ecn/permissions.py` non passano al resolver.

---

## 2. Modello dati attuale

### 2.1 `ProjectFolderMembership` (legacy)

**File:** `projects/models.py` (classe `ProjectFolderMembership`, migrazione `0003_projectfoldermembership`)

| Campo | Tipo | Note |
|-------|------|------|
| `folder` | FK → `ProjectFolder` | CASCADE |
| `user` | FK → `User` | CASCADE |
| `role` | CharField | `reader`, `author`, `approver`, `auditor`, `manager` |
| `created_by`, `created_at` | audit | opzionali |

**Vincoli:** `unique_together = ('folder', 'user')` — un solo ruolo per utente per cartella.

**Admin:** `ProjectFolderMembershipAdmin` — CRUD legacy ancora esposto in Django Admin.

**API diretta:** `get_folder_role()` e `has_folder_role()` in `projects/permissions.py` leggono **solo** questa tabella, senza passare dal resolver modulare.

### 2.2 `FolderPermissionGrant` (modulare)

**File:** `projects/models.py` (classe `FolderPermissionGrant`, migrazione `0009_folder_permission_grant`)

| Campo | Tipo | Note |
|-------|------|------|
| `folder` | FK → `ProjectFolder` | CASCADE |
| `user` / `group` | FK XOR | CheckConstraint: esattamente uno valorizzato |
| `permission_code` | CharField | 12 codici granulari (vedi sotto) |
| `effect` | CharField | `allow` / `deny` |
| `inherit_to_children` | Boolean | default `True`; backfill imposta `False` |
| `expires_at` | DateTime | opzionale; grant scaduti ignorati |
| `notes`, `created_by`, `created_at` | audit | |

**Permission codes disponibili:**

| Codice | Descrizione |
|--------|-------------|
| `read_published` | Leggi documenti pubblicati |
| `view_history` | Vedi storico versioni |
| `view_obsolete_documents` | Vedi documenti obsoleti |
| `view_projects` | Vedi progetti nella cartella |
| `view_folder_ecns` | Vedi ECN della cartella |
| `create_draft` | Crea bozze |
| `submit_for_approval` | Invia in approvazione |
| `eligible_document_approver` | Eleggibile come approvatore |
| `manage_rejected_drafts` | Gestisci bozze rifiutate |
| `manage_project_documents` | Gestisci documenti progetto |
| `request_ecn` | Richiedi variante ECN |
| `manage_folder` | Gestisci cartella |

**Admin:** `FolderPermissionGrantAdmin` con filtri su effect, permission_code, scadenza.

---

## 3. Tre mapping distinti (critico per la migrazione)

### 3.1 Runtime fallback — `_LEGACY_ROLE_PERMISSIONS`

**File:** `projects/resolver.py` (righe 40–84)

Usato quando `include_legacy_fallback=True` e nessun grant modulare decide. Riproduce la semantica storica dei ruoli:

| Ruolo | Permission codes (via fallback runtime) |
|-------|-------------------------------------------|
| **reader** | `read_published`, `view_projects`, `view_folder_ecns` |
| **author** | reader + `create_draft`, `submit_for_approval`, `manage_rejected_drafts`, `manage_project_documents`, `request_ecn` |
| **approver** | reader + `eligible_document_approver` |
| **auditor** | reader + `view_history`, `view_obsolete_documents` |
| **manager** | tutti i 12 codici elencati nel modello |

### 3.2 Backfill — `BACKFILL_ROLE_PERMISSIONS`

**File:** `projects/management/commands/backfill_folder_permission_grants.py` (righe 34–59)

Mapping **conservativo intenzionale**: converte solo permessi con “prova esplicita” nel codice legacy. **Esclusi esplicitamente:**

- `view_projects`
- `view_folder_ecns`
- `manage_project_documents`
- `request_ecn`
- `view_obsolete_documents`
- `manage_rejected_drafts`

| Ruolo | Grant creati dal backfill |
|-------|---------------------------|
| **reader** | `read_published` |
| **author** | `read_published`, `create_draft`, `submit_for_approval` |
| **approver** | `read_published`, `eligible_document_approver` |
| **auditor** | `read_published`, `view_history` |
| **manager** | `read_published`, `create_draft`, `submit_for_approval`, `eligible_document_approver`, `view_history`, `manage_folder` |

Grant backfillati con `inherit_to_children=False` e `effect=allow`.

### 3.3 Compare — usa il mapping backfill, non quello runtime

**File:** `projects/management/commands/compare_folder_permissions.py`

La funzione `_legacy_allows()` confronta:

- **Legacy side:** `BACKFILL_ROLE_PERMISSIONS` (subset)
- **Modular side:** `has_folder_permission(..., include_legacy_fallback=False)`

Quindi `compare_folder_permissions` verifica **solo** il sottoinsieme backfillabile, **non** l’intero comportamento runtime attuale.

### 3.4 Tabella divergenze mapping

| Permission code | Runtime fallback (es. reader) | Backfill reader | Impatto se fallback OFF post-backfill |
|-----------------|------------------------------|-----------------|--------------------------------------|
| `read_published` | ✓ | ✓ | OK dopo backfill |
| `view_projects` | ✓ | ✗ | **Progetti nascosti** (lista/dettaglio) |
| `view_folder_ecns` | ✓ | ✗ | ECN cartella non visibili via grant |
| `view_obsolete_documents` | ✓ (auditor) | ✗ | **Auditor perde obsoleti** |
| `manage_rejected_drafts` | ✓ (author/manager) | ✗ | Bozze rifiutate: permesso perso |
| `manage_project_documents` | ✓ (author/manager) | ✗ | Doc progetto: permesso perso |
| `request_ecn` | ✓ (author/manager) | ✗ | ECN via grant cartella perso |

---

## 4. Architettura di risoluzione

### 4.1 Flusso `PermissionResolver`

```
Richiesta permesso (user, folder, permission_code)
    │
    ├─ anonimo / folder None → deny (superuser bypass)
    │
    ├─ Valuta FolderPermissionGrant (query unica su cartella + antenati)
    │     • cartella corrente: tutti i grant
    │     • antenati: solo inherit_to_children=True
    │     • precedenza: user_deny > user_allow > group_deny > group_allow
    │     • grant scaduti ignorati
    │
    ├─ Decisione modulare? → return allow/deny
    │
    └─ include_legacy_fallback=True?
          ├─ Sì → ProjectFolderMembership + _LEGACY_ROLE_PERMISSIONS
          └─ No  → deny (default)
```

**Bulk:** `resolve_bulk()` usa al massimo 3 query (gruppi cached, grant, membership legacy).

**Request cache:** `PermissionResolver.for_request(request, include_legacy_fallback=...)` evita istanze duplicate per request.

### 4.2 Punti in cui `include_legacy_fallback=True` è attivo

| File | Funzione / contesto | Permission codes tipici |
|------|---------------------|-------------------------|
| `projects/permissions.py` | `can_view_folder` | `read_published` |
| `projects/permissions.py` | `can_manage_folder` | `manage_folder` |
| `projects/permissions.py` | `can_create_document_in_folder` | `create_draft` |
| `projects/permissions.py` | `get_visible_folder_ids` | `read_published` |
| `projects/permissions.py` | `get_writable_folder_ids` | `create_draft` |
| `projects/permissions.py` | `get_project_visible_folder_ids` | `view_projects` |
| `documents/permissions.py` | `_resolve_folder_perm` (wrapper) | vari (read, create, submit, view_history, …) |
| `projects/views.py` | `folder_detail` explorer progetti | `view_projects` |
| `projects/views.py` | `project_detail`, altre view inline | `view_projects` |

**Default del resolver:** `include_legacy_fallback=False` se chiamato direttamente senza flag — ma **tutti i path applicativi documentati sopra passano `True`**.

### 4.3 Codice che bypassa il resolver (solo legacy)

| File | Funzione | Rischio migrazione |
|------|----------|-------------------|
| `projects/permissions.py` | `get_folder_role`, `has_folder_role` | Ignora grant modulari e deny espliciti |
| `ecn/permissions.py` | `can_view_ecn` (AUDIT_ROLES via `get_folder_role`) | ECN visibilità legata a membership, non a grant |
| `ecn/permissions.py` | `can_create_ecn` (WRITE_ROLES via `get_folder_role`) | Creazione ECN legata a membership; commento MB5 prevede `request_ecn` |

Finché queste funzioni restano su `ProjectFolderMembership`, la migrazione modulare è **parziale** anche con backfill completo.

---

## 5. Comandi di migrazione disponibili

### 5.1 `backfill_folder_permission_grants`

**Path:** `projects/management/commands/backfill_folder_permission_grants.py`

| Opzione | Comportamento |
|---------|---------------|
| *(default)* / `--dry-run` | Report piano; **nessuna scrittura** |
| `--apply` | Crea grant in `transaction.atomic()` |
| `--folder-id`, `--user-id` | Scope parziale |

**Proprietà documentate e testate:**

- Idempotente (grant allow esistenti → skip)
- Non distruttivo (membership legacy intatta)
- Conflitti se grant deny preesistente → segnalati, non sovrascritti
- `inherit_to_children=False` sui grant creati

### 5.2 `compare_folder_permissions`

**Path:** `projects/management/commands/compare_folder_permissions.py`

| Opzione | Comportamento |
|---------|---------------|
| `--user-id`, `--folder-id` | Scope parziale |
| `--allow-differences` | Exit 0 anche con divergenze |

**Read-only.** Exit code 1 se divergenze (legacy vs modular senza fallback).

**Limite:** confronta solo permessi in `BACKFILL_ROLE_PERMISSIONS`, non l’intero `_LEGACY_ROLE_PERMISSIONS`.

---

## 6. Test esistenti sui permessi

La suite `projects/tests.py` contiene copertura strutturata per fasi (Step B–F):

| Classe test | ~# test | Cosa copre |
|-------------|---------|------------|
| `MembershipPermissionTests` | ~20 | Integrazione end-to-end legacy: view folder, revisioni, documenti, download, view HTTP |
| `FolderPermissionGrantModelTests` | 12 | Vincoli modello (XOR user/group, unicità, default) |
| `FolderPermissionResolverTests` | ~40+ | Resolver: allow/deny, ereditarietà, scadenze, precedenza, fallback legacy, mapping ruoli runtime |
| `BackfillFolderPermissionGrantsTests` | ~15 | Command backfill: dry-run, apply, idempotenza, mapping, conflitti, atomicità |
| `CompareFolderPermissionsTests` | ~6 | Command compare: exit code, filtri, read-only |
| `StepEFolderPermissionsIntegrationTests` | ~20 | `can_view_folder`, `can_create_document_in_folder`, `can_manage_folder` con grant + fallback |
| `BulkResolverTests` | ~14 | `resolve_bulk`, performance query, fallback bulk |
| `StepFProjectIntegrationTests` | ~6+ | `view_projects`, project_list/detail, navigation-only |
| *(altre)* | vari | View progetti/cartelle con membership legacy sparse |

**Totale suite progetto:** 1207 test Django (confermato TASK-003/005); la maggior parte dei permessi cartella è in `projects/tests.py`.

**Nota:** il docstring di `FolderPermissionResolverTests` (“Il resolver è completamente shadow: nessuna view lo usa”) è **obsoleto** — l’integrazione Step E è avvenuta; il commento non riflette lo stato attuale.

---

## 7. Gap di test individuati

| # | Gap | Severità | Dettaglio |
|---|-----|----------|-----------|
| G1 | Compare non copre permessi esclusi dal backfill | **Alta** | Nessun test che segnali: backfill OK + compare OK + `view_projects` perso senza fallback |
| G2 | Nessun test “post-migrazione completa” end-to-end | **Alta** | Manca scenario: backfill → fallback OFF → parità con comportamento pre-migrazione su **tutti** i 12 codici |
| G3 | `get_folder_role` / ECN non coperti dal resolver | **Media** | Grant modulari o deny su cartella non influenzano `can_view_ecn` / `can_create_ecn` |
| G4 | Grant di gruppo vs membership utente | **Media** | Resolver testato; pochi test integrazione documenti/view con grant gruppo |
| G5 | `inherit_to_children=False` post-backfill vs ereditarietà legacy | **Media** | Membership legacy vale solo sulla cartella esatta; backfill non eredita — comportamento già diverso se si usa solo grant |
| G6 | Permessi esclusi dal backfill senza test dedicati | **Media** | Es. `view_obsolete_documents`, `manage_rejected_drafts`, `request_ecn` hanno test fallback runtime ma non backfill/compare |
| G7 | Admin doppio (membership + grant) | **Bassa** | Nessun test che verifichi coerenza tra modifiche Admin su entrambe le tabelle |

---

## 8. Rischi di una migrazione

| Rischio | Probabilità | Impatto | Mitigazione proposta |
|---------|-------------|---------|---------------------|
| **R1** Rimozione fallback con solo backfill attuale | Alta se premature | Utenti perdono `view_projects`, ECN cartella, obsoleti, ecc. | Estendere backfill o secondo backfill “extended”; compare su `_LEGACY_ROLE_PERMISSIONS` completo |
| **R2** Compare “verde” fuorviante | Alta | Falsa sicurezza operativa | Ampliare compare o aggiungere test regressione post-backfill |
| **R3** Deny modulare + membership legacy ancora presente | Media | Comportamento corretto oggi (deny vince); confusione operativa Admin | Documentare; in TASK-007 decidere se deprecare membership UI |
| **R4** `get_folder_role` / ECN fuori resolver | Media | Incoerenza tra documenti (modulare) e ECN (legacy) | Refactor ECN su `_resolve_folder_perm` / `request_ecn` |
| **R5** Grant backfill `inherit_to_children=False` | Media | Sottocartelle senza grant né membership → deny | Valutare ereditarietà per cartelle ad albero; test su alberi profondi |
| **R6** Conflitti deny preesistenti | Bassa | Backfill skip; utente resta senza allow modulare | Report conflitti pre-apply; runbook operatore |
| **R7** Doppia manutenzione Admin | Media | Operatori aggiornano membership ignorando grant | Processo operativo + eventuale hide membership post-migrazione |

---

## 9. Esercizio sicuro dei management command (pre TASK-007)

**Non eseguire su database reale** (in questa copia non esiste comunque un DB persistente di produzione).

### 9.1 Ambiente consigliato

```bash
cd projects/documentale-workcopy
source .venv/bin/activate
export DJANGO_SETTINGS_MODULE=config.test_settings
export SECRET_KEY=test-secret-key-not-for-production-use-only
```

Settings di test (`config/test_settings.py`): SQLite `:memory:`, nessun `.env`, email locmem.

### 9.2 Sequenza sicura

1. **Suite completa baseline**

   ```bash
   ./scripts/test.sh
   ```

2. **Dry-run backfill** (zero scritture)

   ```bash
   python manage.py backfill_folder_permission_grants --dry-run
   ```

3. **Apply in ambiente test isolato** — preferire i test Django già presenti (`BackfillFolderPermissionGrantsTests`, `CompareFolderPermissionsTests`) che eseguono apply/compare su DB `:memory:` e rollback automatico. Per prova manuale su DB file di test usa solo DB temporaneo dedicato, mai `db.sqlite3` di sviluppo reale.

4. **Compare dopo backfill**

   ```bash
   python manage.py compare_folder_permissions
   # Exit 0 atteso solo sul subset BACKFILL_ROLE_PERMISSIONS
   ```

5. **Compare esteso (da aggiungere in TASK-007)** — verificare manualmente o con script i permessi **non** in backfill, es. per reader:

   ```python
   # Esempio concettuale — non eseguito in TASK-006
   from projects.resolver import has_folder_permission
   # Con membership reader + backfill apply + include_legacy_fallback=False:
   # has_folder_permission(user, folder, 'view_projects') → False oggi (gap atteso)
   ```

### 9.3 Esito atteso in questa copia

I test `BackfillFolderPermissionGrantsTests` e `CompareFolderPermissionsTests` **già esercitano** i command in SQLite `:memory:` durante `./scripts/test.sh`. Non è necessario (né richiesto) un run manuale aggiuntivo per TASK-006; TASK-007 deve partire da quella base e aggiungere verifiche sul gap mapping completo.

---

## 10. Proposta sequenza per TASK-007

### Fase 0 — Prerequisiti (review operatore)

- [ ] Approvare questo audit
- [ ] Decidere strategia mapping: **estendere `BACKFILL_ROLE_PERMISSIONS`** vs mantenere subset + accettare separazione `view_projects` / ECN

### Fase 1 — Allineamento mapping (codice)

1. Allineare `BACKFILL_ROLE_PERMISSIONS` a `_LEGACY_ROLE_PERMISSIONS` **oppure** documentare esplicitamente ogni permesso escluso e aggiornare il comportamento applicativo di conseguenza.
2. Estendere `compare_folder_permissions` per confrontare **tutti** i codici di `_LEGACY_ROLE_PERMISSIONS`, non solo il subset backfill.
3. Aggiungere test regressione: per ogni ruolo, dopo backfill extended + `include_legacy_fallback=False`, parità con snapshot pre-migrazione (`include_legacy_fallback=True`).

### Fase 2 — Backfill in ambiente test

1. `./scripts/test.sh` → 1207/1207 PASS (baseline).
2. `backfill_folder_permission_grants --dry-run` → review report conflitti.
3. `backfill_folder_permission_grants --apply` su DB test isolato.
4. `compare_folder_permissions` → exit 0 sul mapping **completo** (non solo subset).
5. Test mirati view: `project_list`, `folder_detail`, documenti obsoleti, ECN cartella.

### Fase 3 — Refactor percorsi legacy residui

1. Sostituire `get_folder_role` / `has_folder_role` con wrapper resolver dove serve (`ecn/permissions.py` prioritario).
2. Valutare deprecazione Admin `ProjectFolderMembership` (solo UI/processi, non DROP tabella in prima iterazione).

### Fase 4 — Rimozione fallback (solo se Fase 1–3 verdi)

1. Impostare `include_legacy_fallback=False` in `projects/permissions.py`, `documents/permissions.py`, `projects/views.py`.
2. Suite completa + test integrazione HTTP.
3. Documentare in RUN_LOG; membership legacy resta in DB per rollback (non cancellare subito).

### Fase 5 — Rollback plan

- Ripristinare `include_legacy_fallback=True` (una riga per file).
- Membership legacy ancora presente → comportamento immediato pre-migrazione.
- Grant modulari coesistono senza danno (deny espliciti restano prioritaria).

---

## 11. Acceptance criteria TASK-006 (checklist)

- [x] Modello dati legacy vs modulare documentato
- [x] Punti fallback mappati
- [x] Comandi migrazione descritti
- [x] Test esistenti inventariati
- [x] Gap test individuati
- [x] Rischi migrazione elencati
- [x] Sequenza TASK-007 proposta
- [x] Raccomandazione esercizio sicuro command (SQLite `:memory:` / test Django)
- [x] Nessuna modifica applicativa in questo task

---

## 12. Riferimenti file analizzati

| File | Ruolo |
|------|-------|
| `projects/models.py` | Modelli `FolderPermissionGrant`, `ProjectFolderMembership` |
| `projects/resolver.py` | `PermissionResolver`, `_LEGACY_ROLE_PERMISSIONS` |
| `projects/permissions.py` | API pubblica cartella + fallback |
| `documents/permissions.py` | Permessi documento con `_resolve_folder_perm` |
| `projects/views.py` | Check inline `view_projects` |
| `ecn/permissions.py` | Uso diretto `get_folder_role` |
| `projects/management/commands/backfill_folder_permission_grants.py` | Backfill |
| `projects/management/commands/compare_folder_permissions.py` | Compare |
| `projects/tests.py` | Test permessi Step B–F |
| `projects/admin.py` | Admin entrambi i modelli |
| `docs/ai/PROJECT_ANALYSIS.md` | Rischio #4 originale |
