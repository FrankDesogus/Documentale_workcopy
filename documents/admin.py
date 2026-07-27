from django.contrib import admin

from .models import Document, DocumentFile, DocumentVersion


class DocumentVersionInline(admin.TabularInline):
    model = DocumentVersion
    extra = 0
    fields = (
        'revision_label', 'revision_number', 'status',
        'is_current', 'created_by', 'submitted_at', 'approved_at',
    )
    readonly_fields = ('is_current', 'submitted_at', 'approved_at', 'created_at')
    show_change_link = True


@admin.register(Document)
class DocumentAdmin(admin.ModelAdmin):
    list_display = (
        'code', 'title', 'revision_scheme', 'category', 'document_type',
        'status', 'owner', 'current_version', 'created_at',
    )
    list_filter = ('revision_scheme', 'category', 'status', 'document_type')
    search_fields = ('code', 'title', 'description')
    readonly_fields = ('current_version', 'created_by', 'created_at', 'updated_at')
    inlines = [DocumentVersionInline]


@admin.register(DocumentVersion)
class DocumentVersionAdmin(admin.ModelAdmin):
    list_display = (
        'document', 'revision_label', 'revision_number',
        'status', 'is_current', 'created_by',
        'submitted_at', 'approved_at', 'approved_by',
        'approved_pdf_generation_status',
    )
    list_filter = ('status', 'is_current', 'submitted_at', 'approved_at', 'approved_pdf_generation_status')
    search_fields = (
        'document__code', 'document__title',
        'revision_label', 'change_summary',
    )
    # status è lasciato modificabile per debug, ma in produzione
    # le transizioni di stato devono passare dai service.
    readonly_fields = (
        'submitted_at', 'approved_at', 'approved_by',
        'rejected_at', 'is_current', 'replaces_version', 'created_at',
        'representation_pdf', 'representation_pdf_source_file',
        'representation_pdf_origin', 'representation_pdf_requires_confirmation',
        'representation_pdf_generated_at', 'representation_pdf_confirmed_by',
        'representation_pdf_confirmed_at', 'approved_pdf',
        'approved_pdf_generated_at', 'approved_pdf_generation_status',
        'approved_pdf_generation_error',
    )
    actions = ['regenerate_approved_pdf']

    @admin.action(description='Rigenera PDF approvato (per generazioni fallite)')
    def regenerate_approved_pdf(self, request, queryset):
        from documents.approved_pdf import generate_approved_pdf

        regenerated = 0
        for version in queryset:
            if version.status != DocumentVersion.Status.APPROVED:
                continue
            generate_approved_pdf(version, force=True)
            regenerated += 1
        self.message_user(request, f'Rigenerazione tentata per {regenerated} revisione/i approvata/e.')


@admin.register(DocumentFile)
class DocumentFileAdmin(admin.ModelAdmin):
    list_display = (
        'original_filename', 'kind', 'extension', 'size',
        'sha256_hash', 'uploaded_by', 'uploaded_at',
    )
    list_filter = ('kind',)
    search_fields = ('original_filename', 'sha256_hash')
    readonly_fields = ('uploaded_at',)
