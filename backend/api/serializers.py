from django.contrib.auth import get_user_model
from rest_framework import serializers

from .models import Trip, TripCollaborator, ItineraryItem, Poll, PollOption, Vote, ChatMessage, TripInvite


User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "username", "email"]


class TripCollaboratorSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    user_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(), source="user", write_only=True
    )

    class Meta:
        model = TripCollaborator
        fields = ["id", "trip", "user", "user_id", "role", "created_at", "updated_at"]
        read_only_fields = ["created_at", "updated_at", "trip"]


class ItineraryItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = ItineraryItem
        fields = [
            "id",
            "trip",
            "title",
            "description",
            "start_time",
            "end_time",
            "order",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at", "trip"]


class TripSerializer(serializers.ModelSerializer):
    owner = UserSerializer(read_only=True)
    collaborators = UserSerializer(read_only=True, many=True)

    class Meta:
        model = Trip
        fields = [
            "id",
            "name",
            "description",
            "start_date",
            "end_date",
            "owner",
            "collaborators",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["owner", "collaborators", "created_at", "updated_at"]


class PollOptionSerializer(serializers.ModelSerializer):
    votes_count = serializers.IntegerField(source="votes.count", read_only=True)

    class Meta:
        model = PollOption
        fields = ["id", "text", "votes_count"]


class PollSerializer(serializers.ModelSerializer):
    created_by = UserSerializer(read_only=True)
    options = PollOptionSerializer(many=True)

    class Meta:
        model = Poll
        fields = ["id", "trip", "question", "created_by", "options", "created_at"]
        read_only_fields = ["created_by", "created_at", "trip"]

    def create(self, validated_data):
        options = validated_data.pop("options", [])
        poll = Poll.objects.create(**validated_data)
        for opt in options:
            PollOption.objects.create(poll=poll, **opt)
        return poll

    def update(self, instance, validated_data):
        options = validated_data.pop("options", None)
        for attr, val in validated_data.items():
            setattr(instance, attr, val)
        instance.save()
        if options is not None:
            instance.options.all().delete()
            for opt in options:
                PollOption.objects.create(poll=instance, **opt)
        return instance


class VoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vote
        fields = ["id", "poll", "option", "user", "created_at"]
        read_only_fields = ["user", "created_at"]


class ChatMessageSerializer(serializers.ModelSerializer):
    sender = UserSerializer(read_only=True)

    class Meta:
        model = ChatMessage
        fields = ["id", "trip", "sender", "content", "created_at"]
        read_only_fields = ["sender", "created_at", "trip"]


class TripInviteSerializer(serializers.ModelSerializer):
    class Meta:
        model = TripInvite
        fields = ["id", "trip", "email", "token", "accepted", "created_at"]
        read_only_fields = ["token", "accepted", "created_at", "trip"]
