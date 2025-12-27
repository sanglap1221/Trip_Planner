#!/bin/sh
set -e

echo "Starting Trip Planner entrypoint"
python -c 'import sys; print("Python:", sys.version)'
echo "DJANGO_DEBUG=${DJANGO_DEBUG:-False}"
echo "DJANGO_ALLOWED_HOSTS=${DJANGO_ALLOWED_HOSTS:-localhost,127.0.0.1}"

echo "Running Django system checks..."
python manage.py check || { echo "Django check failed"; exit 1; }

echo "Running migrations..."
python manage.py migrate --noinput

# Optionally collect static files (safe if none configured)
echo "Collecting static files..."
python manage.py collectstatic --noinput || echo "collectstatic skipped"

echo "Starting ASGI server (Daphne) on port ${PORT:-8000}..."
exec daphne -b 0.0.0.0 -p "${PORT:-8000}" tripplanner.asgi:application