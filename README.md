# Smart Trip Planner (Flutter + Django)

This repo contains:

## Run Backend (local)

```powershell
cd backend
python -m venv .venv
. .venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
# Optional: Populate with sample data
python manage.py populate_sample_data
python manage.py runserver 0.0.0.0:8000
```

**Sample Users** (if you ran `populate_sample_data`):

- Username: `demo`, Password: `demo123` (has Tokyo & Paris trips)
- Username: `traveler`, Password: `travel123` (has Iceland trip)

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

## Deployment

Deploy backend to Render/Cloud Run/DO/AWS using the Dockerfile and set `DATABASE_URL`, `DJANGO_SECRET_KEY`, and allowed hosts. Use a managed PostgreSQL.

## Quick Start with Sample Data

1. **Backend Setup:**

   ```powershell
   cd backend
   & ..\.venv\Scripts\Activate.ps1
   python manage.py migrate
   python manage.py populate_sample_data  # Creates 3 sample trips with itinerary, polls & chat
   python manage.py runserver 0.0.0.0:8000
   ```

2. **Flutter App:**

   ```powershell
   cd trip
   flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8000/api/
   ```

3. **Login** with sample account:

   - Username: `demo` | Password: `demo123`

4. **Features to Test:**
   - ✅ **Offline-first:** Kill backend, restart app → see cached trips
   - ✅ **Auto-caching:** Trips are automatically cached when loaded from API
   - ✅ **Itinerary:** Drag to reorder items
   - ✅ **Polls:** Vote and see results update
   - ✅ **Real-time Chat:** Open 2 app instances, send messages

**📦 What's Included:**

- 3 sample trips: Tokyo Adventure, Paris Weekend, Iceland Road Trip
- 11 itinerary items across all trips
- 3 polls with multiple options
- Sample chat messages
- 2 demo users (demo & traveler)

## Design Decisions & Tradeoffs

# Smart Trip Planner — RemoteWard Assignment

## Objective

Design and implement a production-ready Smart Trip Planner using a Flutter frontend and Django backend. The goal is to build a scalable, secure, and well-architected full‑stack system, covering backend APIs, real-time features, frontend architecture, offline support, CI/CD, deployment, and overall product-level thinking with smooth UI/UX.

## Requirements

- **Backend (Django):**
  - REST APIs using Django and Django REST Framework with JWT-based authentication.
  - Core features: trip management, collaborators, itinerary items, polls with voting, and in-trip chat (WebSockets or long‑polling).
  - Email invitations without Celery (synchronous or async views).
  - Middleware: authentication checks, request/response logging, rate limiting, global error handling.
  - Database: PostgreSQL with proper schema design, migrations, and indexing.
  - Dockerized backend and documented via OpenAPI/Swagger.
- **Frontend (Flutter):**
  - BLoC architecture with clear separation of UI, state, and business logic.
  - Features: login/signup, trip listing and details, itinerary management with drag-and-reorder, UI for polls and chat.
  - Offline‑first using local storage (Hive or Sqflite) and sync on connectivity restore.
  - Focus on smooth UI/UX: animations, skeleton loaders, optimistic updates.
  - Include unit tests for BLoCs and basic widget tests.
- **CI/CD:**
  - GitHub Actions pipelines for backend and frontend.
  - Backend pipeline: linting, building, deployment.
  - Flutter pipeline: static analysis and app builds.
  - Use GitHub Secrets for all sensitive values; no secrets committed.
- **Deployment:**
  - Deploy backend on a cloud platform (Render, Cloud Run, DigitalOcean, or AWS) with HTTPS and managed PostgreSQL.
  - Flutter app should be buildable and runnable as part of the submission.

## Bonus (Optional)

- Expense splitting within trips
- Calendar export
- Encrypted chat

## Submission Guidelines

Email the GitHub repository link to info@remoteward.com with a 2–5‑minute demo video showing the project features.

## Time Duration

7 days after the date of receiving the assignment.

## Repository Structure

- Backend service: [backend/](backend/)
- Flutter app: [trip/](trip/)

This repository uses a single authoritative README (this file). Duplicate documentation files have been removed to avoid confusion.
