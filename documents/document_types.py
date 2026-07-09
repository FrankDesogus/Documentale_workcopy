"""
Vocabolario controllato per Document.document_type (TASK-020).

Le scelte dipendono dalla Categoria del documento (Document.Category):
  QUALITY -> SYSTEM_DOCUMENT_TYPE_CHOICES  ("documenti di sistema", 35 tipi)
  PROJECT -> PROJECT_DOCUMENT_TYPE_CHOICES ("documenti di progetto", 44 tipi)

Le due liste sono liste di tuple (non django.db.models.TextChoices) per
poter rappresentare SCTY due volte con etichette diverse ("Manuale
Security" / "Procedura Security") - un Enum Python non lo permetterebbe
(la seconda voce diventerebbe un alias silenzioso della prima). Limite
noto: una volta salvato, il valore memorizzato per entrambe le voci SCTY
è identico ("SCTY") - non si può distinguere a posteriori quale delle due
etichette è stata scelta. Alcuni valori (es. "3DPD", "3DAD") iniziano con
una cifra, altro motivo per cui una tupla è più adatta di un Enum qui.

Fonte: due elenchi aziendali forniti dall'operatore (non versionati in
questo repository). "SDD__" nella fonte "documenti di progetto" è stato
normalizzato a "SDD_" per coerenza con lo schema a 4 caratteri degli altri
acronimi brevi (es. "ATP_", "ECP_", "DDT_").
"""

SYSTEM_DOCUMENT_TYPE_CHOICES = [
    ('CNTY', 'CNTY — Certificato di Conformità'),
    ('CONF', 'CONF — Piano Gestione Configurazione'),
    ('DDT_', 'DDT_ — Documento di Trasporto'),
    ('ECOM', 'ECOM — Comunicazione esterna'),
    ('ENVD', 'ENVD — Documenti Iso Ambiente'),
    ('ENVR', 'ENVR — Procedure Ambiente'),
    ('FAIR', 'FAIR — Ispezione del primo articolo'),
    ('INTA', 'INTA — Audit Interno'),
    ('INVOICE', 'INVOICE — Fattura'),
    ('MDAC', 'MDAC — Apertura di Commessa'),
    ('LTTR', 'LTTR — Lettera'),
    ('MDLL', 'MDLL — Modelli'),
    ('MNTR', "MNTR — Rapporto d'Intervento"),
    ('MOME', 'MOME — Verbale di riunione'),
    ('MTRR', 'MTRR — Verbale Non Conformità'),
    ('NRMA', 'NRMA — RMA (Return Merchandise Authorization)'),
    ('OFFR', 'OFFR — Offerta'),
    ('PRCH', 'PRCH — Ordine di Acquisto'),
    ('PRCY', 'PRCY — Manuale Privacy / Procedure Privacy'),
    ('PRMP', 'PRMP — Piano di Gestione Programma'),
    ('PROP', 'PROP — Procedure di Processo Operativo'),
    ('PRST', 'PRST — Presentazione'),
    ('QIMP', 'QIMP — Proposta di Miglioramento per la Qualità'),
    ('QLTP', 'QLTP — Piano della Qualità'),
    ('QTTR', 'QTTR — Richiesta di Offerta'),
    ('RISK', 'RISK — Piano di Gestione dei Rischi'),
    ('RMTX', 'RMTX — Matrice Responsabilità'),
    ('SCTY', 'SCTY — Manuale Security'),
    ('SCTY', 'SCTY — Procedura Security'),
    ('SFTY', 'SFTY — Procedure Safety'),
    ('SYSD', 'SYSD — Documenti di Sistema'),
    ('SYSP', 'SYSP — Procedure di Sistema'),
    ('VNDA', 'VNDA — Audit Fornitori'),
    ('VNDL', 'VNDL — Elenco Fornitori Qualificati'),
    ('WIPO', 'WIPO — Istruzione Operativa'),
    ('WRKI', 'WRKI — Istruzioni di Lavoro'),
]

