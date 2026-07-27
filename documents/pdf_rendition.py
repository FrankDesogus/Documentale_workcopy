"""
Motore di rendition del PDF di rappresentazione (TASK-034).

Usa `documents.pdf_policy.get_pdf_strategy` per decidere COSA fare, e qui
lo mette in pratica: conversione automatica quando la strategia lo prevede
(reportlab per formati affidabili, LibreOffice headless se rilevato per i
formati Office), altrimenti nessun tentativo e richiesta di upload manuale.

Vedi docs/ai/PDF_APPROVAL_DECISION.md per l'analisi completa.
"""
import hashlib
import io
import os
import subprocess
import tempfile

from django.utils import timezone

from auditlog.services import create_audit_log
from documents.pdf_policy import PdfStrategy, get_pdf_strategy

PDF_HEADER = b'%PDF-'
_OFFICE_CONVERT_TIMEOUT_SECONDS = 120


def sniff_is_pdf(document_file) -> bool:
    """True se il contenuto reale del file inizia con l'header PDF standard."""
    document_file.file.open('rb')
    try:
        head = document_file.file.read(len(PDF_HEADER))
    finally:
        document_file.file.close()
    return head == PDF_HEADER


def _text_to_pdf_bytes(raw_bytes: bytes) -> bytes:
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.units import mm
    from reportlab.pdfgen import canvas

    text = raw_bytes.decode('utf-8', errors='replace')
    buf = io.BytesIO()
    width, height = A4
    left = 20 * mm
    top = height - 20 * mm
    bottom = 20 * mm

    c = canvas.Canvas(buf, pagesize=A4)
    textobject = c.beginText(left, top)
    textobject.setFont('Courier', 9)
    for line in (text.splitlines() or ['']):
        if textobject.getY() < bottom:
            c.drawText(textobject)
            c.showPage()
            textobject = c.beginText(left, top)
            textobject.setFont('Courier', 9)
        textobject.textLine(line[:130])
    c.drawText(textobject)
    c.save()
    return buf.getvalue()


def _image_to_pdf_bytes(document_file) -> bytes:
    from PIL import Image
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.utils import ImageReader
    from reportlab.pdfgen import canvas

    document_file.file.open('rb')
    try:
        pil_image = Image.open(document_file.file)
        pil_image.load()
    finally:
        document_file.file.close()

    page_width, page_height = A4
    margin = 20
    max_w = page_width - 2 * margin
    max_h = page_height - 2 * margin
    img_w, img_h = pil_image.size
    scale = min(max_w / img_w, max_h / img_h, 1.0)
    draw_w, draw_h = img_w * scale, img_h * scale
    x = (page_width - draw_w) / 2
    y = (page_height - draw_h) / 2

    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=A4)
    c.drawImage(ImageReader(pil_image), x, y, width=draw_w, height=draw_h, mask='auto')
    c.save()
    return buf.getvalue()


def _convert_office_to_pdf(document_file) -> bytes:
    """Converte via `soffice --headless --convert-to pdf`. Solleva RuntimeError su fallimento."""
    with tempfile.TemporaryDirectory() as tmpdir:
        source_name = os.path.basename(document_file.file.name) or f'source.{document_file.extension}'
        source_path = os.path.join(tmpdir, source_name)
        with open(source_path, 'wb') as dst, document_file.file.open('rb') as src:
            for chunk in src.chunks():
                dst.write(chunk)

        try:
            result = subprocess.run(
                ['soffice', '--headless', '--convert-to', 'pdf', '--outdir', tmpdir, source_path],
                capture_output=True,
                timeout=_OFFICE_CONVERT_TIMEOUT_SECONDS,
            )
        except (OSError, subprocess.SubprocessError) as exc:
            raise RuntimeError(f'Impossibile avviare il convertitore: {exc}') from exc

        if result.returncode != 0:
            stderr = (result.stderr or b'').decode(errors='replace').strip()
            raise RuntimeError(stderr or 'Il convertitore ha restituito un errore.')

        base_name = os.path.splitext(source_name)[0]
        out_path = os.path.join(tmpdir, base_name + '.pdf')
        if not os.path.exists(out_path):
            raise RuntimeError('Il convertitore non ha prodotto alcun file PDF di output.')
        with open(out_path, 'rb') as f:
            return f.read()


