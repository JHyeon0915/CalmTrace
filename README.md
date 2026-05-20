# CalmTrace Research

CalmTrace is a stress detection and wellness tracking project with a Flutter app, a FastAPI backend, Firebase authentication/messaging, MongoDB persistence, and ML-based stress prediction services.

## Table of Contents

- [Project Map](#project-map)
- [Quick Start](#quick-start)
- [Backend](#backend)
- [Frontend](#frontend)
- [Firebase](#firebase)
- [Environment Variables](#environment-variables)
- [Common Workflows](#common-workflows)
- [Troubleshooting](#troubleshooting)

## Project Map

```text
CalmTrace-Research/
|-- backend/                  FastAPI backend and ML services
|   |-- main.py               API entry point, CORS, route registration
|   |-- requirements.txt      Python dependencies
|   `-- app/
|       |-- config.py         Environment-backed settings
|       |-- database.py       MongoDB connection and indexes
|       |-- routers/          API route modules
|       |-- services/         Business logic and stress prediction services
|       |-- schemas/          Pydantic request/response models
|       `-- models/           Trained model/scaler artifacts
`-- frontend/                 Flutter app
    |-- lib/
    |   |-- main.dart         App entry point and Firebase initialization
    |   |-- firebase_options.dart
    |   |-- config/           API configuration
    |   |-- network/          API client
    |   |-- screens/          App screens and flows
    |   |-- services/         Auth, health, notification, stress services
    |   |-- models/           App data models
    |   `-- widgets/          Reusable UI widgets
    |-- assets/audio/         Audio used by calming activities
    |-- android/ ios/ web/    Platform projects
    `-- pubspec.yaml          Flutter dependencies and assets
```

## Quick Start

### 1. Backend API

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
```

The API runs at `http://127.0.0.1:8000`.

Useful endpoints:

- `GET /` - API status message
- `GET /health` - health check
- `GET /docs` - interactive OpenAPI docs

### 2. Flutter App

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

For iOS or Android, start a simulator/device first, then run:

```bash
flutter run
```

## Backend

The backend is a FastAPI application with route groups under `/v1`.

| Area | Files | Routes |
| --- | --- | --- |
| Authentication | `backend/app/routers/auth.py`, `backend/app/auth.py` | `/v1/auth` |
| Streaks | `backend/app/routers/streak.py`, `backend/app/services/streak_service.py` | `/v1/streak` |
| Goals | `backend/app/routers/goals.py`, `backend/app/services/goals_service.py` | `/v1/goals` |
| Notifications | `backend/app/routers/notifications.py`, `backend/app/services/notification_service.py` | `/v1/notifications` |
| Stress Prediction | `backend/app/routers/stress.py`, `backend/app/services/stress_prediction_service.py` | `/v1/stress` |
| AI Coach | `backend/app/routers/ai_coach.py`, `backend/app/services/ai_coach_service.py` | `/v1/ai-coach` |

Database setup lives in `backend/app/database.py`. It connects to MongoDB using settings from `backend/app/config.py` and creates indexes for streaks, goals, notifications, devices, and notification logs.

## Frontend

The Flutter app is organized around screens, services, models, and reusable widgets.

| Area | Files |
| --- | --- |
| App startup | `frontend/lib/main.dart` |
| Firebase config | `frontend/lib/firebase_options.dart` |
| API config/client | `frontend/lib/config/api_config.dart`, `frontend/lib/network/api_client.dart` |
| Auth flow | `frontend/lib/screens/auth_wrapper.dart`, login/signup/forgot-password screens |
| Dashboard and tracking | `frontend/lib/screens/dashboard_screen.dart`, `frontend/lib/screens/tracking_screen.dart` |
| Wellness activities | breathing, tapping, puzzle, rhythm, mindfulness, and reframing screens |
| Settings and notifications | `frontend/lib/screens/settings_screen.dart`, notification widgets/services |
| Shared UI | `frontend/lib/widgets/` |

## Firebase

Firebase is used by the Flutter app for authentication, Firestore, and messaging.

Current config files:

- Android: `frontend/android/app/google-services.json`
- iOS: `frontend/ios/Runner/GoogleService-Info.plist`
- macOS: `frontend/macos/Runner/GoogleService-Info.plist`
- Flutter options: `frontend/lib/firebase_options.dart`

If Firebase apps or bundle IDs change, regenerate the Flutter options:

```bash
cd frontend
flutterfire configure
```

## Environment Variables

### Backend `.env`

Create `backend/.env` for local backend configuration:

```env
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=stress_app
GOOGLE_APPLICATION_CREDENTIALS=
```

These values are loaded by `backend/app/config.py`.

### Frontend `.env`

The Flutter app loads `frontend/.env` through `flutter_dotenv`. Keep it in `frontend/` because `pubspec.yaml` includes it as an asset.

```env
PRODUCTION_API_BASE_URL=http://127.0.0.1:8000
```

The app reads this value in `frontend/lib/config/api_config.dart`.

## Common Workflows

### Run the backend locally

```bash
cd backend
source .venv/bin/activate
uvicorn main:app --reload
```

### Run the Flutter web app

```bash
cd frontend
flutter run -d chrome
```

### Analyze the Flutter app

```bash
cd frontend
flutter analyze lib test
```

### Build the Flutter web app

```bash
cd frontend
flutter build web
```

## Troubleshooting

### Chrome opens to a blank screen

Check the browser console first. If you see `FirebaseOptions cannot be null`, confirm `frontend/lib/main.dart` initializes Firebase with `DefaultFirebaseOptions.currentPlatform` and that `frontend/lib/firebase_options.dart` includes a web config.

### Backend cannot connect to MongoDB

Confirm MongoDB is running and that `MONGODB_URL` in `backend/.env` points to the right instance. The default is `mongodb://localhost:27017`.

### Full Flutter analyze reports generated package errors

If generated build outputs are present, a broad `flutter analyze` may scan files under `frontend/build/`. Prefer:

```bash
cd frontend
flutter analyze lib test
```
