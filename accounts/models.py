from django.contrib.auth.models import User
from django.db import models


class UserSignature(models.Model):
    """
    Firma visiva opzionale di un utente (immagine PNG). Non è una firma
    digitale/crittografica: è una rappresentazione grafica usata nel registro
    di approvazione del PDF approvato (vedi docs/ai/PDF_APPROVAL_DECISION.md).

    Righe immutabili: una nuova sostituzione crea una nuova riga (`is_active`
    sposta il flag) invece di modificarne una esistente, per non alterare
    riferimenti storici già congelati su ApprovalDecision.signature_used.
    """
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='signatures',
        verbose_name='Utente',
    )
    image = models.ImageField(
        upload_to='accounts/signatures/%Y/%m/',
        verbose_name='Immagine firma (PNG)',
    )
    original_filename = models.CharField(max_length=255, verbose_name='Nome file originale')
    size = models.PositiveIntegerField(null=True, blank=True, verbose_name='Dimensione (byte)')
    sha256_hash = models.CharField(max_length=64, blank=True, verbose_name='Hash SHA-256')
    is_active = models.BooleanField(default=True, verbose_name='Firma corrente')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Firma visiva utente'
        verbose_name_plural = 'Firme visive utente'
        ordering = ['-created_at']
        constraints = [
            models.UniqueConstraint(
                fields=['user'],
                condition=models.Q(is_active=True),
                name='unique_active_signature_per_user',
            ),
        ]

    def __str__(self):
        return f"Firma di {self.user.get_username()} ({'attiva' if self.is_active else 'storica'})"
