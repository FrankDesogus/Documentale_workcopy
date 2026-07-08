# Audit ECN permissions resolver bypass (TASK-013)

**Data:** 2026-07-08  
**Task:** TASK-013 — Audit ECN permissions resolver bypass  
**Riferimento audit precedente:** `docs/ai/PERMISSIONS_AUDIT.md` §4.3, §7 gap **G3**  
**Scope:** solo analisi e documentazione — nessuna modifica applicativa

---

## 1. Sintesi esecutiva

In `ecn/permissions.py` **solo 2 funzioni su 12 pubbliche** (`can_*`) consultano
permessi legati alla cartella del documento. Entrambe bypassano il resolver
modulare (`projects/resolver.py` → `has_folder_permission`) e usano invece
`get_folder_role()` da `projects/permissions.py`, che legge **esclusivamente**
`ProjectFolderMembership` e ignora `FolderPermissionGrant`.

| Funzione | Bypass | Candidato refactor TASK-014 |
|----------|--------|----------------------------|
| `can_create_ecn` | `get_folder_role` + `WRITE_ROLES` | **Sì** — equivalente a `request_ecn` con fallback legacy |
| `can_view_ecn` | `get_folder_role` + `AUDIT_ROLES` | **No** — nessun permission code equivalente; rischio escalation |

Le altre 10 funzioni pubbliche di permesso ECN operano su gruppi globali, stato
dell'ECN o relazioni dirette (proponente, approvatore assegnato, coordinatore CCB)
e sono **fuori scope** per questo audit.

---

## 2. Funzioni e file coinvolti

### 2.1 File analizzati (sola lettura)

| File | Ruolo |
|------|-------|
| `ecn/permissions.py` | Permessi ECN — 2 funzioni con bypass legacy |
| `projects/permissions.py` | `get_folder_role`, `has_folder_role`, `WRITE_ROLES`, `AUDIT_ROLES` |
| `projects/resolver.py` | `_LEGACY_ROLE_PERMISSIONS`, `has_folder_permission` |
| `ecn/tests.py` | Test unitari permessi ECN per-cartella |
| `docs/ai/PERMISSIONS_AUDIT.md` | Gap G3, §4.3 |

### 2.2 Funzioni ECN che bypassano il resolver

#### `can_view_ecn` — righe 89–93

```python
# ecn/permissions.py:89-93
if change_notice.document and change_notice.document.project_folder_id:
    from projects.permissions import get_folder_role, AUDIT_ROLES
    if get_folder_role(user, change_notice.document.project_folder) in AUDIT_ROLES:
        return True
```

- **Import dinamico:** `get_folder_role`, `AUDIT_ROLES`
- **Condizione:** ECN collegata a un documento con `project_folder` valorizzato
- **Controllo:** ruolo membership in `{auditor, manager}`

#### `can_create_ecn` — righe 116–121

```python
# ecn/permissions.py:116-121
folder = document.project_folder
if folder is not None:
    from projects.permissions import get_folder_role, WRITE_ROLES
    if get_folder_role(user, folder) in WRITE_ROLES:
        return True
```

- **Import dinamico:** `get_folder_role`, `WRITE_ROLES`
- **Condizione:** documento con cartella di progetto
- **Controllo:** ruolo membership in `{author, manager}`

### 2.3 Funzioni ECN fuori scope (non toccano permessi cartella)

| Funzione | Righe | Criterio |
|----------|-------|----------|
| `can_configure_ccb` | 125–132 | Quality Manager / superuser |
| `can_submit_ecn` | 135–142 | Quality Manager / superuser |
| `can_review_ecn` | 145–181 | ChangeNoticeApprover assegnato |
| `can_close_ecn` | 184–190 | Quality Manager / superuser |
| `can_compile_dossier` | 193–217 | QM, superuser, `ccb_coordinator` |
| `can_edit_ecn` | 220–239 | QM, superuser, proponente/creatore |
| `can_reconfigure_ccb` | 242–260 | QM, stato ECN |
| `can_reopen_ccb` | 263–276 | QM, stato ECN |
| `can_add_ecn_attachment` | 279–298 | QM, superuser, proponente/creatore |
| `can_download_ecn_attachment` | 301–326 | QM, superuser, proponente, approvatore |

