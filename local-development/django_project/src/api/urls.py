from django.urls import path
from .views import HelloView

urlpatterns = [path('hello/', HelloView.as_view())]
