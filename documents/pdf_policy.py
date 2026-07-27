"""
Servizio centrale di policy PDF.

Risponde alla domanda "qual è la strategia PDF per questo file, in questo
ambiente?" in un unico punto, invece di disperdere `if` sulle estensioni in
form/view/service. Vedi `docs/ai/PDF_APPROVAL_DECISION.md` per l'analisi
completa che motiva le soglie scelte.

Questo modulo è deliberatamente senza dipendenze da Django/modelli: prende
in input un'estensione (e un eventuale esito di sniffing dell'header) e
restituisce una decisione. La rilevazione del convertitore è iniettabile
(`converter_available`) per essere mockabile nei test, senza dipendere da
`soffice` realmente installato in CI.

`CONVERSION_FAILED` non è mai restituito da `get_pdf_strategy`: è l'esito di
un tentativo di conversione realmente eseguito (vedi TASK-034,
`documents/pdf_rendition.py`), non della sola valutazione della policy.
"""
import shutil
from dataclasses import dataclass
from typing import Callable, Optional


class PdfStrategy:
    NATIVE_PDF = 'native_pdf'
    AUTO_RELIABLE = 'auto_reliable'
    AUTO_UNCERTAIN = 'auto_uncertain'
    MANUAL_REQUIRED = 'manual_required'
    UNSUPPORTED = 'unsupported'
    CONVERSION_FAILED = 'conversion_failed'

    CHOICES = (
        (NATIVE_PDF, 'PDF nativo'),
        (AUTO_RELIABLE, 'Conversione automatica affidabile'),
        (AUTO_UNCERTAIN, 'Conversione automatica da confermare'),
        (MANUAL_REQUIRED, 'PDF manuale richiesto'),
        (UNSUPPORTED, 'Formato non supportato'),
        (CONVERSION_FAILED, 'Conversione fallita'),
    )


# Estensioni classificate per strategia. Centralizzate qui: per estendere la
# policy a un nuovo formato si aggiunge l'estensione all'insieme giusto,
# senza toccare la logica di `get_pdf_strategy`.
RELIABLE_TEXT_EXTENSIONS = frozenset({'txt'})
RELIABLE_IMAGE_EXTENSIONS = frozenset({'png', 'jpg', 'jpeg'})
RELIABLE_EXTENSIONS = RELIABLE_TEXT_EXTENSIONS | RELIABLE_IMAGE_EXTENSIONS

# Formati Office convertibili via LibreOffice headless SE disponibile
# nell'ambiente corrente. Mai assunti disponibili solo perché l'estensione
# è "nota": la disponibilità è sempre verificata a runtime.
OFFICE_EXTENSIONS = frozenset({'docx', 'odt', 'xlsx', 'ods', 'pptx', 'odp'})

# Formati noti ma troppo rischiosi per un tentativo automatico (macro,
# CAD/proprietari, desktop publishing): sempre PDF manuale, mai un tentativo.
RISKY_EXTENSIONS = frozenset({
    'docm', 'xlsm', 'pptm',  # macro
    'dwg', 'dxf',  # CAD
    'psd', 'ai', 'indd',  # desktop publishing / proprietari
})

_OFFICE_CONVERTER_BINARY = 'soffice'


@dataclass(frozen=True)
class PdfStrategyDecision:
    strategy: str
    converter: Optional[str]
    requires_confirmation: bool
    reason: str
    error: Optional[str] = None


def _default_converter_available(binary_name: str) -> bool:
    return shutil.which(binary_name) is not None


def get_pdf_strategy(
    extension: str,
    *,
    is_pdf_header: bool = False,
    converter_available: Optional[Callable[[str], bool]] = None,
) -> PdfStrategyDecision:
    """
    Determina la strategia PDF per un'estensione sorgente osservata.

    `extension`: estensione del file (con o senza punto iniziale, case-insensitive).
    `is_pdf_header`: True se il contenuto reale è già stato verificato come
        PDF (header `%PDF-`), a prescindere dall'estensione dichiarata.
    `converter_available`: callable(binary_name) -> bool, per verificare la
        disponibilità di un convertitore esterno. Default: `shutil.which`.
        Iniettabile nei test per non dipendere da binari reali.
    """
    if converter_available is None:
        converter_available = _default_converter_available

    ext = (extension or '').strip().lower().lstrip('.')

    if ext == 'pdf' or is_pdf_header:
        return PdfStrategyDecision(
            strategy=PdfStrategy.NATIVE_PDF,
            converter=None,
            requires_confirmation=False,
            reason='Il sorgente è già un PDF: nessuna conversione necessaria.',
        )

    if ext in RELIABLE_EXTENSIONS:
        return PdfStrategyDecision(
            strategy=PdfStrategy.AUTO_RELIABLE,
            converter='reportlab',
            requires_confirmation=False,
            reason=(
                'Formato senza ambiguità di impaginazione: la conversione '
                'automatica è deterministica e non richiede conferma.'
            ),
        )

    if ext in OFFICE_EXTENSIONS:
        if converter_available(_OFFICE_CONVERTER_BINARY):
            return PdfStrategyDecision(
                strategy=PdfStrategy.AUTO_UNCERTAIN,
                converter=_OFFICE_CONVERTER_BINARY,
                requires_confirmation=True,
                reason=(
                    'Conversione automatica disponibile in questo ambiente '
                    '(LibreOffice), ma la fedeltà (font, macro, impaginazione) '
                    'non è garantita: richiede conferma esplicita dell\'autore.'
                ),
            )
        return PdfStrategyDecision(
            strategy=PdfStrategy.MANUAL_REQUIRED,
            converter=None,
            requires_confirmation=False,
            reason=(
                'Formato Office riconosciuto, ma nessun convertitore '
                'disponibile in questo ambiente: caricare un PDF prodotto '
                'manualmente.'
            ),
        )

    if ext in RISKY_EXTENSIONS:
        return PdfStrategyDecision(
            strategy=PdfStrategy.MANUAL_REQUIRED,
            converter=None,
            requires_confirmation=False,
            reason=(
                'Formato con macro, CAD o layout di stampa non gestibile in '
                'modo affidabile in automatico: caricare un PDF prodotto '
                'manualmente.'
            ),
        )

    return PdfStrategyDecision(
        strategy=PdfStrategy.UNSUPPORTED,
        converter=None,
        requires_confirmation=False,
        reason=(
            f"Estensione '.{ext}' non riconosciuta dalla policy di conversione: "
            'caricare un PDF prodotto manualmente.'
            if ext else
            'Nessuna estensione riconoscibile sul file: caricare un PDF prodotto manualmente.'
        ),
    )
