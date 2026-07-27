"""
Generazione del PDF approvato (TASK-036).

Flusso: PDF di rappresentazione congelato + pagina finale con il registro
delle approvazioni (e le eventuali firme visive) = PDF approvato. Non
modifica mai il PDF sottoposto agli approvatori: unisce (`pypdf`) le sue
pagine con una pagina nuova generata da zero (`reportlab`).

Va chiamata SEMPRE dopo il commit della transazione che ha registrato
l'approvazione: un errore qui non deve mai invalidare un'approvazione già
registrata correttamente. Idempotente: se `approved_pdf_generation_status`
è già SUCCESS, non rigenera (salvo `force=True`, riservato alla
rigenerazione amministrativa di un fallimento precedente).
"""
import hashlib
import io

from django.utils import timezone

from auditlog.services import create_audit_log
from documents.models import DocumentVersion

NOTE_NO_DIGITAL_SIGNATURE = (
    "Le firme riprodotte rappresentano graficamente le approvazioni registrate "
    "nel sistema documentale e non costituiscono firma digitale o firma "
    "elettronica qualificata."
)


def _build_registry_page_pdf(version, approval_request, decisions):
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.units import mm
    from reportlab.lib.utils import ImageReader
    from reportlab.pdfgen import canvas

    buf = io.BytesIO()
    width, height = A4
    left = 20 * mm
    right = width - 20 * mm
    y = height - 25 * mm

    c = canvas.Canvas(buf, pagesize=A4)

    def line(text, size=10, bold=False, gap=6 * mm):
        nonlocal y
        c.setFont('Helvetica-Bold' if bold else 'Helvetica', size)
        c.drawString(left, y, text)
        y -= gap

    line('REGISTRO DI APPROVAZIONE', size=14, bold=True, gap=10 * mm)
    line('Stato: APPROVATO', size=12, bold=True)
    line(f'Codice documento: {version.document.code}')
    line(f'Titolo: {version.document.title}')
    line(f'Revisione: {version.revision_label} (n. {version.revision_number})')
    line(f'Modalità approvazione: {approval_request.get_approval_policy_display()}')
    conclusion = version.approved_at.strftime('%d/%m/%Y %H:%M') if version.approved_at else '—'
    line(f'Data di conclusione: {conclusion}', gap=10 * mm)

    line('Approvatori', size=11, bold=True, gap=8 * mm)
    for decision in decisions:
        name = decision.signature_display_name or (
            decision.approver.get_full_name() or decision.approver.username
        )
        line(f'{name} — Approvatore', size=10, bold=True, gap=5 * mm)
        line(f'Decisione: Approvato — {decision.decided_at.strftime("%d/%m/%Y %H:%M")}', gap=5 * mm)

        if decision.signature_used_id and decision.signature_used.image:
            try:
                decision.signature_used.image.open('rb')
                try:
                    from PIL import Image
                    pil_image = Image.open(decision.signature_used.image)
                    pil_image.load()
                finally:
                    decision.signature_used.image.close()
                img_w, img_h = pil_image.size
                max_w, max_h = 40 * mm, 15 * mm
                scale = min(max_w / img_w, max_h / img_h, 1.0)
                draw_w, draw_h = img_w * scale, img_h * scale
                if y - draw_h < 20 * mm:
                    c.showPage()
                    y = height - 25 * mm
                c.drawImage(
                    ImageReader(pil_image), left, y - draw_h,
                    width=draw_w, height=draw_h, mask='auto',
                )
                y -= draw_h + 4 * mm
            except Exception:
                # Un problema nel disegnare la firma PNG non deve mai far
                # fallire l'intera generazione: il registro resta valido
                # anche solo con la firma testuale.
                pass

        y -= 4 * mm
        if y < 30 * mm:
            c.showPage()
            y = height - 25 * mm

    if y < 40 * mm:
        c.showPage()
        y = height - 25 * mm
    y -= 6 * mm
    c.setFont('Helvetica-Oblique', 8)
    c.drawString(left, y, NOTE_NO_DIGITAL_SIGNATURE[:110])
    y -= 4 * mm
    c.drawString(left, y, NOTE_NO_DIGITAL_SIGNATURE[110:])

    c.save()
    return buf.getvalue()


