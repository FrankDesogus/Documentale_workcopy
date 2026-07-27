"""
Test del motore di rendition PDF (TASK-034). Nessun test dipende da
`soffice` reale: la conversione Office è sempre mockata via
`unittest.mock.patch` su `_convert_office_to_pdf`, e la disponibilità del
convertitore è iniettata via `converter_available`.
"""
import io
from unittest.mock import patch

from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from django.urls import reverse

from auditlog.models import AuditLog
from documents.models import Document, DocumentFile, DocumentVersion
from documents.pdf_rendition import (
    confirm_representation_pdf,
    prepare_representation_pdf,
    upload_manual_representation_pdf,
)
from documents.services import create_document_file, create_new_revision, update_draft_version


def make_document(code='RENDDOC-001', owner=None):
    return Document.objects.create(
        code=code, title='Documento rendition', category=Document.Category.QUALITY,
        owner=owner, created_by=owner,
    )


def _png_bytes():
    from PIL import Image
    buf = io.BytesIO()
    Image.new('RGB', (20, 10), (255, 0, 0)).save(buf, format='PNG')
    return buf.getvalue()


def _converter_present(_name):
    return True


def _converter_absent(_name):
    return False


class PrepareRepresentationPdfNativeTests(TestCase):

    def setUp(self):
        self.user = User.objects.create_user('rend_native', password='pw')
        self.doc = make_document(owner=self.user)

    def test_native_pdf_reuses_source_file_no_copy(self):
        source = create_document_file(
            SimpleUploadedFile('doc.pdf', b'%PDF-1.4 body', content_type='application/pdf'),
            self.user,
        )
        version = create_new_revision(self.doc, self.user, '01', 1, file=source)
        version.refresh_from_db()
        self.assertEqual(version.representation_pdf_id, source.pk)
        self.assertEqual(version.representation_pdf_origin, DocumentVersion.RepresentationOrigin.NATIVE)
        self.assertFalse(version.representation_pdf_requires_confirmation)
        self.assertTrue(version.representation_pdf_is_ready_for_submission)
        # Nessun DocumentFile aggiuntivo creato per la rappresentazione.
        self.assertEqual(DocumentFile.objects.filter(kind=DocumentFile.Kind.REPRESENTATION_PDF).count(), 0)


class PrepareRepresentationPdfAutoReliableTests(TestCase):

    def setUp(self):
        self.user = User.objects.create_user('rend_reliable', password='pw')
        self.doc = make_document(code='RENDDOC-002', owner=self.user)

    def test_txt_source_is_converted(self):
        source = create_document_file(
            SimpleUploadedFile('note.txt', b'riga 1\nriga 2\n', content_type='text/plain'),
            self.user,
        )
        version = create_new_revision(self.doc, self.user, '01', 1, file=source)
        version.refresh_from_db()
        self.assertIsNotNone(version.representation_pdf_id)
        self.assertNotEqual(version.representation_pdf_id, source.pk)
        self.assertEqual(
            version.representation_pdf_origin, DocumentVersion.RepresentationOrigin.AUTO_CONVERTED,
        )
        self.assertFalse(version.representation_pdf_requires_confirmation)
        self.assertTrue(version.representation_pdf_is_ready_for_submission)
        rep = DocumentFile.objects.get(pk=version.representation_pdf_id)
        self.assertEqual(rep.kind, DocumentFile.Kind.REPRESENTATION_PDF)
        with rep.file.open('rb') as f:
            self.assertTrue(f.read(5).startswith(b'%PDF'))

    def test_png_source_is_converted(self):
        source = create_document_file(
            SimpleUploadedFile('img.png', _png_bytes(), content_type='image/png'),
            self.user,
        )
        version = create_new_revision(self.doc, self.user, '01', 1, file=source)
        version.refresh_from_db()
        self.assertIsNotNone(version.representation_pdf_id)
        self.assertTrue(version.representation_pdf_is_ready_for_submission)


