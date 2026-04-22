# HelixTrace

Network mapping and tracing application for mobile.

## What It Is

HelixTrace is a Flutter mobile application that lets users create, manage, and visualize geographic network points and trace paths. Users authenticate via email/password, then manage points with location, elevation, categorization, and visibility settings.

See [PURPOSE.md](PURPOSE.md) for the business context and goals.

## Build, Run, Test

```bash
# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze
```

Configuration is loaded from `.env` (API base URL). The default backend is `https://trace-api.meshcore.bg/`.

## Architecture at a Glance

HelixTrace is a single-container Flutter app that communicates with the HelixTrace Backend API. It follows a layered architecture with clear separation between UI, state management, data access, and shared infrastructure.

### Component Table

| Component | Location | Responsibility |
|---|---|---|
| [App Entry & Routing](docs/explanation/app-entry-routing.md) | `lib/main.dart` | Initialization, GoRouter navigation, auth shell |
| [Authentication](docs/explanation/authentication.md) | `lib/features/auth/` | Login/register screens, auth state, repository |
| [Data Layer](docs/explanation/data-layer.md) | `lib/data/` | HTTP client, services, repositories, data models |
| [State Management](docs/explanation/state-management.md) | `lib/features/auth/providers/` | Riverpod providers, dependency injection, auth/theme state |
| [Core Infrastructure](docs/explanation/core-infrastructure.md) | `lib/core/` | Storage, theming, validators, constants, reusable widgets |
| Map (placeholder) | `lib/features/home/` | Placeholder screen — not yet implemented |

See the [Architecture Overview](docs/explanation/architecture-overview.md) for system context, data flow, and cross-cutting concerns.

## Repository Map

```
lib/
├── main.dart                    # App entry point, router provider, auth shell
├── core/                        # Shared infrastructure
│   ├── config/app_config.dart   # Default API URL
│   ├── constants/app_constants.dart  # Storage keys, route names
│   ├── storage/storage_service.dart  # SharedPreferences singleton
│   ├── theme/app_theme.dart     # Light/dark ThemeData
│   ├── utils/validators.dart    # Email, password, URL validators
│   └── widgets/                 # SleekButton, SleekTextField
├── data/                        # Data layer
│   ├── models/                  # AuthResponse, PointModel, TracePathModel, etc.
│   ├── repositories/            # AuthRepository
│   └── services/                # ApiService, AuthService
└── features/                    # Feature modules
    ├── auth/                    # LoginScreen, RegisterScreen, providers
    └── home/                    # MapScreen (placeholder)
test/
└── widget_test.dart             # App initialization widget test
```

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart, SDK ^3.11.5) |
| State Management | flutter_riverpod ^2.6.1 |
| Navigation | go_router ^14.8.1 |
| HTTP Client | dio ^5.8.0+1 |
| Local Storage | shared_preferences ^2.5.3 |
| Environment Config | flutter_dotenv ^5.2.1 |
| Loading UI | shimmer ^3.0.0 |
| Design | Material 3, custom light/dark themes |

## Documentation

- [Documentation Index](docs/index.md) — Links to all docs
- [Architecture Overview](docs/explanation/architecture-overview.md) — System map, data flow, cross-cutting concerns
- [PURPOSE.md](PURPOSE.md) — Business intent and constraints

## Current State

- **Authentication:** Complete (login, register, token persistence, error handling)
- **Data Layer:** Complete (API service, models, auth repository)
- **Theming:** Complete (light/dark with persistent preference)
- **Map/Tracing:** Placeholder — UI skeleton exists, actual mapping functionality is not implemented
- **Tests:** Minimal — one widget test for app initialization
