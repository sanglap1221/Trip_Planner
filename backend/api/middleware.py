import json
import logging
import time
from typing import Callable

from django.core.cache import cache
from django.http import JsonResponse


logger = logging.getLogger(__name__)


class RequestResponseLoggingMiddleware:
    def __init__(self, get_response: Callable):
        self.get_response = get_response

    def __call__(self, request):
        start = time.time()
        response = self.get_response(request)
        duration = (time.time() - start) * 1000
        user_id = getattr(getattr(request, "user", None), "id", None)
        logger.info(
            json.dumps(
                {
                    "method": request.method,
                    "path": request.path,
                    "status": getattr(response, "status_code", None),
                    "ms": round(duration, 2),
                    "user": user_id,
                }
            )
        )
        return response


class RateLimitMiddleware:
    """Simple sliding-window rate limiter per IP (and user when authenticated)."""

    def __init__(self, get_response: Callable, limit: int = 120, window: int = 60):
        self.get_response = get_response
        self.limit = limit
        self.window = window

    def __call__(self, request):
        try:
            ident = request.META.get("REMOTE_ADDR", "anon")
            if getattr(request, "user", None) and request.user.is_authenticated:
                ident = f"u:{request.user.id}"
            key = f"rl:{ident}:{int(time.time() // self.window)}"
            count = cache.get(key)
            if count is None:
                cache.set(key, 1, timeout=self.window + 1)
            else:
                if count >= self.limit:
                    return JsonResponse({"detail": "Rate limit exceeded"}, status=429)
                try:
                    cache.incr(key)
                except Exception:
                    cache.set(key, count + 1, timeout=self.window + 1)
        except Exception:  # fail open
            pass
        return self.get_response(request)


class GlobalExceptionMiddleware:
    def __init__(self, get_response: Callable):
        self.get_response = get_response

    def __call__(self, request):
        try:
            return self.get_response(request)
        except Exception as exc:
            logger.exception("Unhandled error")
            return JsonResponse({"detail": "Internal server error"}, status=500)
