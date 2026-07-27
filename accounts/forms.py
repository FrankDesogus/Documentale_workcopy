from django import forms

MAX_SIGNATURE_SIZE_BYTES = 1 * 1024 * 1024  # 1 MB
MAX_SIGNATURE_DIMENSION_PX = 1000


class UserSignatureUploadForm(forms.Form):
    image = forms.ImageField(
        label='Immagine firma (PNG)',
        help_text=(
            f'Solo PNG, max {MAX_SIGNATURE_DIMENSION_PX}×{MAX_SIGNATURE_DIMENSION_PX}px, '
            f'max {MAX_SIGNATURE_SIZE_BYTES // (1024 * 1024)} MB. La trasparenza è supportata. '
            'Non è una firma digitale: è una rappresentazione grafica interna.'
        ),
    )

    def clean_image(self):
        image = self.cleaned_data['image']

        if image.size > MAX_SIGNATURE_SIZE_BYTES:
            raise forms.ValidationError(
                f'Il file supera la dimensione massima consentita '
                f'({MAX_SIGNATURE_SIZE_BYTES // (1024 * 1024)} MB).'
            )

        # forms.ImageField ha già verificato (via Pillow) che il contenuto sia
        # un'immagine valida e ne ha popolato image.image; qui restringiamo
        # esplicitamente il formato a PNG e la dimensione in pixel.
        pil_image = image.image
        if pil_image.format != 'PNG':
            raise forms.ValidationError('Il file deve essere un\'immagine PNG.')

        width, height = pil_image.size
        if width > MAX_SIGNATURE_DIMENSION_PX or height > MAX_SIGNATURE_DIMENSION_PX:
            raise forms.ValidationError(
                f'L\'immagine supera le dimensioni massime consentite '
                f'({MAX_SIGNATURE_DIMENSION_PX}×{MAX_SIGNATURE_DIMENSION_PX}px).'
            )

        return image
