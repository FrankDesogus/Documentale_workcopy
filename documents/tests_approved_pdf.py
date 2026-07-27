"""
Test della generazione del PDF approvato (TASK-036): pagina finale con
registro delle approvazioni, unita (mai sovrascritta) al PDF di
rappresentazione congelato.
"""
import io

from django.contrib.auth.models import User
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings

from accounts.models import UserSignature
from approvals.models import ApprovalDecision, ApprovalRequest
from approvals.services import approve_version, reject_version
from auditlog.models import AuditLog
from documents.models import Document, DocumentVersion
from documents.services import create_document_file, create_new_revision, submit_version_for_approval

LOCMEM = 'django.core.mail.backends.locmem.EmailBackend'


def make_document(code='APDFDOC-001', owner=None):
    return Document.objects.create(
        code=code, title='Documento PDF approvato', category=Document.Category.QUALITY,
        owner=owner, created_by=owner,
    )


def _real_pdf_bytes(text='Documento di test'):
    from reportlab.lib.pagesizes import A4
    from reportlab.pdfgen import canvas
    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=A4)
    c.drawString(50, 800, text)
    c.save()
    return buf.getvalue()


def make_pdf_source(user, name='a.pdf', content=None):
    return create_document_file(
        SimpleUploadedFile(name, content or _real_pdf_bytes(), content_type='application/pdf'), user,
    )


def _png_bytes():
    from PIL import Image
    buf = io.BytesIO()
    Image.new('RGBA', (10, 10), (0, 0, 0, 255)).save(buf, format='PNG')
    return buf.getvalue()


@override_settings(EMAIL_BACKEND=LOCMEM)
class ApprovedPdfGenerationTests(TestCase):

    def setUp(self):
        self.author = User.objects.create_user('apdf_author', password='pw')
        self.approver = User.objects.create_user('apdf_approver', password='pw')
        self.doc = make_document(owner=self.author)

    def _make_submitted_version(self, approvers=None, policy='any'):
        source = make_pdf_source(self.author)
        version = create_new_revision(self.doc, self.author, '01', 1, file=source)
        submit_version_for_approval(
            version=version, requested_by=self.author,
            approvers=approvers or [self.approver], approval_policy=policy,
        )
        version.refresh_from_db()
        return version

    def test_approval_generates_approved_pdf(self):
        version = self._make_submitted_version()
        ar = ApprovalRequest.objects.get(document_version=version)
        approve_version(ar, self.approver)
        version.refresh_from_db()
        self.assertEqual(
            version.approved_pdf_generation_status, DocumentVersion.ApprovedPdfStatus.SUCCESS,
        )
        self.assertIsNotNone(version.approved_pdf_id)
        self.assertNotEqual(version.approved_pdf_id, version.representation_pdf_id)

    def test_approved_pdf_has_more_pages_than_representation(self):
        from pypdf import PdfReader
        version = self._make_submitted_version()
        ar = ApprovalRequest.objects.get(document_version=version)
        approve_version(ar, self.approver)
        version.refresh_from_db()

        version.representation_pdf.file.open('rb')
        rep_pages = len(PdfReader(version.representation_pdf.file).pages)
        version.representation_pdf.file.close()

        version.approved_pdf.file.open('rb')
        approved_pages = len(PdfReader(version.approved_pdf.file).pages)
        version.approved_pdf.file.close()

        self.assertGreater(approved_pages, rep_pages)

    def test_rejected_request_never_generates_approved_pdf(self):
        version = self._make_submitted_version()
        ar = ApprovalRequest.objects.get(document_version=version)
        reject_version(ar, self.approver, rejection_reason='non conforme')
        version.refresh_from_db()
        self.assertIsNone(version.approved_pdf_id)
        self.assertEqual(
            version.approved_pdf_generation_status, DocumentVersion.ApprovedPdfStatus.NOT_STARTED,
        )

    def test_all_policy_registry_contains_every_approver(self):
        a2 = User.objects.create_user('apdf_a2', password='pw')
        version = self._make_submitted_version(approvers=[self.approver, a2], policy='all')
        ar = ApprovalRequest.objects.get(document_version=version)
        approve_version(ar, self.approver)
        version.refresh_from_db()
        self.assertEqual(version.approved_pdf_generation_status, DocumentVersion.ApprovedPdfStatus.NOT_STARTED)
        approve_version(ar, a2)
        version.refresh_from_db()
        self.assertEqual(version.approved_pdf_generation_status, DocumentVersion.ApprovedPdfStatus.SUCCESS)
        decisions = ApprovalDecision.objects.filter(approval_request=ar, decision='APPROVED')
        self.assertEqual(decisions.count(), 2)

    def test_idempotent_generation_does_not_duplicate_file(self):
        from documents.approved_pdf import generate_approved_pdf
        from documents.models import DocumentFile

        version = self._make_submitted_version()
        ar = ApprovalRequest.objects.get(document_version=version)
        approve_version(ar, self.approver)
        version.refresh_from_db()
        first_id = version.approved_pdf_id

        generate_approved_pdf(version)  # senza force: no-op
        version.refresh_from_db()
        self.assertEqual(version.approved_pdf_id, first_id)
        self.assertEqual(DocumentFile.objects.filter(kind=DocumentFile.Kind.APPROVED_PDF).count(), 1)

    def test_force_regeneration_creates_new_file(self):
        from documents.approved_pdf import generate_approved_pdf

        version = self._make_submitted_version()
        ar = ApprovalRequest.objects.get(document_version=version)
        approve_version(ar, self.approver)
        version.refresh_from_db()
        first_id = version.approved_pdf_id

        generate_approved_pdf(version, force=True)
        version.refresh_from_db()
        self.assertNotEqual(version.approved_pdf_id, first_id)

    def test_approval_without_any_source_marks_generation_failed_without_blocking_approval(self):
        version = create_new_revision(self.doc, self.author, '01', 1)  # nessun file
        submit_version_for_approval(
            version=version, requested_by=self.author,
            approvers=[self.approver], approval_policy='any',
        )
        ar = ApprovalRequest.objects.get(document_version=version)
        approve_version(ar, self.approver)  # non deve sollevare
        version.refresh_from_db()
        self.assertEqual(version.status, DocumentVersion.Status.APPROVED)
        self.assertEqual(
            version.approved_pdf_generation_status, DocumentVersion.ApprovedPdfStatus.FAILED,
        )
        self.assertIsNone(version.approved_pdf_id)

    def test_signature_snapshot_frozen_after_signature_change(self):
        png = _png_bytes()
        signature = UserSignature.objects.create(
            user=self.approver,
            image=SimpleUploadedFile('sig.png', png, content_type='image/png'),
            original_filename='sig.png',
        )
        version = self._make_submitted_version()
        ar = ApprovalRequest.objects.get(document_version=version)
        approve_version(ar, self.approver)

        decision = ApprovalDecision.objects.get(approval_request=ar, approver=self.approver)
        self.assertEqual(decision.signature_used_id, signature.pk)
        self.assertEqual(decision.signature_display_name, 'apdf_approver')

        # L'utente sostituisce la firma DOPO l'approvazione: la decisione
        # storica non deve cambiare.
        signature.is_active = False
        signature.save(update_fields=['is_active'])
        new_signature = UserSignature.objects.create(
            user=self.approver,
            image=SimpleUploadedFile('sig2.png', png, content_type='image/png'),
            original_filename='sig2.png',
        )
        decision.refresh_from_db()
        self.assertEqual(decision.signature_used_id, signature.pk)
        self.assertNotEqual(decision.signature_used_id, new_signature.pk)

    def test_audit_log_generated_event(self):
        version = self._make_submitted_version()
        ar = ApprovalRequest.objects.get(document_version=version)
        approve_version(ar, self.approver)
        self.assertTrue(
            AuditLog.objects.filter(action='APPROVED_PDF_GENERATED', object_id=str(version.pk)).exists()
        )


