# Eletroluk Workshop — Desktop Frontend

Production desktop application built with **Flutter** for **Eletroluk**, an appliance repair workshop. Used daily by technicians and front-desk staff to manage repair orders, customers, device diagnostics, and payments.

This repository serves both as Eletroluk's live operational client and as a showcase of clean, testable, production-grade Flutter desktop architecture.

---

## Key Features

- **Workshop Dashboard:** Real-time overview of device statistics and active repair queues.
- **Device & Repair Lifecycle:**
  - Paginated device listing with infinite scroll and resilient error recovery.
  - Multi-filter search by status, customer, type, brand, model, and date range.
  - Device registration with cached catalog lookups (types, brands, models, colors, technicians).
  - Detailed repair view covering diagnostics, observations, customer contacts, and payment history.
- **Customer Management:** Customer directory, search, registration, and linked repair history.
- **Payment Tracking:** Itemized payment recording using exact integer-cent arithmetic (`Money(int cents)`).
- **Automated Updates:** Built-in startup update checker (`UpdateService`) integrated with GitHub Releases for Windows desktop deployments.

---

## Architecture & Engineering Highlights

The codebase follows a strict, modular layered architecture designed for maintainability, testability, and operational reliability:

- **Explicit Composition Root & Config Validation:**
  - Startup configuration is parsed once via `AppConfig.fromEnvironment()` (`lib/core/config/app_config.dart`); invalid configurations render `ConfigErrorApp` instead of failing at runtime.
  - All services, repositories, `Dio` clients, and secure storage instances are wired in `AppDependencies.create()` (`lib/core/di/app_dependencies.dart`) with constructor injection throughout.
- **Typed Error Handling & RFC 9457 Support:**
  - Services communicate through `ApiClient.send` and return `Result<T>` (`Ok` / `Err`) backed by an exhaustive `AppFailure` hierarchy.
  - `ApiClient` parses both legacy error payloads and **RFC 9457 `ProblemDetail`** responses.
- **Consolidated Data Layer:**
  - Domain-focused repositories (`DeviceRepository`, `CatalogRepository`, `CustomerRepository`) encapsulate API communication and in-memory catalog caching.
- **Security & Session Management:**
  - Device-bound API key setup persisted in the OS keyring via `flutter_secure_storage`.
  - Automatic JWT access/refresh token injection and synchronized renewal owned by `SecurityInterceptor` and `AuthService`.
  - Structured, payload-safe logging (`AppLogger` + `LogSanitizer`) that redacts tokens and sensitive customer data.
- **Accessibility & UI Testability:**
  - Interactive controls carry explicit `Semantics` identifiers (`<page>.<element>`), enabling deterministic widget and integration tests without brittle label matching.

---

## Tech Stack

| Layer | Technologies |
| --- | --- |
| **Framework & Language** | Flutter (Linux & Windows desktop), Dart (`^3.8.2`) |
| **State Management & DI** | `provider` (`ChangeNotifier`), explicit `AppDependencies` |
| **Networking** | `dio`, `ApiClient` with `Result<T>` & `ProblemDetail` |
| **Routing** | `go_router` |
| **Security & Storage** | `flutter_secure_storage`, `jwt_decoder`, `crypto`, `synchronized` |
| **UI & Formatting** | Material Design, `intl`, `shimmer`, `calendar_date_picker2` |
| **Tooling & Testing** | `flutter_test`, `integration_test`, `flutter_lints`, `mcp_toolkit` |

---

## Project Structure

```text
lib/
├── core/
│   ├── config/          # Environment validation (AppConfig)
│   ├── di/              # Composition root (AppDependencies)
│   ├── http/            # ApiClient, interceptors, RFC 9457 response validation
│   ├── logging/         # Structured logger & LogSanitizer
│   ├── money/           # Exact integer-cent Money value object
│   ├── result/          # Result<T> (Ok / Err) and AppFailure types
│   ├── route/           # GoRouter configuration & auth guards
│   └── security/        # Keyring storage & device binding
├── models/              # Domain models & DTOs
├── pages/               # Feature pages, controllers, and page-scoped widgets
├── repositories/        # catalog/, customer/, device/
├── services/            # auth/, customer_contact/, payment/, update/, etc.
└── widgets/             # Shared UI components, forms, and tables
```

---

## Configuration and Running

`.env` files are never committed or bundled as assets. Build configuration is injected at startup via `--dart-define-from-file` (`lib/core/config/app_config.dart`).

Copy `.env.example` or use the helper script to select an environment:

```bash
cp .env.example .env
# or
bash scripts/set_env.sh local
```

### Run locally

```bash
bash scripts/set_env.sh local
flutter run -d linux --dart-define-from-file=.env
```

### Run against QA without overwriting your local storage key

In debug mode, use `STORAGE_NAMESPACE` together with `RESET_STORAGE=true` and pass `.env-qa` directly (without overwriting `.env`):

```bash
flutter run -d linux \
  --dart-define-from-file=.env-qa \
  --dart-define=STORAGE_NAMESPACE=qa \
  --dart-define=RESET_STORAGE=true
```

To skip the setup screen and authenticate automatically (debug mode only):

```bash
flutter run -d linux \
  --dart-define-from-file=.env-qa \
  --dart-define=STORAGE_NAMESPACE=qa \
  --dart-define=RESET_STORAGE=true \
  --dart-define=DEV_API_KEY=<your-qa-api-key>
```

How storage isolation works:
- **Default setup preserved:** the API key and tokens are stored under prefixed keys in the keyring (`qa.api_key`, `qa.access_token`, `qa.refresh_token`), without reading or overwriting your default credentials.
- **Reset on boot:** `RESET_STORAGE=true` clears the namespaced API key and tokens on startup. To remove the `qa` namespace entries when you finish testing, sign out in the app before closing it.
- **Shared `bound_device_id`:** the machine identifier is not namespaced, keeping the device binding expected by the API.

---

## Quality Checks & Tests

CI runs formatting, static analysis, and the full unit/widget test suite on every pull request:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```