def _merge_representation_with_registry(representation_pdf_bytes, registry_pdf_bytes):
    from pypdf import PdfReader, PdfWriter

    writer = PdfWriter()
    for reader_bytes in (representation_pdf_bytes, registry_pdf_bytes):
        reader = PdfReader(io.BytesIO(reader_bytes))
        for page in reader.pages:
            writer.add_page(page)

    out = io.BytesIO()
    writer.write(out)
    return out.getvalue()


def generate_approved_pdf(version, force=False):
    """
    Genera il PDF approvato per una revisione già APPROVED. Non solleva
    eccezioni: un fallimento è registrato su
    `approved_pdf_generation_status`/`_error` e in audit, mai propagato al
    chiamante (che tipicamente ha appena chiuso con successo l'approvazione).
    """
    if version.status != DocumentVersion.Status.APPROVED:
        return

    if not force and version.approved_pdf_generation_status == DocumentVersion.ApprovedPdfStatus.SUCCESS:
        return

    approval_request = (
        version.approval_requests
        .filter(status='APPROVED')
        .order_by('-completed_at')
        .first()
    )
    if approval_request is None or version.representation_pdf_id is None:
        version.approved_pdf_generation_status = DocumentVersion.ApprovedPdfStatus.FAILED
        version.approved_pdf_generation_error = (
            'Nessuna richiesta di approvazione conclusa o PDF di rappresentazione assente.'
        )
        version.save(update_fields=['approved_pdf_generation_status', 'approved_pdf_generation_error'])
        return

    decisions = list(
        approval_request.decisions.filter(decision='APPROVED')
        .select_related('approver', 'signature_used')
        .order_by('decided_at')
    )

    try:
        version.representation_pdf.file.open('rb')
        try:
            representation_bytes = version.representation_pdf.file.read()
        finally:
            version.representation_pdf.file.close()

        registry_bytes = _build_registry_page_pdf(version, approval_request, decisions)
        merged_bytes = _merge_representation_with_registry(representation_bytes, registry_bytes)
    except Exception as exc:
        version.approved_pdf_generation_status = DocumentVersion.ApprovedPdfStatus.FAILED
        version.approved_pdf_generation_error = str(exc)
        version.save(update_fields=['approved_pdf_generation_status', 'approved_pdf_generation_error'])
        create_audit_log(
            user=version.approved_by, action='APPROVED_PDF_GENERATION_FAILED', instance=version,
            new_values={'error': str(exc)}, document=version.document, document_version=version,
        )
        return

    from documents.models import DocumentFile

    name = f'{version.document.code}-rev{version.revision_label}-approvato.pdf'
    approved_file = DocumentFile.objects.create(
        kind=DocumentFile.Kind.APPROVED_PDF,
        file=_content_file(merged_bytes, name),
        original_filename=name,
        extension='pdf',
        size=len(merged_bytes),
        mime_type='application/pdf',
        sha256_hash=hashlib.sha256(merged_bytes).hexdigest(),
        uploaded_by=version.approved_by,
    )

    version.approved_pdf = approved_file
    version.approved_pdf_generated_at = timezone.now()
    version.approved_pdf_generation_status = DocumentVersion.ApprovedPdfStatus.SUCCESS
    version.approved_pdf_generation_error = ''
    version.save(update_fields=[
        'approved_pdf', 'approved_pdf_generated_at',
        'approved_pdf_generation_status', 'approved_pdf_generation_error',
    ])

    create_audit_log(
        user=version.approved_by, action='APPROVED_PDF_GENERATED', instance=version,
        new_values={'approved_pdf_id': approved_file.pk},
        document=version.document, document_version=version,
    )


def _content_file(data: bytes, name: str):
    from django.core.files.base import ContentFile
    return ContentFile(data, name=name)
