from django.urls import path, include
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework.permissions import AllowAny
from rest_framework.views import APIView
from django.contrib.auth import get_user_model

from .views import TripViewSet, ItineraryItemViewSet, PollViewSet, ChatMessageViewSet, TripInviteViewSet

router = DefaultRouter()
router.register(r"trips", TripViewSet, basename="trip")
router.register(r"itinerary-items", ItineraryItemViewSet, basename="itineraryitem")
router.register(r"polls", PollViewSet, basename="poll")
router.register(r"messages", ChatMessageViewSet, basename="message")
router.register(r"invites", TripInviteViewSet, basename="invite")

urlpatterns = [
    path("auth/token/", TokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("auth/token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("auth/signup/", csrf_exempt(lambda request: SignupView.as_view()(request))),
    path("", include(router.urls)),
    path("invites/accept", csrf_exempt(lambda request: _accept_invite(request))),
]


def _accept_invite(request):
    from django.contrib.auth import get_user_model
    from django.shortcuts import get_object_or_404
    from .models import TripInvite, TripCollaborator

    token = request.GET.get("token")
    if not token:
        return JsonResponse({"detail": "token required"}, status=400)
    invite = get_object_or_404(TripInvite, token=token)
    invite.accepted = True
    invite.save(update_fields=["accepted"])
    # If user authenticated, add collaborator
    if getattr(request, "user", None) and request.user.is_authenticated:
        TripCollaborator.objects.get_or_create(trip=invite.trip, user=request.user, defaults={"role": "viewer"})
    return JsonResponse({"detail": "Invite accepted", "trip": invite.trip_id})


class SignupView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        import json as _json
        try:
            data = _json.loads(request.body.decode("utf-8")) if request.body else request.POST
        except Exception:
            data = request.POST
        username = data.get("username") or data.get("email")
        email = data.get("email")
        password = data.get("password")
        if not username or not password:
            return JsonResponse({"detail": "username/email and password required"}, status=400)
        User = get_user_model()
        if User.objects.filter(username=username).exists():
            return JsonResponse({"detail": "username taken"}, status=400)
        user = User.objects.create_user(username=username, email=email, password=password)
        return JsonResponse({"id": user.id, "username": user.username, "email": user.email}, status=201)
