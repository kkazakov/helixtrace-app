# Core Infrastructure

**Type:** Explanation — this doc describes shared infrastructure: storage service, theming, validators, constants, and reusable UI widgets.

## Responsibility

Core infrastructure provides shared utilities used across all features. It handles persistent storage, visual theming, form validation, constant definitions, and reusable UI components. If this component fails, individual features may break but the app can still start — the damage is localized to the affected feature's functionality.

## Public Interface

### Storage Service

`StorageService` (`lib/core/storage/storage_service.dart:4`) — Singleton for persistent key-value storage via `SharedPreferences`.

| Method | Purpose |
|---|---|
| `init()` | Initialize SharedPreferences instance |
| `getApiKey()` / `setApiKey(String)` | Get/set API base URL |
| `getAuthToken()` / `setAuthToken(String)` | Get/set auth token |
| `clearAuthToken()` | Remove auth token (logout) |
| `getUserEmail()` / `setUserEmail(String)` | Get/set user email |
| `clearUserEmail()` | Remove user email |
| `getThemeMode()` / `setThemeMode(ThemeMode)` | Get/set theme preference |
| `getMapLayer()` / `setMapLayer(String)` | Get/set preferred map tile layer |

### Theming

`AppTheme` (`lib/core/theme/app_theme.dart:3`) — Static class providing light and dark `ThemeData`.

| Property | Purpose |
|---|---|
| `lightTheme` | Light mode theme with primary `#2563EB`, surface `#FAFBFF` |
| `darkTheme` | Dark mode theme with primary `#3B82F6`, surface `#0F172A` |

### Validators

`Validators` (`lib/core/utils/validators.dart:1`) — Static utility class with form validation methods.

| Method | Validates |
|---|---|
| `emailValidator(String?)` | Non-empty, valid email format |
| `passwordValidator(String?)` | Non-empty, minimum 6 characters |
| `urlValidator(String?)` | Non-empty, starts with `http://` or `https://` |

### Constants

`AppConstants` (`lib/core/constants/app_constants.dart:1`) — Centralized string keys.

| Constant | Value | Used For |
|---|---|---|
| `apiKey` | `'api_url'` | Storage key for API URL |
| `authToken` | `'auth_token'` | Storage key for auth token |
| `userEmail` | `'user_email'` | Storage key for user email |
| `themeMode` | `'theme_mode'` | Storage key for theme preference |
| `mapLayer` | `'map_layer'` | Storage key for map tile layer preference |
| `routeLogin` | `'/'` | Login route path |
| `routeRegister` | `'/register'` | Register route path |
| `routeHome` | `'/home'` | Home route path |

### Custom Widgets

| Widget | Location | Purpose |
|---|---|---|
| `SleekButton` | `lib/core/widgets/sleek_button.dart:4` | Themed button with loading state (shimmer animation) |
| `SleekTextField` | `lib/core/widgets/sleek_text_field.dart:3` | Themed text field with label, icon, validation, password toggle |

## Internal Structure

### Storage Service Singleton

`StorageService` uses the private constructor + factory pattern (`lib/core/storage/storage_service.dart:4-7`):

```dart
class StorageService {
  StorageService._internal();
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
}
```

The `init()` method must be called before any read/write operations. It initializes the `SharedPreferences` instance stored in `_prefs`.

### Theme Design System

`AppTheme` defines a consistent design system with:

- **Primary color:** `#2563EB` (blue)
- **Accent/secondary color:** `#06B6D4` (cyan)
- **Border radius:** 14px for all buttons and inputs
- **Input padding:** 16px horizontal, 14px vertical
- **Button padding:** 24px horizontal, 15px vertical
- **Card border radius:** 16px
- **Dialog border radius:** 20px

Light and dark themes share the same primary/accent colors but differ in surface colors, text colors, and input fill colors. The dark theme uses `#0B1120` as scaffold background and `#1E293B` as input/card fill.

### SleekButton

`SleekButton` (`lib/core/widgets/sleek_button.dart:4`) is a `StatelessWidget` that dynamically renders either an `ElevatedButton` or `OutlinedButton` based on the `isOutlined` parameter. When `isLoading` is `true`, it displays a `CircularProgressIndicator` with shimmer animation (from the `shimmer` package) instead of text.

