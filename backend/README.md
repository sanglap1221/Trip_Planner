# Smart Trip Planner Backend

Django REST API with JWT auth, trip management, collaborators, itinerary, polls, and chat (long-polling). OpenAPI docs and Dockerized for deployment.

## Quickstart (local)

```bash
# In backend/
python -m venv .venv
. .venv/Scripts/activate  # Windows PowerShell: .venv\Scripts\Activate.ps1
pip install -r requirements.txt

# Configure env (optional)
copy .env.example .env

# Migrate and run
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

- API root: http://localhost:8000/api/
- Swagger UI: http://localhost:8000/api/docs/
- Obtain JWT: POST /api/auth/token/ with `{ "username", "password" }`

## Docker Compose

```bash
# From repo root
docker compose up --build
```

- API: http://localhost:8000
- DB: Postgres on 5432

## Environment

See `.env.example` for variables: `DATABASE_URL`, `DJANGO_SECRET_KEY`, `ALLOWED_HOSTS`, SSL and email config.

## Endpoints (high level)

- POST `/api/auth/token/`, `/api/auth/token/refresh/`
- CRUD `/api/trips/` (+ `collaborators`, `reorder-itinerary` actions)
- CRUD `/api/itinerary-items/`
- CRUD `/api/polls/` + POST `/api/polls/{id}/vote/`
- List/Create `/api/messages/?trip={id}&after_id={last}`
- POST `/api/invites/` (sends email with token)

## Middleware

- Request/Response logging
- Simple rate limiting (per IP/user)
- Global error handler

## Real-time Chat

- WebSockets: Channels/Daphne at `ws://<host>/ws/trips/{trip_id}/`
- Fallback: REST long-polling via `/api/messages/?trip={id}&after_id={last}`

## Deployment

- Build image using Dockerfile; run with `gunicorn tripplanner.wsgi`
- WebSockets enabled via Daphne (`ASGI`)
- Provide `DATABASE_URL` for managed PostgreSQL
- Enable HTTPS and set `SECURE_*` env vars
