from django.contrib import admin

from .models import Trip, TripCollaborator, ItineraryItem, Poll, PollOption, Vote, ChatMessage, TripInvite


@admin.register(Trip)
class TripAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "owner", "start_date", "end_date", "created_at")
    search_fields = ("name", "description")
    list_filter = ("start_date",)


@admin.register(TripCollaborator)
class TripCollaboratorAdmin(admin.ModelAdmin):
    list_display = ("trip", "user", "role", "created_at")
    list_filter = ("role",)


@admin.register(ItineraryItem)
class ItineraryItemAdmin(admin.ModelAdmin):
    list_display = ("id", "trip", "title", "order", "start_time", "end_time")
    list_filter = ("trip",)


class PollOptionInline(admin.TabularInline):
    model = PollOption
    extra = 0


@admin.register(Poll)
class PollAdmin(admin.ModelAdmin):
    list_display = ("id", "trip", "question", "created_by", "created_at")
    inlines = [PollOptionInline]


@admin.register(Vote)
class VoteAdmin(admin.ModelAdmin):
    list_display = ("poll", "option", "user", "created_at")


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display = ("id", "trip", "sender", "created_at")
    search_fields = ("content",)


@admin.register(TripInvite)
class TripInviteAdmin(admin.ModelAdmin):
    list_display = ("id", "trip", "email", "accepted", "created_at")