Helper privati (`_is_quality_manager`, `_can_consult_all_ecn`, ecc.) non
consultano `ProjectFolderMembership` né il resolver.

---

## 3. Flussi ECN interessati

### 3.1 Visibilità ECN (`can_view_ecn`)

**Flusso:** un utente tenta di vedere il dettaglio di un ECN (view HTTP, link
dashboard, download allegati indiretti).

**Ordine di valutazione in `can_view_ecn`:**

1. Autenticazione
2. Visibilità globale (`Quality Manager`, `Quality Operator`, `Direction`, superuser)
3. Proponente / creatore dell'ECN
4. ChangeNoticeApprover assegnato a quell'ECN
5. Coordinatore CCB designato (`ccb_coordinator`)
6. **Ruolo cartella auditor/manager** ← unico path per-cartella

**Impatto del bypass:** un utente con grant modulare `FolderPermissionGrant`
(senza `ProjectFolderMembership`) **non** ottiene visibilità ECN tramite cartella,
anche se possiede `view_folder_ecns`. Al contrario, un deny modulare sulla
cartella **non** revoca la visibilità se la membership legacy è ancora `auditor`
o `manager`.

### 3.2 Proposta ECN (`can_create_ecn`)

**Flusso:** un utente tenta di creare/proporre un ECN su un documento.

**Ordine di valutazione in `can_create_ecn`:**

1. Autenticazione
2. Superuser
3. Gruppi globali: `Quality Manager`, `ECN Proposers`
4. Compatibilità legacy: gruppi globali `Authors`, `Managers`
5. **Ruolo cartella author/manager** ← unico path per-cartella

**Impatto del bypass:** un grant modulare `request_ecn` (allow) **non** abilita
la creazione ECN oggi; solo `ProjectFolderMembership` con ruolo `author` o
`manager` lo fa. Il commento MB5 in riga 113 anticipa già la migrazione verso
`request_ecn`.

---

## 4. Permessi verificati oggi (legacy via `get_folder_role`)

Definizioni in `projects/permissions.py`:

```python
WRITE_ROLES = frozenset([ROLE_AUTHOR, ROLE_MANAGER])   # {author, manager}
AUDIT_ROLES = frozenset([ROLE_AUDITOR, ROLE_MANAGER])  # {auditor, manager}
```

`get_folder_role(user, folder)` interroga **solo** `ProjectFolderMembership`:

```python
ProjectFolderMembership.objects.get(folder=folder, user=user).role
```

Restituisce `None` se assente → il check `in WRITE_ROLES` / `in AUDIT_ROLES`
fallisce.

### 4.1 `can_view_ecn` — ruoli ammessi per-cartella

| Ruolo membership | Può vedere ECN (path cartella) |
|------------------|-------------------------------|
| `reader` | No |
| `author` | No |
| `approver` | No |
| `auditor` | **Sì** |
| `manager` | **Sì** |
| Nessuna membership | No |

Nota: `manager` nel setUp di `ECNPermissionsTests` vede l'ECN anche perché
è `ChangeNoticeApprover` assegnato — il test `test_manager_can_view_when_assigned_approver`
documenta esplicitamente questo path alternativo.

### 4.2 `can_create_ecn` — ruoli ammessi per-cartella

| Ruolo membership | Può creare ECN (path cartella) |
|------------------|--------------------------------|
| `reader` | No |
| `author` | **Sì** |
| `approver` | No |
| `auditor` | No |
| `manager` | **Sì** |
| Nessuna membership | No |

---

## 5. Differenza tra logica ECN attuale e resolver modulare

### 5.1 Modello attuale (ECN)

```
can_view_ecn / can_create_ecn
    → get_folder_role(user, folder)
        → ProjectFolderMembership.role
            → confronto con AUDIT_ROLES / WRITE_ROLES
```