PROJECT_DOCUMENT_TYPE_CHOICES = [
    ('ASSD', 'ASSD — Disegno Assemblaggio'),
    ('ASSY', 'ASSY — Assieme'),
    ('ATP_', 'ATP_ — Procedura dei test di Accettazione'),
    ('ATR_', 'ATR_ — Rapporto dei test di Accettazione'),
    ('SDD_', 'SDD_ — Disegno di Progetto'),
    ('DTSH', 'DTSH — Foglio Tecnico'),
    ('ECP_', 'ECP_ — Proposta di Variante'),
    ('ELTD', 'ELTD — Schema Elettrico'),
    ('EXPD', 'EXPD — Disegno Esploso'),
    ('SPKT', 'SPKT — Elenco Parti di Rispetto'),
    ('FLOW', 'FLOW — Diagramma di Flusso'),
    ('GRBF', 'GRBF — Files Gerber'),
    ('IDD_', 'IDD_ — Documento di definizione interfacce'),
    ('INPR', 'INPR — Rapporto di Processo'),
    ('MCHD', 'MCHD — Disegno Meccanico'),
    ('DIMD', 'DIMD — Disegno dimensionale'),
    ('PCBD', 'PCBD — PCB Master'),
    ('PRJP', 'PRJP — Piano di Progetto'),
    ('DJF_', 'DJF_ — Design justification file'),
    ('RMT_', 'RMT_ — Documentazione di Affidabilità, manutenibilità e testabilità'),
    ('ESSP', 'ESSP — Procedure di screening ambientali'),
    ('ESSR', 'ESSR — Report di screening ambientali'),
    ('QTP_', 'QTP_ — Procedura di Test di qualifica'),
    ('QTR_', 'QTR_ — Rapporto di test di qualifica'),
    ('QTPL', 'QTPL — Piano di test di qualifica'),
    ('DDP_', 'DDP_ — Design Declaration Performance'),
    ('MFGS', 'MFGS — Specifica di costruzione (verso cliente)'),
    ('CMX_', 'CMX_ — Matrice di Conformità'),
    ('BLKD', 'BLKD — Schema a blocchi'),
    ('ICD_', 'ICD_ — Documento di controllo dell’interfaccia'),
    ('3DPD', '3DPD — Disegno 3D di una parte'),
    ('3DAD', '3DAD — Disegno 3D di un’assieme'),
    ('PRJR', 'PRJR — Rapporto di Progetto'),
    ('PRDT', 'PRDT — Albero Documentazione di Prodotto'),
    ('PRTL', 'PRTL — Lista Parti'),
    ('SLKD', 'SLKD — Serigrafia'),
    ('UDD_', 'UDD_ — Descrizione Progetto Unità'),
    ('USRM', 'USRM — Manuale d’Uso'),
    ('TCHM', 'TCHM — Manuale Tecnico'),
    ('TCHR', 'TCHR — Relazione Tecnica'),
    ('TCHS', 'TCHS — Specifica Tecnica'),
    ('TSTP', 'TSTP — Procedura di Collaudo'),
    ('TSTR', 'TSTR — Report di Collaudo'),
    ('VTP_', 'VTP_ — Procedura del test di verifica'),
]

DOCUMENT_TYPE_CHOICES = SYSTEM_DOCUMENT_TYPE_CHOICES + PROJECT_DOCUMENT_TYPE_CHOICES

_CHOICES_BY_CATEGORY = {
    'QUALITY': SYSTEM_DOCUMENT_TYPE_CHOICES,
    'PROJECT': PROJECT_DOCUMENT_TYPE_CHOICES,
}

CATEGORY_BY_DOCUMENT_TYPE_VALUE = {
    value: category
    for category, choices in _CHOICES_BY_CATEGORY.items()
    for value, _label in choices
}


def document_type_choices_for_category(category: str) -> list:
    """Restituisce le scelte di tipo documento valide per la categoria data.

    Categoria sconosciuta/vuota -> lista vuota (nessun tipo valido finché
    la categoria non è nota).
    """
    return _CHOICES_BY_CATEGORY.get(category, [])


def is_valid_document_type_for_category(document_type: str, category: str) -> bool:
    """True se document_type è tra i valori validi per la categoria data.

    Stringa vuota è sempre valida (il campo è opzionale).
    """
    if not document_type:
        return True
    valid_values = {value for value, _ in document_type_choices_for_category(category)}
    return document_type in valid_values
