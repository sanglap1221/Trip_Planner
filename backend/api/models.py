from django.conf import settings
from django.db import models


class TimeStampedModel(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class Trip(TimeStampedModel):
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="owned_trips")
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    start_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)

    collaborators = models.ManyToManyField(settings.AUTH_USER_MODEL, through="TripCollaborator", related_name="trips")

    class Meta:
        indexes = [
            models.Index(fields=["owner", "start_date"]),
            models.Index(fields=["name"]),
        ]

    def __str__(self):
        return self.name


class TripCollaborator(TimeStampedModel):
    ROLE_CHOICES = (
        ("editor", "Editor"),
        ("viewer", "Viewer"),
    )
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name="trip_collaborators")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="collaborations")
    role = models.CharField(max_length=16, choices=ROLE_CHOICES, default="viewer")

    class Meta:
        unique_together = ("trip", "user")
        indexes = [models.Index(fields=["trip", "user"])]


class ItineraryItem(TimeStampedModel):
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name="itinerary_items")
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    start_time = models.DateTimeField(null=True, blank=True)
    end_time = models.DateTimeField(null=True, blank=True)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["order", "created_at"]
        indexes = [models.Index(fields=["trip", "order"])]


class Poll(TimeStampedModel):
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name="polls")
    question = models.CharField(max_length=255)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="created_polls")

    def __str__(self):
        return self.question


class PollOption(TimeStampedModel):
    poll = models.ForeignKey(Poll, on_delete=models.CASCADE, related_name="options")
    text = models.CharField(max_length=255)

    class Meta:
        unique_together = ("poll", "text")


class Vote(TimeStampedModel):
    poll = models.ForeignKey(Poll, on_delete=models.CASCADE, related_name="votes")
    option = models.ForeignKey(PollOption, on_delete=models.CASCADE, related_name="votes")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="votes")

    class Meta:
        unique_together = ("poll", "user")
        indexes = [models.Index(fields=["poll", "user"])]


class ChatMessage(TimeStampedModel):
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name="messages")
    sender = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="messages")
    content = models.TextField()

    class Meta:
        indexes = [models.Index(fields=["trip", "created_at", "id"])]


class TripInvite(TimeStampedModel):
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name="invites")
    email = models.EmailField()
    token = models.CharField(max_length=64, unique=True)
    accepted = models.BooleanField(default=False)

    class Meta:
        indexes = [models.Index(fields=["trip", "email"])]
