import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from django.urls import path

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "tripplanner.settings")

django_asgi_app = get_asgi_application()

# Import websocket routes from api
from api.routing import websocket_urlpatterns  # noqa: E402

application = ProtocolTypeRouter({
	"http": django_asgi_app,
	"websocket": AuthMiddlewareStack(URLRouter(websocket_urlpatterns)),
})
