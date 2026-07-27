import base64
import hashlib

from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.shortcuts import redirect, render

from accounts.forms import UserSignatureUploadForm
from accounts.models import UserSignature
from auditlog.services import create_audit_log


def _active_signature_preview_data_uri(signature):
    """
    Anteprima come data URI: nessun URL scaricabile per la firma di un altro
    utente, nessuna vista di download separata da proteggere. Usata solo per
    l'anteprima della propria firma nella pagina di gestione.
    """
    signature.image.open('rb')
    try:
        encoded = base64.b64encode(signature.image.read()).decode('ascii')
    finally:
        signature.image.close()
    return f'data:image/png;base64,{encoded}'


@login_required
def signature_manage(request):
    active_signature = UserSignature.objects.filter(user=request.user, is_active=True).first()

    if request.method == 'POST':
        action = request.POST.get('action')

        if action == 'remove':
            if active_signature is None:
                messages.error(request, 'Non hai una firma visiva attiva da rimuovere.')
                return redirect('signature_manage')
            active_signature.is_active = False
            active_signature.save(update_fields=['is_active'])
            create_audit_log(
                user=request.user,
                action='SIGNATURE_REMOVED',
                instance=active_signature,
            )
            messages.success(
                request,
                'Firma visiva rimossa. Verrà usata solo la firma testuale (nome utente).',
            )
            return redirect('signature_manage')

        form = UserSignatureUploadForm(request.POST, request.FILES)
        if form.is_valid():
            image = form.cleaned_data['image']
            sha256 = hashlib.sha256()
            for chunk in image.chunks():
                sha256.update(chunk)
            image.seek(0)

            if active_signature is not None:
                active_signature.is_active = False
                active_signature.save(update_fields=['is_active'])

            new_signature = UserSignature.objects.create(
                user=request.user,
                image=image,
                original_filename=image.name,
                size=image.size,
                sha256_hash=sha256.hexdigest(),
                is_active=True,
            )
            create_audit_log(
                user=request.user,
                action='SIGNATURE_UPLOADED',
                instance=new_signature,
                new_values={'original_filename': image.name},
            )
            messages.success(request, 'Firma visiva caricata correttamente.')
            return redirect('signature_manage')
    else:
        form = UserSignatureUploadForm()

    preview_data_uri = None
    if active_signature is not None:
        preview_data_uri = _active_signature_preview_data_uri(active_signature)

    return render(request, 'accounts/signature_manage.html', {
        'form': form,
        'active_signature': active_signature,
        'preview_data_uri': preview_data_uri,
    })
