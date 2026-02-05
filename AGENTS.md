# Agent Guide for flutter-workshop-front

## Idioma
- Sempre responder em pt-BR.


## Project overview
- Flutter frontend app targeting mobile/desktop/web.
- Core code lives in `lib/` with `pages/`, `widgets/`, `services/`, `models/`, and `core/`.
- Tests are in `test/` using `flutter_test`.
- Assets are listed in `pubspec.yaml` and include `.env` and `assets/images/`.
- No Cursor rules found in `.cursor/rules/` or `.cursorrules`.
- No Copilot rules found in `.github/copilot-instructions.md`.

## Environment setup
- Install Flutter SDK matching `pubspec.yaml` SDK constraint (Dart ^3.5.3).
- Run `flutter pub get` after pulling dependencies or editing `pubspec.yaml`.
- Configure environment files via `bash scripts/set_env.sh local` or `bash scripts/set_env.sh prd`.
- `.env` is packaged as an asset, so keep it updated when running locally.

## Common build commands
- Debug run: `flutter run`.
- Run on a specific device: `flutter run -d <device-id>`.
- Android APK: `flutter build apk`.
- iOS (macOS only): `flutter build ios`.
- Web: `flutter build web`.
- Windows: `flutter build windows`.
- macOS: `flutter build macos`.
- Linux: `flutter build linux`.

## Lint and formatting
- Lint/analyze: `flutter analyze` (uses `analysis_options.yaml` and `flutter_lints`).
- Format all Dart files: `dart format .`.
- Format a single file: `dart format lib/path/to/file.dart`.
- Keep formatting consistent with 2-space indentation and trailing commas.

## Testing
- Run all tests: `flutter test`.
- Run a single file: `flutter test test/auth_pvt_test.dart`.
- Run a single widget test file: `flutter test test/widget_test.dart`.
- Run a single test by name:
- `flutter test test/auth_pvt_test.dart --plain-name "AuthService: Should identify ADMIN correctly via JWT (Simulated)"`.
- For widget tests, use `testWidgets` and `WidgetTester`.

## Import organization
- Use package imports for Flutter/Dart SDK and third-party packages first.
- Separate import groups with a blank line.
- Prefer `package:flutter_workshop_front/...` for app modules.
- Some service files use relative imports; follow the existing pattern within the file's folder.
- Avoid unused imports; let `flutter analyze` catch them.

## Naming conventions
- Files: lower_snake_case (e.g., `device_register_page.dart`).
- Classes/enums: UpperCamelCase (e.g., `CustomerModel`).
- Methods/variables: lowerCamelCase (e.g., `getDeviceStatistics`).
- Constants: lowerCamelCase with `const` or `static const`.
- Private members start with `_` (e.g., `_dio`).

## Types and null safety
- Use strong typing everywhere; avoid `dynamic` unless unavoidable.
- Mark optional fields with `?` and provide safe defaults.
- Prefer `final` for fields that do not change.
- Use `late` only when needed for lifecycle or deferred init.
- Leverage `Future<T>` and `Future<void>` for async APIs.

## Widget conventions
- Use `const` constructors/widgets when inputs are compile-time constants.
- Prefer classes to create widgets rather than function widgets
- Keep widgets small and focused; extract repeated UI into `widgets/`.
- Prefer `StatelessWidget` unless state is required.
- For state, use `ChangeNotifier` + `notifyListeners` as in controllers.
- Keep UI code declarative and avoid side effects in `build`.

## Security Architecture
- O app utiliza `QueuedInterceptor` no `SecurityInterceptor` para serializar requisições e evitar múltiplas chamadas de refresh simultâneas (deduplicação).
- Injeção automática de `Authorization: Bearer <token>` em todas as requisições via `SecurityInterceptor`.
- Se 401: O interceptor verifica se o token no storage já mudou (deduplicação); se for o mesmo, realiza o refresh. Após o sucesso, retenta a requisição original e usa `handler.resolve(response)` para que o erro seja invisível aos controllers.
- Se 403: Executa logout forçado, limpa storage e notifica via `AuthNotifier`. O erro é rejeitado com `DioExceptionType.cancel` para silenciar a UI.

## Controllers and state

- Controllers extend `ChangeNotifier` and expose simple state fields.
- Always use `try-finally` blocks when setting loading flags to ensure state is reset even on silent errors.
- Set loading flags before async calls, then reset in `finally` and notify.
- Keep controllers focused on orchestration, not UI rendering.
- Initialize services as private fields (e.g., `_deviceStatisticsService`).

## Services and repositories
- Services encapsulate HTTP calls via `Dio` using `CustomDio`.
- Repositories define interfaces and are typically implemented by services.
- Response handling uses explicit status checks (e.g., `[200, 201]`).
- Throw `RequisitionException.fromJson(response.data['error'])` on error.
- Keep service methods small and return domain models.
- Authentication (401/403) is handled globally via `SecurityInterceptor` (transparent retry).

## Error handling and logging
- Use try/catch around network calls that can fail.
- Catch `DioException` when inspecting HTTP status codes is needed.
- Use `debugPrint` for structured logs (see `AuthService`).
- When rethrowing, prefer `rethrow` to preserve stack traces.
- Ensure storage cleanup in `finally` blocks when logging out.
- Erros 401/403 são silenciados no interceptor; controllers não precisam tratar renovação de token manualmente.
- Requisições canceladas (`DioExceptionType.cancel`) são ignoradas pelo `GlobalErrorInterceptor`.


## Models and JSON
- Models use `factory ClassName.fromJson(Map<String, dynamic> json)`.
- Keep fields `final` and initialized in constructors.
- Parse lists with `.map(...).toList()` and handle null lists safely.
- Provide `toJson()` when models are sent to the API.
- Map JSON keys as returned by the backend; avoid renaming unless necessary.

## Async patterns
- Use `async`/`await` rather than chained `then`.
- Avoid unhandled futures; always `await` async calls in controllers/services.
- Use short artificial delays sparingly and only when needed for UX.

## UI strings and localization
- App uses `Intl` and `flutter_localizations` with `pt_BR` locale.
- Keep new UI strings consistent with existing Portuguese copy.
- If adding new locales, update `supportedLocales` and delegates.

## Mermaid Diagrams
- Use aliases for participants (e.g., `participant U as User`) to keep syntax clean.
- Avoid using colons (`:`) within labels or notes unless absolutely necessary, as it can break some parsers.
- Prefer simple arrows (`->>`, `-->>`) and keep labels concise and without special characters.
- For `stateDiagram-v2`, use short state names and simple transitions.

## Testing patterns

- Use `group` and `setUp` for organization.
- Manual mocks are acceptable when avoiding extra dependencies.
- Keep tests deterministic; avoid timers and network calls.
- Use `expect` with clear matcher semantics.

## Do and don’t
- Do keep file/module boundaries (models, services, widgets).
- Do keep changes minimal and aligned with surrounding patterns.
- Do run `flutter analyze` before handing off changes.
- Don’t introduce new dependencies without a strong reason.
- Don’t swallow exceptions silently unless documented (see `logout`).
- Don’t add unused assets or unused imports.
