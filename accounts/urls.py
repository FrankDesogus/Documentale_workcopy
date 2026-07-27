from django.urls import path

from accounts.views import signature_manage

urlpatterns = [
    path('firma/', signature_manage, name='signature_manage'),
]
