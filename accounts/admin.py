from django.contrib import admin

from .models import UserSignature


@admin.register(UserSignature)
class UserSignatureAdmin(admin.ModelAdmin):
    list_display = ('user', 'is_active', 'original_filename', 'size', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('user__username', 'original_filename')
    readonly_fields = ('sha256_hash', 'size', 'created_at')