class PrepareRepresentationPdfAutoUncertainTests(TestCase):

    def setUp(self):
        self.user = User.objects.create_user('rend_uncertain', password='pw')
        self.doc = make_document(code='RENDDOC-003', owner=self.user)
        self.source = create_document_file(
            SimpleUploadedFile('report.docx', b'fake docx bytes', content_type='application/octet-stream'),
            self.user,
        )

    def _make_version_with_source_no_auto_analysis(self, source):
        # Assegna il sorgente FUORI dal path di create_new_revision/
        # update_draft_version apposta: quei path invocano
        # prepare_representation_pdf con rilevamento REALE del convertitore,
        # e questa macchina di sviluppo ha soffice davvero installato. Qui
        # vogliamo controllare noi converter_available/mock in ogni test.
        version = create_new_revision(self.doc, self.user, '01', 1)
        version.file = source
        version.save(update_fields=['file'])
        return version

    def test_successful_office_conversion_with_source_assigned(self):
        version = self._make_version_with_source_no_auto_analysis(self.source)
        with patch('documents.pdf_rendition._convert_office_to_pdf', return_value=b'%PDF-fake-office'):
            prepare_representation_pdf(version, self.user, converter_available=_converter_present)
        version.refresh_from_db()
        self.assertIsNotNone(version.representation_pdf_id)
        self.assertTrue(version.representation_pdf_requires_confirmation)
        self.assertFalse(version.representation_pdf_is_confirmed)
        self.assertFalse(version.representation_pdf_is_ready_for_submission)

        confirm_representation_pdf(version, self.user)
        version.refresh_from_db()
        self.assertTrue(version.representation_pdf_is_confirmed)
        self.assertTrue(version.representation_pdf_is_ready_for_submission)

    def test_failed_office_conversion_leaves_no_representation(self):
        version = self._make_version_with_source_no_auto_analysis(self.source)
        with patch('documents.pdf_rendition._convert_office_to_pdf', side_effect=RuntimeError('boom')):
            prepare_representation_pdf(version, self.user, converter_available=_converter_present)
        version.refresh_from_db()
        self.assertIsNone(version.representation_pdf_id)
        self.assertTrue(
            AuditLog.objects.filter(action='PDF_CONVERSION_FAILED', object_id=str(version.pk)).exists()
        )

    def test_converter_unavailable_falls_back_to_manual(self):
        version = self._make_version_with_source_no_auto_analysis(self.source)
        decision = prepare_representation_pdf(version, self.user, converter_available=_converter_absent)
        version.refresh_from_db()
        self.assertEqual(decision.strategy, 'manual_required')
        self.assertIsNone(version.representation_pdf_id)


class PrepareRepresentationPdfManualUnsupportedTests(TestCase):

    def setUp(self):
        self.user = User.objects.create_user('rend_manual', password='pw')
        self.doc = make_document(code='RENDDOC-004', owner=self.user)

    def test_risky_extension_is_manual_required(self):
        source = create_document_file(
            SimpleUploadedFile('drawing.dwg', b'binary cad data', content_type='application/octet-stream'),
            self.user,
        )
        version = create_new_revision(self.doc, self.user, '01', 1, file=source)
        version.refresh_from_db()
        self.assertIsNone(version.representation_pdf_id)

    def test_unknown_extension_is_unsupported(self):
        source = create_document_file(
            SimpleUploadedFile('mystery.xyz', b'???', content_type='application/octet-stream'),
            self.user,
        )
        version = create_new_revision(self.doc, self.user, '01', 1, file=source)
        version.refresh_from_db()
        self.assertIsNone(version.representation_pdf_id)


class ManualUploadAndConfirmTests(TestCase):

    def setUp(self):
        self.user = User.objects.create_user('rend_upload', password='pw')
        self.doc = make_document(code='RENDDOC-005', owner=self.user)
        source = create_document_file(
            SimpleUploadedFile('drawing.dwg', b'binary cad data', content_type='application/octet-stream'),
            self.user,
        )
        self.version = create_new_revision(self.doc, self.user, '01', 1, file=source)

    def test_manual_upload_of_valid_pdf_is_immediately_confirmed(self):
        pdf = SimpleUploadedFile('rappresentazione.pdf', b'%PDF-1.4 manual', content_type='application/pdf')
        upload_manual_representation_pdf(self.version, pdf, self.user)
        self.version.refresh_from_db()
        self.assertEqual(
            self.version.representation_pdf_origin, DocumentVersion.RepresentationOrigin.MANUAL_UPLOAD,
        )
        self.assertTrue(self.version.representation_pdf_is_confirmed)
        self.assertTrue(self.version.representation_pdf_is_ready_for_submission)

    def test_manual_upload_of_non_pdf_is_rejected(self):
        not_pdf = SimpleUploadedFile('finto.pdf', b'questo non e un pdf', content_type='application/pdf')
        with self.assertRaises(ValidationError):
            upload_manual_representation_pdf(self.version, not_pdf, self.user)

    def test_confirm_without_representation_raises(self):
        with self.assertRaises(ValidationError):
            confirm_representation_pdf(self.version, self.user)