- Ignora `FolderPermissionGrant` (allow e deny)
- Ignora ereditarietà grant verso cartelle padre
- Ignora grant di gruppo

### 5.2 Modello modulare (resolver)

```
has_folder_permission(user, folder, permission_code, include_legacy_fallback=True)
    → PermissionResolver
        1. Grant modulari (ALLOW/DENY, utente/gruppo, ereditarietà)
        2. Se nessuna decisione e fallback attivo:
           ProjectFolderMembership.role → _LEGACY_ROLE_PERMISSIONS[role]
```

Con `include_legacy_fallback=True` (obbligatorio in TASK-014), il fallback
reproduce la semantica legacy **per permission code**, non per set di ruoli
aggregati come `WRITE_ROLES` / `AUDIT_ROLES`.

### 5.3 Analisi di equivalenza — `request_ecn` vs `WRITE_ROLES`

Mapping in `projects/resolver.py` (`_LEGACY_ROLE_PERMISSIONS`):

| Ruolo | Contiene `request_ecn`? |
|-------|-------------------------|
| `reader` | No |
| `author` | **Sì** (via `_LEGACY_AUTHOR_PERMISSIONS`) |
| `approver` | No |
| `auditor` | No |
| `manager` | **Sì** (via `_LEGACY_MANAGER_PERMISSIONS`) |

**Set ruoli con `request_ecn`:** `{author, manager}`  
**Set `WRITE_ROLES`:** `{author, manager}`

**Conclusione: match 1:1.** Con `include_legacy_fallback=True`, la sostituzione

```python
has_folder_permission(user, folder, 'request_ecn', include_legacy_fallback=True)
```

è **comportamentalmente equivalente** al controllo attuale `get_folder_role(user, folder) in WRITE_ROLES` per utenti con membership legacy.

**Beneficio aggiuntivo del refactor:** un utente **senza** membership legacy ma
con grant modulare `FolderPermissionGrant(permission_code='request_ecn', effect='allow')`
potrà creare ECN — oggi impossibile. I test esistenti con membership legacy
restano verdi grazie al fallback.

### 5.4 Analisi di non-equivalenza — `view_folder_ecns` vs `AUDIT_ROLES`

Mapping in `projects/resolver.py`:

| Ruolo | Contiene `view_folder_ecns`? |
|-------|------------------------------|
| `reader` | **Sì** (in `_LEGACY_READER_PERMISSIONS`, set base) |
| `author` | **Sì** (eredita reader) |
| `approver` | **Sì** (eredita reader) |
| `auditor` | **Sì** (eredita reader) |
| `manager` | **Sì** (esplicito in manager set) |

**Set ruoli con `view_folder_ecns`:** `{reader, author, approver, auditor, manager}` — **tutti e 5 i ruoli**  
**Set `AUDIT_ROLES`:** `{auditor, manager}`

**Conclusione: nessun match.** Un refactor ingenuo:

```python
has_folder_permission(user, folder, 'view_folder_ecns', include_legacy_fallback=True)
```

sarebbe un'**escalation di permessi reale**: reader, author e approver sulla
cartella otterrebbero visibilità ECN che **oggi non hanno**.

Nessun altro `permission_code` in `_LEGACY_ROLE_PERMISSIONS` corrisponde a
"visibilità ECN solo per auditor/manager". I permessi auditor-specifici
(`view_history`, `view_obsolete_documents`) coprono documenti/versioni, non ECN.

**Nota di prodotto:** `view_folder_ecns` è backfillato (TASK-007-2) ma, come
documentato in `PERMISSIONS_AUDIT.md`, **non è consumato da nessun path runtime**
tranne il resolver stesso. La semantica ECN attuale (`AUDIT_ROLES`) è **più
restrittiva** del permission code omonimo nel modello modulare.

---

## 6. Rischi di cambiare comportamento

### 6.1 Refactor `can_create_ecn` → `request_ecn` (TASK-014)

