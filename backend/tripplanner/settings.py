"""
Production settings for Trip Planner
This is the DEFINITIVE settings file for Render deployment.
"""

import os
from pathlib import Path
from datetime import timedelta

import dj_database_url
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

# ================== SECURITY ==================
# SECRET_KEY: MUST be set in Render environment
SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY")
if not SECRET_KEY:
    if os.environ.get("RENDER"):  # On Render without secret = ERROR
        raise ValueError("DJANGO_SECRET_KEY environment variable is REQUIRED on Render")
    # Local development fallback only
    SECRET_KEY = "insecure-local-dev-only-key"

# DEBUG: False in production, True in local
DEBUG = os.environ.get("DJANGO_DEBUG", "False") == "True"

# ALLOWED_HOSTS: Set in Render (e.g., "trip-plan.onrender.com")
ALLOWED_HOSTS = os.environ.get("DJANGO_ALLOWED_HOSTS", "localhost,127.0.0.1").split(",")
# Strip whitespace from each host
ALLOWED_HOSTS = [h.strip() for h in ALLOWED_HOSTS]

# ================== INSTALLED APPS ==================
INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    # Third-party
    "rest_framework",
    "rest_framework.authtoken",
    "corsheaders",
    "drf_spectacular",
    "channels",
    # Local apps
    "api",
]

# ================== MIDDLEWARE ==================
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    # Custom middleware
    "api.middleware.RequestResponseLoggingMiddleware",
    "api.middleware.RateLimitMiddleware",
    "api.middleware.GlobalExceptionMiddleware",
]

ROOT_URLCONF = "tripplanner.urls"

# ================== TEMPLATES ==================
TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    }
]

# ================== WSGI & ASGI ==================
WSGI_APPLICATION = "tripplanner.wsgi.application"
ASGI_APPLICATION = "tripplanner.asgi.application"

# ================== DATABASE ==================
# On Render: DATABASE_URL is provided automatically
# Format: postgres://user:password@host:port/dbname
if os.environ.get("DATABASE_URL"):
    DATABASES = {
        "default": dj_database_url.config(
            default=os.environ.get("DATABASE_URL"),
            conn_max_age=600,
            conn_health_checks=True,
        )
    }
else:
    # Local development fallback
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }

# ================== CACHES ==================
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        "LOCATION": "tripplanner-cache",
    }
}

# ================== CHANNELS (WebSocket) ==================
CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels.layers.InMemoryChannelLayer",
    }
}

# ================== AUTH ==================
AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

# ================== INTERNATIONALIZATION ==================
LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

# ================== STATIC FILES ==================
STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# ================== REST FRAMEWORK ==================
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticated",
    ),
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
}

# ================== API DOCS (Swagger) ==================
SPECTACULAR_SETTINGS = {
    "TITLE": "Smart Trip Planner API",
    "DESCRIPTION": "Production API for collaborative trip planning with real-time chat",
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,  # Don't expose raw schema endpoint
}

# ================== JWT ==================
SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=60),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
}

# ================== CORS ==================
CORS_ALLOW_ALL_ORIGINS = True  # Flutter frontend can be any origin during dev

# ================== EMAIL ==================
EMAIL_BACKEND = os.getenv(
    "EMAIL_BACKEND",
    "django.core.mail.backends.console.EmailBackend" if DEBUG else "django.core.mail.backends.smtp.EmailBackend"
)
EMAIL_HOST = os.getenv("EMAIL_HOST", "localhost")
EMAIL_PORT = int(os.getenv("EMAIL_PORT", "25"))
EMAIL_HOST_USER = os.getenv("EMAIL_HOST_USER", "")
EMAIL_HOST_PASSWORD = os.getenv("EMAIL_HOST_PASSWORD", "")
EMAIL_USE_TLS = os.getenv("EMAIL_USE_TLS", "False").lower() == "true"
DEFAULT_FROM_EMAIL = os.getenv("DEFAULT_FROM_EMAIL", "noreply@tripplanner.local")

# ================== SECURITY HEADERS (Production Only) ==================
if not DEBUG:
    # Trust X-Forwarded-Proto header from Render reverse proxy
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
    # Force HTTPS in production
    SECURE_SSL_REDIRECT = True
    # Set secure flag on session cookies
    SESSION_COOKIE_SECURE = True
    # Set secure flag on CSRF cookies
    CSRF_COOKIE_SECURE = True
    # Prevent browsers from MIME-sniffing
    SECURE_CONTENT_SECURITY_POLICY = {
        "default-src": ("'self'",),
    }

# ================== LOGGING ==================
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "{levelname} {asctime} {module} {process:d} {thread:d} {message}",
            "style": "{",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "verbose",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "INFO",
    },
    "loggers": {
        "django": {
            "handlers": ["console"],
            "level": os.getenv("DJANGO_LOG_LEVEL", "INFO"),
            "propagate": False,
        },
    },
}