class InvalidationOnSourceChangeTests(TestCase):

    def setUp(self):
        self.user = User.objects.create_user('rend_invalid', password='pw')
        self.doc = make_document(code='RENDDOC-006', owner=self.user)
        self.pdf_a = create_document_file(
            SimpleUploadedFile('a.pdf', b'%PDF-1.4 a', content_type='application/pdf'), self.user,
        )
        self.pdf_b = create_document_file(
            SimpleUploadedFile('b.pdf', b'%PDF-1.4 b', content_type='application/pdf'), self.user,
        )
        self.version = create_new_revision(self.doc, self.user, '01', 1, file=self.pdf_a)

    def test_replacing_source_invalidates_and_reanalyzes(self):
        self.version.refresh_from_db()
        first_representation_id = self.version.representation_pdf_id
        self.assertEqual(first_representation_id, self.pdf_a.pk)

        update_draft_version(
            self.version, self.user,
            revision_label='01', revision_number=1, change_summary='',
            new_file=self.pdf_b,
        )
        self.version.refresh_from_db()
        self.assertEqual(self.version.representation_pdf_id, self.pdf_b.pk)
        self.assertFalse(self.version.representation_pdf_is_stale)
        self.assertTrue(
            AuditLog.objects.filter(
                action='REPRESENTATION_PDF_INVALIDATED', object_id=str(self.version.pk),
            ).exists()
        )

    def test_confirmation_is_cleared_after_source_change(self):
        confirm_representation_pdf(self.version, self.user)
        self.version.refresh_from_db()
        self.assertIsNotNone(self.version.representation_pdf_confirmed_at)

        update_draft_version(
            self.version, self.user,
            revision_label='01', revision_number=1, change_summary='',
            new_file=self.pdf_b,
        )
        self.version.refresh_from_db()
        self.assertIsNone(self.version.representation_pdf_confirmed_at)


class RepresentationPdfViewTests(TestCase):

    def setUp(self):
        self.author = User.objects.create_user('rend_view_author', password='pw')
        self.outsider = User.objects.create_user('rend_view_outsider', password='pw')
        self.doc = make_document(code='RENDDOC-007', owner=self.author)
        source = create_document_file(
            SimpleUploadedFile('drawing.dwg', b'cad data', content_type='application/octet-stream'),
            self.author,
        )
        self.version = create_new_revision(self.doc, self.author, '01', 1, file=source)

    def test_author_can_upload_manual_pdf(self):
        self.client.login(username='rend_view_author', password='pw')
        pdf = SimpleUploadedFile('rep.pdf', b'%PDF-1.4 x', content_type='application/pdf')
        response = self.client.post(
            reverse('version_representation_pdf_upload', args=[self.version.pk]),
            {'representation_pdf_file': pdf},
        )
        self.assertEqual(response.status_code, 302)
        self.version.refresh_from_db()
        self.assertIsNotNone(self.version.representation_pdf_id)

    def test_outsider_cannot_upload_manual_pdf(self):
        self.client.login(username='rend_view_outsider', password='pw')
        pdf = SimpleUploadedFile('rep.pdf', b'%PDF-1.4 x', content_type='application/pdf')
        response = self.client.post(
            reverse('version_representation_pdf_upload', args=[self.version.pk]),
            {'representation_pdf_file': pdf},
        )
        self.assertEqual(response.status_code, 403)

    def test_author_can_confirm_after_upload(self):
        self.client.login(username='rend_view_author', password='pw')
        pdf = SimpleUploadedFile('rep.pdf', b'%PDF-1.4 x', content_type='application/pdf')
        self.client.post(
            reverse('version_representation_pdf_upload', args=[self.version.pk]),
            {'representation_pdf_file': pdf},
        )
        response = self.client.post(reverse('version_representation_pdf_confirm', args=[self.version.pk]))
        self.assertEqual(response.status_code, 302)

    def test_version_detail_shows_pdf_status_section(self):
        self.client.login(username='rend_view_author', password='pw')
        response = self.client.get(reverse('version_detail', args=[self.version.pk]))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'PDF di rappresentazione')
