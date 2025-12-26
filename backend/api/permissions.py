from rest_framework.permissions import BasePermission, SAFE_METHODS


class IsOwnerOrCollaborator(BasePermission):
    def has_object_permission(self, request, view, obj):
        user = request.user
        if not user or not user.is_authenticated:
            return False
        if hasattr(obj, "owner") and obj.owner_id == user.id:
            return True
        # check related trip owner/collaborators for related objects
        trip = getattr(obj, "trip", None)
        if trip:
            if trip.owner_id == user.id:
                return True
            return trip.collaborators.filter(id=user.id).exists()
        # default read-only
        return request.method in SAFE_METHODS