| Rischio | Probabilità | Mitigazione |
|---------|-------------|-------------|
| Regressione su membership legacy | Bassa | Fallback legacy attivo; set ruoli identico |
| Grant deny modulare blocca creazione ECN | Bassa | Comportamento desiderato (resolver rispettato) |
| Grant allow senza membership abilita creazione | Intenzionale | Nuovo test TASK-014 |

### 6.2 Refactor `can_view_ecn` → `view_folder_ecns` (sconsigliato)

| Rischio | Probabilità | Impatto |
|---------|-------------|---------|
| Escalation: reader/author/approver vedono ECN | **Certa** con refactor ingenuo | Violazione privacy ECN documentata in MB1 |
| Grant deny non applicato se si mantiene legacy path parallelo | Media | Incoerenza permessi |
| Nuovo permission code dedicato (es. `view_ecn_as_auditor`) | — | Richiede decisione prodotto + migrazione + backfill |

**Raccomandazione:** non migrare `can_view_ecn` in TASK-014. Eventuale
migrazione futura richiede uno dei seguenti:

1. Nuovo `permission_code` con semantica `{auditor, manager}` esplicita
2. Accettazione esplicita che `AUDIT_ROLES` resti su legacy membership
3. Ridefinizione prodotto: allargare visibilità ECN a tutti i ruoli reader+

---

## 7. Test esistenti rilevanti

### 7.1 Classe principale: `ECNPermissionsTests` (`ecn/tests.py`, riga 520)

| Test | Funzione | Cosa verifica |
|------|----------|---------------|
| `test_folder_auditor_can_view` (574) | `can_view_ecn` | Membership `AUDITOR` → visibilità ECN |
| `test_folder_author_can_create` (602) | `can_create_ecn` | Membership `AUTHOR` → creazione ECN |
| `test_reader_cannot_create` (594) | `can_create_ecn` | Stranger senza ruolo → negato |
| `test_author_can_create` (591) | `can_create_ecn` | Gruppo globale Authors (path non-cartella) |
| `test_manager_can_create` (588) | `can_create_ecn` | Gruppo globale Managers (path non-cartella) |
| `test_ccb_cannot_create_without_author_role` (598) | `can_create_ecn` | CCB senza author → negato |

### 7.2 Altre classi con `can_view_ecn` (path non-cartella)

| Classe | Test rilevanti |
|--------|----------------|
| `ECNVisibilityPrivacyTests` (2423) | Visibilità globale, CCB assegnato/non assegnato, QM, staff |
| `ECNCoordinatorViewTests` (3289) | Coordinatore CCB designato |

Nessuna di queste classi testa il path cartella oltre a `test_folder_auditor_can_view`.

---

## 8. Gap di test

| Gap | Priorità | Note |
|-----|----------|------|
| Manca `test_folder_manager_can_view` (solo path cartella) | Media | Manager in setUp vede via approvatore assegnato, non via cartella isolata |
| Manca `test_folder_reader_cannot_view` | Media | Conferma esplicita che reader non vede ECN |
| Manca `test_folder_approver_cannot_view` | Bassa | Coerente con `AUDIT_ROLES` |
| Manca test grant modulare `request_ecn` senza membership | Alta | Previsto in TASK-014 |
| Manca test che dimostri grant `view_folder_ecns` ≠ `can_view_ecn` | Bassa | Documentato qui; utile per prevenire refactor errato |
| Nessun test integrazione HTTP per path cartella ECN | Bassa | View tests coprono altri path di visibilità |

---

## 9. Proposta refactor minimo — TASK-014

### 9.1 In scope

**Solo `can_create_ecn`** — sostituire righe 119–120:

```python
# Da:
from projects.permissions import get_folder_role, WRITE_ROLES
if get_folder_role(user, folder) in WRITE_ROLES:

# A:
from projects.resolver import has_folder_permission
if has_folder_permission(user, folder, 'request_ecn', include_legacy_fallback=True):
```

