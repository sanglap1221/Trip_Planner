import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth.models import AnonymousUser

from .models import Trip


class TripChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.trip_id = self.scope["url_route"]["kwargs"]["trip_id"]
        self.group_name = f"trip_{self.trip_id}"
        user = self.scope.get("user")
        if isinstance(user, AnonymousUser):
            await self.close()
            return
        allowed = await self._user_allowed(int(self.trip_id), user.id)
        if not allowed:
            await self.close()
            return
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def receive(self, text_data=None, bytes_data=None):
        # For minimal impl: ignore client -> server messages here.
        pass

    async def chat_message(self, event):
        # Forward message JSON to client
        await self.send(text_data=json.dumps({"type": "chat", "message": event["message")}))

    @database_sync_to_async
    def _user_allowed(self, trip_id: int, user_id: int) -> bool:
        try:
            trip = Trip.objects.get(id=trip_id)
        except Trip.DoesNotExist:
            return False
        if trip.owner_id == user_id:
            return True
        return trip.collaborators.filter(id=user_id).exists()
import json
from channels.generic.websocket import AsyncWebsocketConsumer


class TripChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.trip_id = self.scope["url_route"]["kwargs"]["trip_id"]
        self.group_name = f"trip_{self.trip_id}"
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def receive(self, text_data=None, bytes_data=None):
        # Read-only WS: ignore client messages; HTTP endpoint persists and broadcasts
        pass

    async def chat_message(self, event):
        await self.send(text_data=json.dumps(event["message"]))
