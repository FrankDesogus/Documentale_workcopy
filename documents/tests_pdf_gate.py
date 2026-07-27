"""
Test del gate di invio in approvazione (TASK-035): un PDF di
rappresentazione valido e, se richiesto, confermato è obbligatorio prima
dell'invio — ma solo per revisioni che hanno un file sorgente (vedi
docs/ai/PDF_APPROVAL_DECISION.md §6 per la motivazione).
"""
from unittest.mock import patch

from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase

from documents.models import Document, DocumentVersion
from documents.pdf_rendition import confirm_representation_pdf, upload_manual_representation_pdf
from documents.services import (
    create_document_file,
    create_new_revision,
    submit_version_for_approval,
    update_draft_version,
)


def make_document(code='GATEDOC-001', owner=None):
    return Document.objects.create(
        code=code, title='Documento gate', category=Document.Category.QUALITY,
        owner=owner, created_by=owner,
    )


class SubmissionGateTests(TestCase):

    def setUp(self):
        self.author = User.objects.create_user('gate_author', password='pw')
        self.approver = User.objects.create_user('gate_approver', password='pw')
        self.doc = make_document(owner=self.author)

    def test_submit_without_any_source_file_is_unaffected_by_gate(self):
        # DocumentVersion.file è nullable da prima di questa feature: una
        # revisione senza alcun sorgente non ha nulla da rappresentare in
        # PDF, quindi il gate non si applica.
        version = create_new_revision(self.doc, self.author, '01', 1)
        approval_request = submit_version_for_approval(
            version=version, requested_by=self.author,
            approvers=[self.approver], approval_policy='any',
        )
        self.assertIsNotNone(approval_request.pk)

    def test_submit_blocked_when_representation_pdf_missing(self):
        source = create_document_file(
            SimpleUploadedFile('drawing.dwg', b'cad', content_type='application/octet-stream'),
            self.author,
        )
        version = create_new_revision(self.doc, self.author, '01', 1, file=source)
        with self.assertRaises(ValidationError):
            submit_version_for_approval(
                version=version, requested_by=self.author,
                approvers=[self.approver], approval_policy='any',
            )

    def test_submit_allowed_with_native_pdf_source(self):
        source = create_document_file(
            SimpleUploadedFile('doc.pdf', b'%PDF-1.4 body', content_type='application/pdf'),
            self.author,
        )
        version = create_new_revision(self.doc, self.author, '01', 1, file=source)
        approval_request = submit_version_for_approval(
            version=version, requested_by=self.author,
            approvers=[self.approver], approval_policy='any',
        )
        self.assertIsNotNone(approval_request.pk)

    def test_submit_blocked_when_representation_pdf_stale(self):
        pdf_a = create_document_file(
            SimpleUploadedFile('a.pdf', b'%PDF-1.4 a', content_type='application/pdf'), self.author,
        )
        pdf_b = create_document_file(
            SimpleUploadedFile('b.pdf', b'%PDF-1.4 b', content_type='application/pdf'), self.author,
        )
        version = create_new_revision(self.doc, self.author, '01', 1, file=pdf_a)
        # Sostituzione diretta del sorgente senza passare da update_draft_version:
        # simula uno stato incoerente per verificare che il gate lo rilevi
        # comunque tramite representation_pdf_is_stale.
        version.file = pdf_b
        version.save(update_fields=['file'])
        with self.assertRaises(ValidationError):
            submit_version_for_approval(
                version=version, requested_by=self.author,
                approvers=[self.approver], approval_policy='any',
            )

    def test_submit_blocked_when_confirmation_required_and_missing(self):
        source = create_document_file(
            SimpleUploadedFile('report.docx', b'fake docx', content_type='application/octet-stream'),
            self.author,
        )
        version = create_new_revision(self.doc, self.author, '01', 1)
        version.file = source
        version.save(update_fields=['file'])
        from documents.pdf_rendition import prepare_representation_pdf
        with patch('documents.pdf_rendition._convert_office_to_pdf', return_value=b'%PDF-office'):
            prepare_representation_pdf(version, self.author, converter_available=lambda _n: True)
        version.refresh_from_db()
        self.assertTrue(version.representation_pdf_requires_confirmation)

        with self.assertRaises(ValidationError):
            submit_version_for_approval(
                version=version, requested_by=self.author,
                approvers=[self.approver], approval_policy='any',
            )

        confirm_representation_pdf(version, self.author)
        approval_request = submit_version_for_approval(
            version=version, requested_by=self.author,
            approvers=[self.approver], approval_policy='any',
        )
        self.assertIsNotNone(approval_request.pk)

    def test_submit_allowed_after_manual_upload(self):
        source = create_document_file(
            SimpleUploadedFile('drawing.dwg', b'cad', content_type='application/octet-stream'),
            self.author,
        )
        version = create_new_revision(self.doc, self.author, '01', 1, file=source)
        pdf = SimpleUploadedFile('rep.pdf', b'%PDF-1.4 manual', content_type='application/pdf')
        upload_manual_representation_pdf(version, pdf, self.author)
        approval_request = submit_version_for_approval(
            version=version, requested_by=self.author,
            approvers=[self.approver], approval_policy='any',
        )
        self.assertIsNotNone(approval_request.pk)


class FreezeAfterSubmissionTests(TestCase):

    def setUp(self):
        self.author = User.objects.create_user('freeze_author', password='pw')
        self.approver = User.objects.create_user('freeze_approver', password='pw')
        self.doc = Document.objects.create(
            code='GATEDOC-002', title='Documento freeze', category=Document.Category.QUALITY,
            owner=self.author, created_by=self.author,
        )
        source = create_document_file(
            SimpleUploadedFile('a.pdf', b'%PDF-1.4 a', content_type='application/pdf'), self.author,
        )
        self.version = create_new_revision(self.doc, self.author, '01', 1, file=source)
        submit_version_for_approval(
            version=self.version, requested_by=self.author,
            approvers=[self.approver], approval_policy='any',
        )
        self.version.refresh_from_db()

    def test_cannot_upload_manual_pdf_once_in_approval(self):
        pdf = SimpleUploadedFile('sneaky.pdf', b'%PDF-1.4 sneaky', content_type='application/pdf')
        with self.assertRaises(ValidationError):
            upload_manual_representation_pdf(self.version, pdf, self.author)

    def test_cannot_confirm_once_in_approval(self):
        with self.assertRaises(ValidationError):
            confirm_representation_pdf(self.version, self.author)

    def test_cannot_replace_source_once_in_approval(self):
        self.assertEqual(self.version.status, DocumentVersion.Status.IN_APPROVAL)
        with self.assertRaises(ValidationError):
            update_draft_version(
                self.version, self.author,
                revision_label='01', revision_number=1, change_summary='tentativo',
            )
