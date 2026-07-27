"""
Test di modello per i campi PDF introdotti in TASK-032 (DocumentFile.kind,
campi rappresentazione/approvato su DocumentVersion). Nessuna conversione
reale qui: solo stato dati e le property di supporto al gate (TASK-035).
"""
from django.contrib.auth.models import User
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from django.utils import timezone

from documents.models import Document, DocumentFile, DocumentVersion
from documents.services import create_document_file, create_new_revision


def make_document(code='PDFDOC-001', owner=None):
    return Document.objects.create(
        code=code,
        title='Documento di test PDF',
        category=Document.Category.QUALITY,
        owner=owner,
        created_by=owner,
    )


def make_source_file(user, name='sorgente.docx', content=b'contenuto sorgente'):
    return create_document_file(
        SimpleUploadedFile(name, content, content_type='application/octet-stream'),
        user,
    )


class DocumentFileKindTests(TestCase):

    def setUp(self):
        self.user = User.objects.create_user('kind_user', password='pw')

    def test_default_kind_is_source(self):
        doc_file = make_source_file(self.user)
        self.assertEqual(doc_file.kind, DocumentFile.Kind.SOURCE)

    def test_kind_can_be_representation_or_approved(self):
        rep = DocumentFile.objects.create(
            kind=DocumentFile.Kind.REPRESENTATION_PDF,
            file=SimpleUploadedFile('rep.pdf', b'%PDF rep', content_type='application/pdf'),
            original_filename='rep.pdf',
            uploaded_by=self.user,
        )
        approved = DocumentFile.objects.create(
            kind=DocumentFile.Kind.APPROVED_PDF,
            file=SimpleUploadedFile('appr.pdf', b'%PDF appr', content_type='application/pdf'),
            original_filename='appr.pdf',
            uploaded_by=self.user,
        )
        self.assertEqual(rep.kind, DocumentFile.Kind.REPRESENTATION_PDF)
        self.assertEqual(approved.kind, DocumentFile.Kind.APPROVED_PDF)


class DocumentVersionPdfFieldsDefaultsTests(TestCase):

    def setUp(self):
        self.user = User.objects.create_user('pdf_user', password='pw')
        self.doc = make_document(owner=self.user)

    def test_new_version_has_no_pdf_state(self):
        version = create_new_revision(self.doc, self.user, '01', 1)
        self.assertIsNone(version.representation_pdf_id)
        self.assertIsNone(version.approved_pdf_id)
        self.assertEqual(
            version.approved_pdf_generation_status,
            DocumentVersion.ApprovedPdfStatus.NOT_STARTED,
        )
        self.assertFalse(version.representation_pdf_requires_confirmation)


class DocumentVersionPdfPropertiesTests(TestCase):

    def setUp(self):
        self.user = User.objects.create_user('pdf_props_user', password='pw')
        self.doc = make_document(code='PDFDOC-002', owner=self.user)
        self.source_a = make_source_file(self.user, name='a.docx')
        self.source_b = make_source_file(self.user, name='b.docx')
        self.version = create_new_revision(self.doc, self.user, '01', 1, file=self.source_a)

    def _attach_representation(self, source_file, requires_confirmation=False, confirmed=False):
        rep = DocumentFile.objects.create(
            kind=DocumentFile.Kind.REPRESENTATION_PDF,
            file=SimpleUploadedFile('rep.pdf', b'%PDF rep', content_type='application/pdf'),
            original_filename='rep.pdf',
            uploaded_by=self.user,
        )
        self.version.representation_pdf = rep
        self.version.representation_pdf_source_file = source_file
        self.version.representation_pdf_requires_confirmation = requires_confirmation
        self.version.representation_pdf_generated_at = timezone.now()
        if confirmed:
            self.version.representation_pdf_confirmed_by = self.user
            self.version.representation_pdf_confirmed_at = timezone.now()
        self.version.save()

    def test_no_representation_yet_is_not_stale_and_not_ready(self):
        self.assertFalse(self.version.representation_pdf_is_stale)
        self.assertFalse(self.version.representation_pdf_is_ready_for_submission)

    def test_representation_matching_current_source_is_fresh(self):
        self._attach_representation(self.source_a, requires_confirmation=False)
        self.assertFalse(self.version.representation_pdf_is_stale)
        self.assertTrue(self.version.representation_pdf_is_confirmed)
        self.assertTrue(self.version.representation_pdf_is_ready_for_submission)

    def test_representation_becomes_stale_after_source_change(self):
        self._attach_representation(self.source_a, requires_confirmation=False)
        self.version.file = self.source_b
        self.version.save(update_fields=['file'])
        self.assertTrue(self.version.representation_pdf_is_stale)
        self.assertFalse(self.version.representation_pdf_is_ready_for_submission)

    def test_requires_confirmation_blocks_readiness_until_confirmed(self):
        self._attach_representation(self.source_a, requires_confirmation=True, confirmed=False)
        self.assertFalse(self.version.representation_pdf_is_confirmed)
        self.assertFalse(self.version.representation_pdf_is_ready_for_submission)

        self._attach_representation(self.source_a, requires_confirmation=True, confirmed=True)
        self.assertTrue(self.version.representation_pdf_is_confirmed)
        self.assertTrue(self.version.representation_pdf_is_ready_for_submission)