def _save_representation_pdf_file(pdf_bytes: bytes, base_filename: str, user):
    from django.core.files.base import ContentFile

    from documents.models import DocumentFile

    name = os.path.splitext(base_filename)[0] + '.pdf'
    sha256 = hashlib.sha256(pdf_bytes).hexdigest()
    return DocumentFile.objects.create(
        kind=DocumentFile.Kind.REPRESENTATION_PDF,
        file=ContentFile(pdf_bytes, name=name),
        original_filename=name,
        extension='pdf',
        size=len(pdf_bytes),
        mime_type='application/pdf',
        sha256_hash=sha256,
        uploaded_by=user,
    )


def _clear_representation_state(version):
    version.representation_pdf = None
    version.representation_pdf_source_file = None
    version.representation_pdf_origin = ''
    version.representation_pdf_requires_confirmation = False
    version.representation_pdf_generated_at = None
    version.representation_pdf_confirmed_by = None
    version.representation_pdf_confirmed_at = None


def prepare_representation_pdf(version, user, converter_available=None):
    """
    Analizza il file sorgente corrente di `version` e prepara il PDF di
    rappresentazione quando la strategia lo consente. Va richiamata ogni
    volta che il sorgente di una bozza viene creato o sostituito.

    Se una rappresentazione precedente non corrisponde più al sorgente
    corrente, viene invalidata prima di procedere (mai lasciata "quasi
    aggiornata": o è coerente col sorgente attuale, o non esiste).

    Ritorna la `PdfStrategyDecision` calcolata, per essere mostrata in UI.
    Non solleva eccezioni per un fallimento di conversione: lo registra
    (`approved_pdf_generation_*` non è toccato qui, solo audit) e lascia la
    revisione senza rappresentazione, in attesa di upload manuale.
    """
    from documents.models import DocumentVersion

    source = version.file
    if source is None:
        _clear_representation_state(version)
        version.save()
        return None

    if version.representation_pdf_source_file_id != source.pk:
        was_set = version.representation_pdf_id is not None
        _clear_representation_state(version)
        if was_set:
            create_audit_log(
                user=user, action='REPRESENTATION_PDF_INVALIDATED', instance=version,
                document=version.document, document_version=version,
            )

    decision = get_pdf_strategy(
        source.extension,
        is_pdf_header=sniff_is_pdf(source),
        converter_available=converter_available,
    )
    create_audit_log(
        user=user, action='PDF_STRATEGY_DETERMINED', instance=version,
        new_values={'strategy': decision.strategy, 'reason': decision.reason},
        document=version.document, document_version=version,
    )

    if decision.strategy == PdfStrategy.NATIVE_PDF:
        version.representation_pdf = source
        version.representation_pdf_source_file = source
        version.representation_pdf_origin = DocumentVersion.RepresentationOrigin.NATIVE
        version.representation_pdf_requires_confirmation = False
        version.representation_pdf_generated_at = timezone.now()
        version.save()
        return decision

    if decision.strategy in (PdfStrategy.AUTO_RELIABLE, PdfStrategy.AUTO_UNCERTAIN):
        create_audit_log(
            user=user, action='PDF_CONVERSION_STARTED', instance=version,
            new_values={'converter': decision.converter},
            document=version.document, document_version=version,
        )
        try:
            if decision.strategy == PdfStrategy.AUTO_RELIABLE:
                if source.extension == 'txt':
                    source.file.open('rb')
                    try:
                        raw_bytes = source.file.read()
                    finally:
                        source.file.close()
                    pdf_bytes = _text_to_pdf_bytes(raw_bytes)
                else:
                    pdf_bytes = _image_to_pdf_bytes(source)
            else:
                pdf_bytes = _convert_office_to_pdf(source)
        except Exception as exc:
            create_audit_log(
                user=user, action='PDF_CONVERSION_FAILED', instance=version,
                new_values={'error': str(exc)},
                document=version.document, document_version=version,
            )
            return decision

        representation_file = _save_representation_pdf_file(pdf_bytes, source.original_filename, user)
        version.representation_pdf = representation_file
        version.representation_pdf_source_file = source
        version.representation_pdf_origin = DocumentVersion.RepresentationOrigin.AUTO_CONVERTED
        version.representation_pdf_requires_confirmation = decision.requires_confirmation
        version.representation_pdf_generated_at = timezone.now()
        version.save()
        create_audit_log(
            user=user, action='PDF_CONVERSION_SUCCEEDED', instance=version,
            new_values={'representation_pdf_id': representation_file.pk},
            document=version.document, document_version=version,
        )
        return decision

    # MANUAL_REQUIRED / UNSUPPORTED: nessun tentativo, resta in attesa di upload manuale.
    create_audit_log(
        user=user, action='MANUAL_PDF_REQUIRED', instance=version,
        new_values={'reason': decision.reason},
        document=version.document, document_version=version,
    )
    version.save()
    return decision


