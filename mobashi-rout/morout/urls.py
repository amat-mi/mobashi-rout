from django.urls import path
from . import views

urlpatterns = [
    path('directions', views.DirectionsView.as_view(), name='directions'),
    path('geocode', views.GeocodeView.as_view(), name='geocode'),
    path('reverse', views.ReverseView.as_view(), name='reverse'),
]
