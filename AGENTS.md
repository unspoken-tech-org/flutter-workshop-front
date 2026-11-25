# Agent Guide for flutter-workshop-front

Only what the code does not tell you.

## Environment

- `.env` is never committed or bundled as an asset: configure via `bash scripts/set_env.sh local` or `bash scripts/set_env.sh prd` (or copy `.env.example`) and run with `--dart-define-from-file=.env`.

## Security & Auth

- `SecurityInterceptor` and `AuthService` own token injection, refresh, and logout; controllers never handle token renewal.
- Only force logout on `403` when the API rejects the credential (`auth.invalid.api.key` or `auth.invalid.token`); generic `403` responses (role/WAF) propagate to the caller.
- Never convert transient network/refresh failures into `DioExceptionType.cancel` (`GlobalErrorInterceptor` silences `cancel`); return/propagate them so errors surface and the session stays intact.
- Offline or storage failures at boot preserve `apiKey` and route via `AuthRouteState.offline` / `AuthRouteState.storageError` (`BootstrapErrorPage`), never to `needsSetup`.

## HTTP & Logging

- Services call the API through `ApiClient.send` (`lib/core/http/api_client.dart`) with the endpoint's `expectedStatus` and return `Result<T>` (`lib/core/result/`); never check status codes in services. Controllers handle `Ok`/`Err` with an exhaustive `switch` on `AppFailure`. Exceptions: `AuthService` and `UpdateService`.
- `AppLogger` messages record events and codes, never request/response payloads, tokens or customer data; `LogSanitizer` is a safety net, not the filter.

## State, UI & Domain

- Always use `ChangeNotifierProvider` (never `InheritedWidget`/`InheritedNotifier`, despite the legacy `InheritedAllCustomerController`) and `try-finally` around loading flags; canonical reference: `DeviceDetailsPage`.
- Prefer widget classes over `_build*` helper methods.
- Represent monetary values with `Money(int cents)` (`lib/core/money/money.dart`), never raw `double` arithmetic.
- New paginated lists should use `InfiniteScrollListener` with `loadMoreFailed` guard and `LoadMoreErrorFooter`.
- Every interactive control carries `Semantics(identifier: '<page>.<element>')` (form fields take `semanticsIdentifier:`); a test or agent that finds one missing adds it in the code instead of matching a label, since pages share labels and offstage pages stay in the tree. Conventions: skill `flutter-ui-mcp`.
- A UI scenario that will be re-run goes to `integration_test/`, not to an MCP session (skill `flutter-ui-mcp`).

## Checks & Dependencies

- Run `dart format .`, `flutter analyze`, and `flutter test` before handing off changes; CI fails on any of them.
- Don't introduce new dependencies without a strong reason, and don't swallow exceptions silently unless documented (see `AuthService.logout`).

## Git

Never push to `main` or `release/*` directly, never squash or rebase a shared branch, and never create a tag unless the user asks: a tag publishes a release that every installed app downloads.

Read the matching file before the task (load it only then):

| Before you... | Read |
| --- | --- |
| create a branch or fix a bug | `instructions/git/branches.md` |
| commit | `instructions/git/commits.md` |
| open or update a PR | `instructions/git/pull-requests.md` |
| create a tag or release | `instructions/git/releases.md` |
