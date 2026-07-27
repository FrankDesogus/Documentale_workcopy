"""
TASK-039: verifica trasversale che l'intero ciclo di vita PDF/firma scriva
gli eventi di audit attesi. Non riguarda i dettagli di negozio (già coperti
nei rispettivi moduli): qui si controlla solo che ogni transizione di stato
rilevante produca la riga di `AuditLog` corrispondente.
"""
import io
from unittest.mock import patch

from django.contrib.auth.models import User
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from django.urls import reverse

from accounts.models import UserSignature
from approvals.models import ApprovalRequest
from approvals.services import approve_version
from auditlog.models import AuditLog
from documents.models import Document
from documents.pdf_rendition import confirm_representation_pdf, upload_manual_representation_pdf
from documents.services import create_document_file, create_new_revision, submit_version_for_approval

LOCMEM = 'django.core.mail.backends.locmem.EmailBackend'


def make_document(code='AUDITDOC-001', owner=None):
    return Document.objects.create(
        code=code, title='Documento audit', category=Document.Category.QUALITY,
        owner=owner, created_by=owner,
    )


def _real_pdf_bytes():
    from reportlab.lib.pagesizes import A4
    from reportlab.pdfgen import canvas
    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=A4)
    c.drawString(50, 800, 'contenuto')
    c.save()
    return buf.getvalue()


def _png_bytes():
    from PIL import Image
    buf = io.BytesIO()
    Image.new('RGBA', (5, 5)).save(buf, format='PNG')
    return buf.getvalue()


@override_settings(EMAIL_BACKEND=LOCMEM)
class PdfLifecycleAuditTrailTests(TestCase):

    def setUp(self):
        self.author = User.objects.create_user('audit_author', password='pw')
        self.approver = User.objects.create_user('audit_approver', password='pw')
        self.doc = make_document(owner=self.author)

    def _actions_for(self, version):
        return set(
            AuditLog.objects.filter(object_id=str(version.pk)).values_list('action', flat=True)
        )

    def test_native_pdf_flow_records_strategy_and_submission(self):
        source = create_document_file(
            SimpleUploadedFile('a.pdf', _real_pdf_bytes(), content_type='application/pdf'), self.author,
        )
        version = create_new_revision(self.doc, self.author, '01', 1, file=source)
        submit_version_for_approval(
            version=version, requested_by=self.author,
            approvers=[self.approver], approval_policy='any',
        )
        ar = ApprovalRequest.objects.get(document_version=version)
        approve_version(ar, self.approver)

        actions = self._actions_for(version)
        self.assertIn('PDF_STRATEGY_DETERMINED', actions)
        self.assertIn('SUBMITTED_FOR_APPROVAL', actions)
        self.assertIn('APPROVED_PDF_GENERATED', actions)

    def test_office_conversion_flow_records_start_success_and_confirmation(self):
        source = create_document_file(
            SimpleUploadedFile('report.docx', b'fake docx', content_type='application/octet-stream'),
            self.author,
        )
        version = create_new_revision(self.doc, self.author, '01', 1)
        version.file = source
        version.save(update_fields=['file'])
        from documents.pdf_rendition import prepare_representation_pdf
        with patch('documents.pdf_rendition._convert_office_to_pdf', return_value=_real_pdf_bytes()):
            prepare_representation_pdf(version, self.author, converter_available=lambda _n: True)
        confirm_representation_pdf(version, self.author)

        actions = self._actions_for(version)
        self.assertIn('PDF_CONVERSION_STARTED', actions)
        self.assertIn('PDF_CONVERSION_SUCCEEDED', actions)
        self.assertIn('REPRESENTATION_PDF_CONFIRMED', actions)

    def test_failed_conversion_records_failure(self):
        source = create_document_file(
            SimpleUploadedFile('report.docx', b'fake docx', content_type='application/octet-stream'),
            self.author,
        )
        version = create_new_revision(self.doc, self.author, '01', 1)
        version.file = source
        version.save(update_fields=['file'])
        from documents.pdf_rendition import prepare_representation_pdf
        with patch('documents.pdf_rendition._convert_office_to_pdf', side_effect=RuntimeError('x')):
            prepare_representation_pdf(version, self.author, converter_available=lambda _n: True)

        self.assertIn('PDF_CONVERSION_FAILED', self._actions_for(version))

    def test_manual_required_and_upload_and_invalidation(self):
        source = create_document_file(
            SimpleUploadedFile('drawing.dwg', b'cad', content_type='application/octet-stream'), self.author,
        )
        version = create_new_revision(self.doc, self.author, '01', 1, file=source)
        self.assertIn('MANUAL_PDF_REQUIRED', self._actions_for(version))

        pdf = SimpleUploadedFile('rep.pdf', _real_pdf_bytes(), content_type='application/pdf')
        upload_manual_representation_pdf(version, pdf, self.author)
        self.assertIn('MANUAL_PDF_UPLOADED', self._actions_for(version))

        source2 = create_document_file(
            SimpleUploadedFile('drawing2.dwg', b'cad2', content_type='application/octet-stream'), self.author,
        )
        from documents.services import update_draft_version
        update_draft_version(
            version, self.author, revision_label='01', revision_number=1,
            change_summary='', new_file=source2,
        )
        self.assertIn('REPRESENTATION_PDF_INVALIDATED', self._actions_for(version))

    def test_approved_pdf_generation_failure_recorded(self):
        version = create_new_revision(self.doc, self.author, '01', 1)  # nessun file: gate non si applica
        submit_version_for_approval(
            version=version, requested_by=self.author,
            approvers=[self.approver], approval_policy='any',
        )
        ar = ApprovalRequest.objects.get(document_version=version)
        approve_version(ar, self.approver)
        self.assertIn('APPROVED_PDF_GENERATION_FAILED', self._actions_for(version))

    def test_signature_upload_and_removal_audit(self):
        self.client.login(username='audit_author', password='pw')
        self.client.post(reverse('signature_manage'), {
            'image': SimpleUploadedFile('sig.png', _png_bytes(), content_type='image/png'),
        })
        signature = UserSignature.objects.get(user=self.author)
        self.assertTrue(
            AuditLog.objects.filter(action='SIGNATURE_UPLOADED', object_id=str(signature.pk)).exists()
        )
        self.client.post(reverse('signature_manage'), {'action': 'remove'})
        self.assertTrue(
            AuditLog.objects.filter(action='SIGNATURE_REMOVED', object_id=str(signature.pk)).exists()
        )
