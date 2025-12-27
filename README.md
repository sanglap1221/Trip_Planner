# Smart Trip Planner

A production-ready trip planning app built with **Flutter** (frontend) and **Django** (backend). Features include trip management, itineraries, polls, real-time chat, offline-first support, and JWT authentication.

## Quick Start (Localhost)

### 1. Backend Setup

```powershell
cd backend
python -m venv .venv
. .venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py migrate
python manage.py populate_sample_data  # Loads sample data
python manage.py runserver 0.0.0.0:8000
```

API Docs: http://localhost:8000/api/docs/

### 2. Flutter App Setup

```powershell
cd trip
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8000/api/
```

### 3. Login

Use demo credentials:

- **Username:** `demo`
- **Password:** `traveler`

---

## Features

- ✅ Trip management with collaborators
- ✅ Itinerary with drag-and-drop reordering
- ✅ Polls with voting
- ✅ Real-time in-trip chat (WebSockets)
- ✅ Offline-first with local caching
- ✅ JWT authentication
- ✅ Responsive UI with animations

---

## Sample Data

The `populate_sample_data` command creates:

- 3 sample trips (Tokyo, Paris, Iceland)
- 11 itinerary items
- 3 polls
- Sample chat messages
- 2 demo users (demo, traveler)

---

## Docker Deployment

```powershell
docker compose up --build
```

---

## Production Deployment (Render)

1. Create PostgreSQL database on Render
2. Create Web Service → Docker environment
3. Set env variables:
   - `DATABASE_URL` → PostgreSQL connection
   - `DJANGO_SECRET_KEY` → Random secret
   - `DJANGO_ALLOWED_HOSTS` → Your domain
   - `DJANGO_DEBUG` → `False`
4. Deploy

Visit API: `https://your-domain.onrender.com/api/docs/`

---

## Repository Structure

- [backend/](backend/) – Django REST API
- [trip/](trip/) – Flutter app