### SleekTextField

`SleekTextField` (`lib/core/widgets/sleek_text_field.dart:3`) is a `StatelessWidget` that wraps a `TextFormField` with:

- A label text above the field
- A prefix icon
- An optional suffix icon for password visibility toggle
- Consistent 6px gap between label and field, 16px bottom margin
- Theme-aware text colors
- An `enabled` parameter to disable the entire field (used on login/register screens when no API URL is set)

The parameter `obsecureTextState` (note: typo — not `obscureTextState`) controls the visibility toggle state.

## Dependencies

### Internal Dependencies

- None — `core/` is the foundation layer and has no internal dependencies. It is imported by all other layers.

### External Dependencies

- `shared_preferences` — Persistent storage.
- `shimmer` — Loading animation for `SleekButton`.
- `flutter` — Material design components.

## Data Model

This component does not own data models. It defines string constants and configuration values.

## Key Logic

### Storage key inconsistency

`AppConstants` defines storage keys (`apiKey`, `authToken`, `userEmail`, `themeMode`, `mapLayer`) but `StorageService` hardcodes the same keys directly (`lib/core/storage/storage_service.dart:15-53`). The constants are not imported by the storage service, creating a duplication risk. If a key is changed in one place but not the other, storage operations will silently fail.

### Map layer persistence

`getMapLayer()` and `setMapLayer()` persist the user's preferred map tile layer as a string key (e.g., `'osm'`, `'opentopomap'`). The `MapScreen` restores this preference on startup and applies it to the `FlutterMap` tile layer.

### Password visibility state pattern

`SleekTextField` requires the caller to pass both an `obscureText` boolean and an `obsecureTextState` boolean (note the typo) plus an `onToggleVisibility` callback. The caller is responsible for managing the visibility state externally; the widget itself is stateless. This pattern couples the widget to the caller's state management.

### Static validation returns `String?`

`Validators` follows the Flutter convention where `null` means valid and a non-null `String` is the error message. This is consistent with `FormFieldValidator<String>` but means callers must check for `null` rather than a boolean.

## Configuration

| Config | Source | Purpose |
|---|---|---|
| Primary color | Hardcoded: `#2563EB` (`lightTheme`), `#3B82F6` (`darkTheme`) | Brand primary color |
| Accent color | Hardcoded: `#06B6D4` | Brand accent/secondary color |
| Font family | Theme defaults | App-wide font (Material 3 defaults) |
| Border radius | Hardcoded: 14px–16px | Consistent corner rounding |

## Design Decisions & Trade-offs

### Singleton storage service

`StorageService` is a singleton, which works for a single-storage app but makes testing harder (you cannot have multiple isolated storage instances). Constructor injection via Riverpod (as done in `providers.dart`) mitigates this somewhat by controlling the instance creation point.

### Theme colors hardcoded in AppTheme

Theme colors are hardcoded constants in `AppTheme` rather than being loaded from configuration or a design tokens file. This is simple but makes it harder to A/B test themes or support user-customizable colors.

### Validators as static methods

`Validators` is a static utility class rather than a provider or service. This is appropriate for stateless validation logic but means validators cannot depend on external configuration (e.g., a minimum password length stored on the backend).

## Testing

- No tests exist for `StorageService`, `AppTheme`, `Validators`, `SleekButton`, or `SleekTextField`.
- `StorageService` depends on `SharedPreferences`, which requires platform channels and cannot be easily unit-tested. Mock it with a test double or use `flutter_test` widget tests.
- To run existing tests: `flutter test`

## Related Components

- [State Management](state-management.md) — Providers consume `StorageService` and `AppTheme`.
- [Authentication](authentication.md) — Auth screens use `Validators`, `SleekButton`, `SleekTextField`, and `AppConstants`.
- [App Entry & Routing](app-entry-routing.md) — `main.dart` imports and initializes `StorageService` and `AppTheme`.
- [Map Screen](map-screen.md) — `MapScreen` uses `StorageService` for map layer persistence.