"""
Test del servizio centrale di policy PDF (TASK-031).

Non dipendono da `soffice`/LibreOffice reale: la disponibilità del
convertitore è sempre iniettata via `converter_available`, mai letta dal
sistema, per restare deterministici in qualunque ambiente di CI.
"""
from django.test import SimpleTestCase

from documents.pdf_policy import (
    OFFICE_EXTENSIONS,
    RELIABLE_EXTENSIONS,
    RISKY_EXTENSIONS,
    PdfStrategy,
    get_pdf_strategy,
)


def _converter_present(_binary_name):
    return True


def _converter_absent(_binary_name):
    return False


class PdfPolicyNativePdfTests(SimpleTestCase):
    def test_pdf_extension_is_native(self):
        decision = get_pdf_strategy('pdf')
        self.assertEqual(decision.strategy, PdfStrategy.NATIVE_PDF)
        self.assertFalse(decision.requires_confirmation)
        self.assertIsNone(decision.converter)

    def test_extension_case_and_dot_insensitive(self):
        for ext in ('PDF', '.pdf', '.PDF'):
            with self.subTest(ext=ext):
                decision = get_pdf_strategy(ext)
                self.assertEqual(decision.strategy, PdfStrategy.NATIVE_PDF)

    def test_pdf_header_overrides_wrong_extension(self):
        # Un file rinominato con estensione sbagliata ma header PDF reale
        # deve comunque essere trattato come nativo.
        decision = get_pdf_strategy('docx', is_pdf_header=True)
        self.assertEqual(decision.strategy, PdfStrategy.NATIVE_PDF)


class PdfPolicyAutoReliableTests(SimpleTestCase):
    def test_all_reliable_extensions_are_auto_reliable(self):
        for ext in RELIABLE_EXTENSIONS:
            with self.subTest(ext=ext):
                decision = get_pdf_strategy(ext)
                self.assertEqual(decision.strategy, PdfStrategy.AUTO_RELIABLE)
                self.assertFalse(decision.requires_confirmation)
                self.assertEqual(decision.converter, 'reportlab')

    def test_txt_is_reliable(self):
        self.assertEqual(get_pdf_strategy('txt').strategy, PdfStrategy.AUTO_RELIABLE)

    def test_png_is_reliable(self):
        self.assertEqual(get_pdf_strategy('png').strategy, PdfStrategy.AUTO_RELIABLE)


class PdfPolicyAutoUncertainTests(SimpleTestCase):
    def test_office_extension_with_converter_available(self):
        for ext in OFFICE_EXTENSIONS:
            with self.subTest(ext=ext):
                decision = get_pdf_strategy(ext, converter_available=_converter_present)
                self.assertEqual(decision.strategy, PdfStrategy.AUTO_UNCERTAIN)
                self.assertTrue(decision.requires_confirmation)
                self.assertEqual(decision.converter, 'soffice')

    def test_office_extension_without_converter_falls_back_to_manual(self):
        for ext in OFFICE_EXTENSIONS:
            with self.subTest(ext=ext):
                decision = get_pdf_strategy(ext, converter_available=_converter_absent)
                self.assertEqual(decision.strategy, PdfStrategy.MANUAL_REQUIRED)
                self.assertFalse(decision.requires_confirmation)
                self.assertIn('ambiente', decision.reason)


class PdfPolicyManualRequiredTests(SimpleTestCase):
    def test_risky_extensions_never_attempt_conversion(self):
        for ext in RISKY_EXTENSIONS:
            with self.subTest(ext=ext):
                # Anche con convertitore disponibile, i formati rischiosi
                # restano manuali: il rischio non dipende dall'ambiente.
                decision = get_pdf_strategy(ext, converter_available=_converter_present)
                self.assertEqual(decision.strategy, PdfStrategy.MANUAL_REQUIRED)
                self.assertFalse(decision.requires_confirmation)


class PdfPolicyUnsupportedTests(SimpleTestCase):
    def test_unknown_extension_is_unsupported(self):
        decision = get_pdf_strategy('xyz123')
        self.assertEqual(decision.strategy, PdfStrategy.UNSUPPORTED)
        self.assertIn('xyz123', decision.reason)

    def test_empty_extension_is_unsupported(self):
        decision = get_pdf_strategy('')
        self.assertEqual(decision.strategy, PdfStrategy.UNSUPPORTED)


class PdfPolicyReasonTests(SimpleTestCase):
    def test_every_decision_has_a_non_empty_reason(self):
        samples = ['pdf', 'txt', 'png', 'docx', 'dwg', 'unknownext']
        for ext in samples:
            with self.subTest(ext=ext):
                decision = get_pdf_strategy(ext, converter_available=_converter_absent)
                self.assertTrue(decision.reason)
