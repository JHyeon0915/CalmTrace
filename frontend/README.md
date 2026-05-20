# CalmTrace Frontend

Flutter client for CalmTrace, a stress detection and wellness tracking app.

For the full repository guide, start with the root [README.md](../README.md).

## Quick Start

```bash
flutter pub get
flutter run -d chrome
```

## Useful Commands

```bash
flutter analyze lib test
flutter build web
flutter test
```

## Where Things Live

| Path | Purpose |
| --- | --- |
| `lib/main.dart` | App startup, theme, Firebase initialization |
| `lib/firebase_options.dart` | Firebase platform options |
| `lib/config/` | App/API configuration |
| `lib/network/` | API client |
| `lib/screens/` | Main user-facing screens |
| `lib/services/` | Auth, health data, notifications, AI coach, and stress services |
| `lib/models/` | Dart data models |
| `lib/widgets/` | Shared UI components |
| `assets/audio/` | Audio used by wellness activities |

## Notes

- Keep `.env` inside `frontend/`; it is loaded with `flutter_dotenv` and included in `pubspec.yaml`.
- Set `PRODUCTION_API_BASE_URL` in `.env` to the backend URL, for example `http://127.0.0.1:8000`.
- If Firebase settings change, regenerate `lib/firebase_options.dart` with `flutterfire configure`.