### 9.2 Esplicitamente fuori scope TASK-014

| Elemento | Motivazione |
|----------|-------------|
| `can_view_ecn` | Nessun permission code equivalente a `AUDIT_ROLES`; rischio escalation con `view_folder_ecns` |
| Altre 10 funzioni `can_*` in `ecn/permissions.py` | Non consultano permessi cartella |
| `projects/resolver.py` | Nessuna modifica mapping |
| `projects/permissions.py` | Nessuna modifica |
| Modelli, migrazioni, template | Fuori scope |
| `ProjectFolderMembership` | Resta fonte fallback legacy |

### 9.3 Acceptance criteria TASK-014 (riferimento)

Tratti da `docs/ai/TASKS.md` § TASK-014:

- [ ] `can_create_ecn` usa `has_folder_permission(user, folder, 'request_ecn', include_legacy_fallback=True)`
- [ ] `can_view_ecn` **non toccato**
- [ ] Test esistenti (`test_author_can_create`, `test_folder_author_can_create`, `test_reader_cannot_create`, `test_ccb_cannot_create_without_author_role`) verdi senza modifiche
- [ ] Nuovo test: grant modulare `request_ecn` senza membership → `can_create_ecn` = `True`
- [ ] Fallback legacy invariato (`include_legacy_fallback=True` esplicito)
- [ ] Nessuna migrazione dati, nessuna modifica template/UX/flusso ECN
- [ ] Suite Django reale verde (1208 + nuovo test)

---

## 10. Piano di rollback (TASK-014)

1. **Revert singolo:** ripristinare le 2 righe in `can_create_ecn` (import
   `get_folder_role`/`WRITE_ROLES` e check membership).
2. **Fallback legacy:** resta attivo nel resolver indipendentemente dal revert;
   nessuna modifica a `ProjectFolderMembership` o grant backfillati.
3. **Test:** rimuovere il test grant modulare aggiunto in TASK-014 se presente.
4. **Verifica:** `./scripts/test.sh` deve tornare verde con conteggio test
   precedente.

Il rollback è a **basso rischio** perché il refactor è confinato a una singola
condizione in una funzione, con equivalenza dimostrata per membership legacy.

---

## 11. Cosa NON modificare

- `can_view_ecn` e il check `AUDIT_ROLES` / `get_folder_role`
- Le altre 10 funzioni pubbliche di `ecn/permissions.py`
- `projects/resolver.py` (mapping `_LEGACY_ROLE_PERMISSIONS`)
- `projects/permissions.py` (`get_folder_role`, set di ruoli)
- Modelli (`ProjectFolderMembership`, `FolderPermissionGrant`)
- Migrazioni, template, UX, flusso approvazioni ECN
- Flag `include_legacy_fallback` — non disattivare in nessun path

---

## 12. Acceptance criteria TASK-013

- [x] `docs/ai/ECN_PERMISSIONS_AUDIT.md` creato con tutte le sezioni richieste
- [x] Equivalenza `request_ecn` / `WRITE_ROLES` confermata con evidenza da `_LEGACY_ROLE_PERMISSIONS`
- [x] Non-equivalenza `view_folder_ecns` / `AUDIT_ROLES` confermata con evidenza
- [x] Nessuna modifica applicativa
- [ ] Suite Django reale verde (da confermare con `./scripts/test.sh` — nessuna modifica applicativa prevista; ultimo run documentato: 1208/1208 PASS in TASK-012)

---

## 13. Riferimenti incrociati

| Documento | Sezione |
|-----------|---------|
| `docs/ai/PERMISSIONS_AUDIT.md` | §4.3 bypass resolver, §7 gap G3 |
| `docs/ai/TASKS.md` | TASK-013 (questo audit), TASK-014 (refactor proposto) |
| `ecn/permissions.py` | Righe 89–93 (`can_view_ecn`), 116–121 (`can_create_ecn`) |
| `projects/resolver.py` | Righe 40–84 (`_LEGACY_*_PERMISSIONS`) |
