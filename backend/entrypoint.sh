#!/bin/sh
# Exit immediately if a command exits with a non-zero status.
set -e

# Apply database migrations
echo "Applying database migrations..."
python manage.py migrate --noinput

# Start the Daphne server, listening on the port specified by the PORT env var.
echo "Starting server on port ${PORT:-8000}..."
exec daphne -b 0.0.0.0 -p "${PORT:-8000}" tripplanner.asgi:application