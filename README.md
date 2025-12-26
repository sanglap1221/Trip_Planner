# Smart Trip Planner (Flutter + Django)

This repo contains:

- Backend: Django REST API in [backend](backend) with JWT auth, trip features, OpenAPI docs, and Docker setup.
- Frontend: Flutter app in [trip](trip) using BLoC, Dio, and Hive with basic Login and Trips list.

## Run Backend (local)

```powershell
cd backend
python -m venv .venv
. .venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 0.0.0.0:8000
```

Docs: http://localhost:8000/api/docs/

## Run Backend (Docker Compose)

```powershell
docker compose up --build
```

## Run Flutter app

```powershell
cd trip
flutter pub get
flutter run -d windows  # Or emulator; ensure API points to backend
```

Configure API base via Dart define: `--dart-define=API_BASE_URL=http://localhost:8000/api/` (use `http://10.0.2.2:8000/api/` on Android emulator).

## CI/CD

- Backend workflow: [.github/workflows/backend.yml](.github/workflows/backend.yml)
- Flutter workflow: [.github/workflows/flutter.yml](.github/workflows/flutter.yml)

## Deployment

Deploy backend to Render/Cloud Run/DO/AWS using the Dockerfile and set `DATABASE_URL`, `DJANGO_SECRET_KEY`, and allowed hosts. Use a managed PostgreSQL.

## Design Decisions & Tradeoffs

- Used long-polling chat initially for simplicity and reliability.
- Added WebSocket support via Django Channels as an optimization for real-time updates.
- Implemented offline-first caching for the trip list (core UX on slow/spotty networks).
- Deferred full offline sync for chat/polls to reduce complexity for this assignment timeframe.
- Used BLoC for predictability, testability, and clear separation of UI/state/business logic.
