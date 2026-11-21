# Agent Guide for flutter-workshop-front

Only what the code does not tell you.

## Environment

- `.env` is never committed or bundled as an asset: configure via `bash scripts/set_env.sh local` or `bash scripts/set_env.sh prd` (or copy `.env.example`) and run with `--dart-define-from-file=.env`.

## Security & Auth

- `SecurityInterceptor` and `AuthService` own token injection, refresh, and logout; controllers never handle token renewal.
- Only force logout on `403` when the API rejects the credential (`auth.invalid.api.key` or `auth.invalid.token`); generic `403` responses (role/WAF) propagate to the caller.
- Never convert transient network/refresh failures into `DioExceptionType.cancel` (`GlobalErrorInterceptor` silences `cancel`); return/propagate them so errors surface and the session stays intact.
- Offline or storage failures at boot preserve `apiKey` and route via `AuthRouteState.offline` / `AuthRouteState.storageError` (`BootstrapErrorPage`), never to `needsSetup`.

## State, UI & Domain

- Always use `ChangeNotifierProvider` (never `InheritedWidget`/`InheritedNotifier`, despite the legacy `InheritedAllCustomerController`) and `try-finally` around loading flags; canonical reference: `DeviceDetailsPage`.
- Prefer widget classes over `_build*` helper methods.
- Represent monetary values with `Money(int cents)` (`lib/core/money/money.dart`), never raw `double` arithmetic.
- New paginated lists should use `InfiniteScrollListener` with `loadMoreFailed` guard and `LoadMoreErrorFooter`.

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
