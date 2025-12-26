from django.contrib.auth import get_user_model
from django.db.models import Q
from django.shortcuts import get_object_or_404
from rest_framework import viewsets, mixins, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

from .models import Trip, TripCollaborator, ItineraryItem, Poll, PollOption, Vote, ChatMessage, TripInvite
from .permissions import IsOwnerOrCollaborator
from .serializers import (
    TripSerializer,
    TripCollaboratorSerializer,
    ItineraryItemSerializer,
    PollSerializer,
    ChatMessageSerializer,
    TripInviteSerializer,
)

User = get_user_model()


class TripViewSet(viewsets.ModelViewSet):
    serializer_class = TripSerializer
    permission_classes = [IsAuthenticated, IsOwnerOrCollaborator]

    def get_queryset(self):
        user = self.request.user
        return Trip.objects.filter(Q(owner=user) | Q(collaborators=user)).distinct()

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)

    @action(detail=True, methods=["get", "post"], url_path="collaborators")
    def collaborators(self, request, pk=None):
        trip = self.get_object()
        if request.method == "GET":
            qs = TripCollaborator.objects.filter(trip=trip).select_related("user")
            return Response(TripCollaboratorSerializer(qs, many=True).data)
        serializer = TripCollaboratorSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        TripCollaborator.objects.update_or_create(
            trip=trip, user=serializer.validated_data["user"], defaults={"role": serializer.validated_data["role"]}
        )
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=["post"], url_path="reorder-itinerary")
    def reorder_itinerary(self, request, pk=None):
        trip = self.get_object()
        order = request.data.get("order", [])
        # order is list of item ids in desired order
        id_to_item = {i.id: i for i in trip.itinerary_items.all()}
        for idx, item_id in enumerate(order):
            item = id_to_item.get(item_id)
            if item:
                item.order = idx
                item.save(update_fields=["order"])
        return Response({"status": "ok"})


class ItineraryItemViewSet(viewsets.ModelViewSet):
    serializer_class = ItineraryItemSerializer
    permission_classes = [IsAuthenticated, IsOwnerOrCollaborator]

    def get_queryset(self):
        user = self.request.user
        return ItineraryItem.objects.filter(Q(trip__owner=user) | Q(trip__collaborators=user)).distinct()

    def perform_create(self, serializer):
        trip_id = self.request.data.get("trip") or self.kwargs.get("trip_pk")
        trip = get_object_or_404(Trip, id=trip_id)
        serializer.save(trip=trip)


class PollViewSet(viewsets.ModelViewSet):
    serializer_class = PollSerializer
    permission_classes = [IsAuthenticated, IsOwnerOrCollaborator]

    def get_queryset(self):
        user = self.request.user
        return Poll.objects.filter(Q(trip__owner=user) | Q(trip__collaborators=user)).distinct()

    def perform_create(self, serializer):
        trip_id = self.request.data.get("trip")
        trip = get_object_or_404(Trip, id=trip_id)
        serializer.save(trip=trip, created_by=self.request.user)

    @action(detail=True, methods=["post"], url_path="vote")
    def vote(self, request, pk=None):
        poll = self.get_object()
        option_id = request.data.get("option_id")
        option = get_object_or_404(PollOption, id=option_id, poll=poll)
        Vote.objects.update_or_create(poll=poll, user=request.user, defaults={"option": option})
        return Response({"status": "ok"})


class ChatMessageViewSet(mixins.ListModelMixin, mixins.CreateModelMixin, viewsets.GenericViewSet):
    serializer_class = ChatMessageSerializer
    permission_classes = [IsAuthenticated, IsOwnerOrCollaborator]

    def get_queryset(self):
        trip_id = self.request.query_params.get("trip")
        qs = ChatMessage.objects.all().select_related("sender")
        if trip_id:
            qs = qs.filter(trip_id=trip_id)
        last_id = self.request.query_params.get("after_id")
        if last_id:
            qs = qs.filter(id__gt=last_id)
        return qs.order_by("id")[:200]

    def perform_create(self, serializer):
        trip_id = self.request.data.get("trip")
        trip = get_object_or_404(Trip, id=trip_id)
        message = serializer.save(trip=trip, sender=self.request.user)
        # Broadcast to websocket group
        channel_layer = get_channel_layer()
        if channel_layer is not None:
            async_to_sync(channel_layer.group_send)(
                f"trip_{trip.id}",
                {
                    "type": "chat.message",
                    "message": {
                        "id": message.id,
                        "trip": trip.id,
                        "content": message.content,
                        "created_at": message.created_at.isoformat(),
                        "sender": {"id": self.request.user.id, "username": self.request.user.get_username()},
                    },
                },
            )


class TripInviteViewSet(mixins.CreateModelMixin, viewsets.GenericViewSet):
    serializer_class = TripInviteSerializer
    permission_classes = [IsAuthenticated, IsOwnerOrCollaborator]

    def get_queryset(self):
        return TripInvite.objects.none()

    def perform_create(self, serializer):
        import secrets
        trip_id = self.request.data.get("trip")
        trip = get_object_or_404(Trip, id=trip_id)
        invite = serializer.save(trip=trip, token=secrets.token_hex(16))
        # send sync email (placeholder using console backend by default)
        from django.core.mail import send_mail

        send_mail(
            subject=f"Trip invite: {trip.name}",
            message=f"You are invited. Accept: /api/invites/accept?token={invite.token}",
            from_email=None,
            recipient_list=[invite.email],
            fail_silently=True,
        )