@override_settings(EMAIL_BACKEND=LOCMEM)
class ApprovalAndDocumentUiTests(TestCase):
    """TASK-037/038: link di download nella pagina approvazione e nella pagina documento."""

    def setUp(self):
        from django.contrib.auth.models import Group
        self.author = User.objects.create_user('ui_author', password='pw')
        self.approver = User.objects.create_user('ui_approver', password='pw')
        self.outsider = User.objects.create_user('ui_outsider', password='pw')
        Group.objects.get_or_create(name='Document Authors')[0].user_set.add(self.author)
        self.doc = make_document(code='UIDOC-001', owner=self.author)
        source = make_pdf_source(self.author)
        self.version = create_new_revision(self.doc, self.author, '01', 1, file=source)
        submit_version_for_approval(
            version=self.version, requested_by=self.author,
            approvers=[self.approver], approval_policy='any',
        )
        self.ar = ApprovalRequest.objects.get(document_version=self.version)

    def test_approval_detail_shows_representation_pdf_link(self):
        from django.urls import reverse
        self.client.login(username='ui_approver', password='pw')
        response = self.client.get(reverse('approval_detail', args=[self.ar.pk]))
        self.assertEqual(response.status_code, 200)
        self.assertContains(
            response, reverse('version_representation_pdf_download', args=[self.version.pk]),
        )

    def test_assigned_approver_can_download_representation_pdf(self):
        from django.urls import reverse
        self.client.login(username='ui_approver', password='pw')
        response = self.client.get(
            reverse('version_representation_pdf_download', args=[self.version.pk]),
        )
        self.assertEqual(response.status_code, 200)

    def test_outsider_cannot_download_representation_pdf(self):
        from django.urls import reverse
        self.client.login(username='ui_outsider', password='pw')
        response = self.client.get(
            reverse('version_representation_pdf_download', args=[self.version.pk]),
        )
        self.assertEqual(response.status_code, 403)

    def test_document_detail_shows_approved_pdf_as_principal(self):
        from django.urls import reverse
        approve_version(self.ar, self.approver)
        self.version.refresh_from_db()
        self.client.login(username='ui_approver', password='pw')
        response = self.client.get(reverse('document_detail', args=[self.doc.pk]))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, reverse('version_approved_pdf_download', args=[self.version.pk]))
        self.assertContains(response, 'Scarica PDF approvato')

    def test_approved_pdf_downloadable_by_authorized_viewer(self):
        # Documento senza project_folder: come per can_view_version già
        # esistente, una revisione approvata e corrente è visibile a
        # qualunque utente autenticato (nessuna restrizione di cartella
        # impostata) — qui si verifica solo che il download funzioni con
        # gli stessi permessi già in vigore per la versione, non se ne
        # introduce uno nuovo più permissivo.
        from django.urls import reverse
        approve_version(self.ar, self.approver)
        self.version.refresh_from_db()

        self.client.login(username='ui_approver', password='pw')
        response = self.client.get(reverse('version_approved_pdf_download', args=[self.version.pk]))
        self.assertEqual(response.status_code, 200)

    def test_approved_pdf_download_requires_login(self):
        from django.urls import reverse
        approve_version(self.ar, self.approver)
        self.version.refresh_from_db()
        response = self.client.get(reverse('version_approved_pdf_download', args=[self.version.pk]))
        self.assertEqual(response.status_code, 302)  # redirect al login