def upload_manual_representation_pdf(version, uploaded_file, user):
    """
    Carica manualmente un PDF di rappresentazione. Il caricamento è già una
    dichiarazione consapevole dell'autore: considerato confermato subito,
    nessuna conferma separata richiesta anche se non era obbligatoria.

    Guardrail di congelamento: possibile solo in bozza/rifiutato (stessa
    regola di can_edit_version), verificato anche qui a livello di servizio
    e non solo di permesso di vista, per evitare qualunque sostituzione
    silenziosa una volta avviato il workflow di approvazione (TASK-035).
    """
    from django.core.exceptions import ValidationError
    from documents.models import DocumentVersion

    if version.status not in (DocumentVersion.Status.DRAFT, DocumentVersion.Status.REJECTED):
        raise ValidationError(
            f"Non è possibile modificare il PDF di rappresentazione: la revisione non è in "
            f"bozza. Stato attuale: {version.get_status_display()}."
        )

    head = uploaded_file.read(len(PDF_HEADER))
    uploaded_file.seek(0)
    if head != PDF_HEADER:
        raise ValidationError('Il file caricato non è un PDF valido.')

    from documents.models import DocumentFile, DocumentVersion

    sha256 = hashlib.sha256()
    for chunk in uploaded_file.chunks():
        sha256.update(chunk)
    uploaded_file.seek(0)

    representation_file = DocumentFile.objects.create(
        kind=DocumentFile.Kind.REPRESENTATION_PDF,
        file=uploaded_file,
        original_filename=uploaded_file.name,
        extension='pdf',
        size=uploaded_file.size,
        mime_type='application/pdf',
        sha256_hash=sha256.hexdigest(),
        uploaded_by=user,
    )
    now = timezone.now()
    version.representation_pdf = representation_file
    version.representation_pdf_source_file = version.file
    version.representation_pdf_origin = DocumentVersion.RepresentationOrigin.MANUAL_UPLOAD
    version.representation_pdf_requires_confirmation = False
    version.representation_pdf_generated_at = now
    version.representation_pdf_confirmed_by = user
    version.representation_pdf_confirmed_at = now
    version.save()

    create_audit_log(
        user=user, action='MANUAL_PDF_UPLOADED', instance=version,
        new_values={'representation_pdf_id': representation_file.pk},
        document=version.document, document_version=version,
    )
    return representation_file


def confirm_representation_pdf(version, user):
    from django.core.exceptions import ValidationError
    from documents.models import DocumentVersion

    if version.status not in (DocumentVersion.Status.DRAFT, DocumentVersion.Status.REJECTED):
        raise ValidationError(
            f"Non è possibile confermare il PDF di rappresentazione: la revisione non è in "
            f"bozza. Stato attuale: {version.get_status_display()}."
        )
    if version.representation_pdf_id is None:
        raise ValidationError('Non esiste un PDF di rappresentazione da confermare.')
    if version.representation_pdf_is_stale:
        raise ValidationError(
            'Il file sorgente è cambiato dopo la generazione del PDF di rappresentazione: '
            'rigenerarlo prima di confermare.'
        )

    version.representation_pdf_confirmed_by = user
    version.representation_pdf_confirmed_at = timezone.now()
    version.save(update_fields=['representation_pdf_confirmed_by', 'representation_pdf_confirmed_at'])

    create_audit_log(
        user=user, action='REPRESENTATION_PDF_CONFIRMED', instance=version,
        document=version.document, document_version=version,
    )
    return version
