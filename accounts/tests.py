import io

from django.contrib.auth.models import User
from django.core.files.uploadedfile import SimpleUploadedFile
from django.db import IntegrityError, transaction
from django.test import TestCase
from django.urls import reverse

from accounts.models import UserSignature


def _make_png_bytes(size=(10, 10), mode='RGBA', color=(0, 0, 0, 0)):
    from PIL import Image
    buf = io.BytesIO()
    Image.new(mode, size, color).save(buf, format='PNG')
    return buf.getvalue()


class UserSignatureModelTests(TestCase):

    def setUp(self):
        self.user = User.objects.create_user('sig_user', password='pw')

    def test_create_active_signature(self):
        png = _make_png_bytes()
        sig = UserSignature.objects.create(
            user=self.user,
            image=SimpleUploadedFile('firma.png', png, content_type='image/png'),
            original_filename='firma.png',
            size=len(png),
        )
        self.assertTrue(sig.is_active)
        self.assertIn(self.user.get_username(), str(sig))

    def test_only_one_active_signature_per_user(self):
        png = _make_png_bytes()
        UserSignature.objects.create(
            user=self.user,
            image=SimpleUploadedFile('a.png', png, content_type='image/png'),
            original_filename='a.png',
            is_active=True,
        )
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                UserSignature.objects.create(
                    user=self.user,
                    image=SimpleUploadedFile('b.png', png, content_type='image/png'),
                    original_filename='b.png',
                    is_active=True,
                )

    def test_replacing_signature_deactivates_previous_and_keeps_history(self):
        png = _make_png_bytes()
        first = UserSignature.objects.create(
            user=self.user,
            image=SimpleUploadedFile('a.png', png, content_type='image/png'),
            original_filename='a.png',
            is_active=True,
        )
        first.is_active = False
        first.save(update_fields=['is_active'])
        second = UserSignature.objects.create(
            user=self.user,
            image=SimpleUploadedFile('b.png', png, content_type='image/png'),
            original_filename='b.png',
            is_active=True,
        )
        first.refresh_from_db()
        self.assertFalse(first.is_active)
        self.assertTrue(second.is_active)
        # La riga storica non viene eliminata: resta referenziabile da
        # eventuali ApprovalDecision.signature_used già congelate.
        self.assertEqual(UserSignature.objects.filter(user=self.user).count(), 2)

    def test_two_users_can_each_have_an_active_signature(self):
        other = User.objects.create_user('sig_user_2', password='pw')
        png = _make_png_bytes()
        UserSignature.objects.create(
            user=self.user,
            image=SimpleUploadedFile('a.png', png, content_type='image/png'),
            original_filename='a.png',
        )
        UserSignature.objects.create(
            user=other,
            image=SimpleUploadedFile('b.png', png, content_type='image/png'),
            original_filename='b.png',
        )
        self.assertEqual(UserSignature.objects.filter(is_active=True).count(), 2)


class SignatureManageViewTests(TestCase):

    def setUp(self):
        self.user = User.objects.create_user('view_sig_user', password='pw')

    def test_requires_login(self):
        response = self.client.get(reverse('signature_manage'))
        self.assertEqual(response.status_code, 302)

    def test_upload_valid_png_creates_active_signature(self):
        self.client.login(username='view_sig_user', password='pw')
        png = _make_png_bytes()
        response = self.client.post(reverse('signature_manage'), {
            'image': SimpleUploadedFile('firma.png', png, content_type='image/png'),
        })
        self.assertEqual(response.status_code, 302)
        sig = UserSignature.objects.get(user=self.user, is_active=True)
        self.assertEqual(sig.original_filename, 'firma.png')

    def test_upload_non_png_rejected(self):
        self.client.login(username='view_sig_user', password='pw')
        response = self.client.post(reverse('signature_manage'), {
            'image': SimpleUploadedFile('firma.txt', b'not an image', content_type='text/plain'),
        })
        self.assertEqual(response.status_code, 200)
        self.assertFalse(UserSignature.objects.filter(user=self.user).exists())

    def test_upload_oversized_dimensions_rejected(self):
        self.client.login(username='view_sig_user', password='pw')
        oversized = _make_png_bytes(size=(1200, 10))
        response = self.client.post(reverse('signature_manage'), {
            'image': SimpleUploadedFile('big.png', oversized, content_type='image/png'),
        })
        self.assertEqual(response.status_code, 200)
        self.assertFalse(UserSignature.objects.filter(user=self.user).exists())

    def test_replace_signature_deactivates_previous(self):
        self.client.login(username='view_sig_user', password='pw')
        png = _make_png_bytes()
        self.client.post(reverse('signature_manage'), {
            'image': SimpleUploadedFile('a.png', png, content_type='image/png'),
        })
        first = UserSignature.objects.get(user=self.user, is_active=True)
        self.client.post(reverse('signature_manage'), {
            'image': SimpleUploadedFile('b.png', png, content_type='image/png'),
        })
        first.refresh_from_db()
        self.assertFalse(first.is_active)
        self.assertEqual(UserSignature.objects.filter(user=self.user).count(), 2)

    def test_remove_signature(self):
        self.client.login(username='view_sig_user', password='pw')
        png = _make_png_bytes()
        UserSignature.objects.create(
            user=self.user,
            image=SimpleUploadedFile('a.png', png, content_type='image/png'),
            original_filename='a.png',
        )
        response = self.client.post(reverse('signature_manage'), {'action': 'remove'})
        self.assertEqual(response.status_code, 302)
        self.assertFalse(UserSignature.objects.filter(user=self.user, is_active=True).exists())
        self.assertEqual(UserSignature.objects.filter(user=self.user).count(), 1)

    def test_preview_is_not_a_public_media_url(self):
        self.client.login(username='view_sig_user', password='pw')
        png = _make_png_bytes()
        UserSignature.objects.create(
            user=self.user,
            image=SimpleUploadedFile('a.png', png, content_type='image/png'),
            original_filename='a.png',
        )
        response = self.client.get(reverse('signature_manage'))
        self.assertContains(response, 'data:image/png;base64,')
        self.assertNotContains(response, '/media/')
