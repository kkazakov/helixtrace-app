# HelixTrace Flutter App — Implementation Plan

## Overview
Modern Flutter app for HelixTrace API with authentication, sleek dark/light UI, and Map placeholder.

## Architecture (Layered)
```
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart          # Default API URL constant
│   ├── constants/
│   │   └── app_constants.dart        # Storage keys, routes
│   ├── storage/
│   │   └── storage_service.dart      # SharedPreferences wrapper
│   ├── theme/
│   │   ├── app_theme.dart           # Theme data class
│   │   ├── light_theme.dart         # Light theme
│   │   └── dark_theme.dart          # Dark theme
│   ├── utils/
│   │   └── validators.dart          # Email validator
│   └── widgets/
│       ├── sleek_text_field.dart    # Reusable styled text field
│       └── sleek_button.dart        # Reusable styled button
├── data/
│   ├── models/
│   │   ├── auth_response.dart
│   │   ├── point_model.dart
│   │   ├── trace_path_model.dart
│   │   └── point_category.dart
│   ├── services/
│   │   ├── api_service.dart         # Dio client with interceptors
│   │   └── auth_service.dart        # Login/Register logic
│   └── repositories/
│       └── auth_repository.dart     # Auth SSOT
├── features/
│   ├── auth/
│   │   ├── providers/
│   │   │   ├── auth_provider.dart   # Auth state management
│   │   │   └── theme_provider.dart  # Theme state management
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   └── home/
│       └── map_screen.dart          # Blank "Map" placeholder
└── main.dart
```

## Dependencies
| Package | Purpose |
|---|---|
| `flutter_riverpod: ^2.6.1` | State management |
| `go_router: ^14.8.1` | Navigation |
| `dio: ^5.8.0+1` | HTTP client with interceptors |
| `shared_preferences: ^2.5.3` | Persist token, API URL, theme |
| `shimmer: ^3.0.0` | Loading skeleton screens |
| `flutter_dotenv: ^5.2.1` | Environment config |

## API Integration
- **Base URL**: `https://trace-api.meshcore.bg/` (default, from `.env`)
- **Custom URL**: User can set via button on login page, saved to SharedPreferences
- **Auth**: Bearer token stored in SharedPreferences, auto-attached via Dio interceptor
- **Endpoints**: login, register, profile, points, trace-path, point-categories, etc.

## Screens & Flow
1. **Login** — Sleek design, disabled until API URL set, "Set API URL" button
2. **Register** — Same design, register action
3. **API URL Dialog** — Bottom sheet to enter custom URL
4. **Home (Map)** — Blank page with "Map" text centered

## Key Constraints
- Login/Register **disabled** until API URL is set at least once
- API URL persists in SharedPreferences across launches
- Theme defaults to device system preference

## Implementation Order
1. Initialize project + add dependencies
2. Create `.env` file
3. Create core layer (config, storage, theme, utils, widgets)
4. Create data layer (models, services, repository)
5. Create features (auth screens, home screen)
6. Set up routing in main.dart
7. Run `flutter pub get` + `flutter analyze`
