from django.urls import re_path

from .consumers import TripChatConsumer

websocket_urlpatterns = [
    re_path(r"^ws/trips/(?P<trip_id>\d+)/$", TripChatConsumer.as_asgi()),
]
