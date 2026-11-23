import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:synchronized/synchronized.dart';
import '../../core/exceptions/requisition_exception.dart';
import '../../core/config/config.dart';

import '../../core/http/api_auth_error.dart';
import '../../core/http/custom_dio.dart';
import '../../core/http/response_validation.dart';
import '../../core/security/auth_debug_log.dart';
import '../../core/security/auth_notifier.dart';
import '../../core/security/refresh_result.dart';
import '../../core/security/security_storage.dart';
import '../../models/auth/token_request.dart';
import '../../models/auth/token_response.dart';

enum SessionRestoreResult {
  restored,
  invalidCredentials,
  transientError,
  noApiKey,
}

class AuthService {
  /// Espera aplicada quando o `429` do refresh vem sem `Retry-After` válido.
  static const refreshRetryAfterFallback = Duration(seconds: 30);

  /// Teto defensivo para um `Retry-After` exagerado não travar o refresh.
  static const refreshRetryAfterMax = Duration(hours: 1);

  final Dio _dio;
  final SecurityStorage _storage;
  final AuthNotifier _authNotifier;
  final DateTime Function() _now;
  final Lock _storageLock = Lock();
  int _sessionEpoch = 0;

  /// Até quando o refresh fica suspenso após um `429` (zona `/api/auth/*`).
  DateTime? _refreshBlockedUntil;
  Response<dynamic>? _refreshRateLimitResponse;

  AuthService({
    Dio? dio,
    SecurityStorage? storage,
    required AuthNotifier authNotifier,
    @visibleForTesting DateTime Function()? clock,
  }) : _authNotifier = authNotifier,
       _dio = dio ?? CustomDio.authDioInstance(),
       _storage = storage ?? SecurityStorage(),
       _now = clock ?? DateTime.now;

  Future<String?> get apiKey async => (await _storage.getApiKey());
  Future<bool> get hasApiKey async => (await apiKey) != null;

  Future<bool> get hasSession async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      return true;
    }
    final accessToken = await _storage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return false;
    }
    return !_isTokenExpired(accessToken);
  }

  bool _isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      return true;
    }
  }

  /// RBAC: Checks if user has ADMIN role by decoding the current JWT.
  Future<bool> get isAdmin async {
    final token = await _storage.getAccessToken();
    if (token == null || JwtDecoder.isExpired(token)) {
      debugPrint('[AuthDebug] Token null or expired. isAdmin: false');
      return false;
    }

    final decodedToken = JwtDecoder.decode(token);
    final List<dynamic> roles =
        (decodedToken['roles'] as List<dynamic>?) ?? <dynamic>[];
    final isAdmin = roles.contains('ADMIN');
    debugPrint('[AuthDebug] Decoded roles: $roles. isAdmin: $isAdmin');
    return isAdmin;
  }

  /// Performs initial authentication exchanging API Key for JWT tokens.
  Future<void> authenticate(String apiKey) async {
    final epochAtStart = ++_sessionEpoch;
    try {
      final boundDeviceId = await _storage.getBoundDeviceId();
      final appVersion = await Config.appVersion;

      final response = await _dio.post<dynamic>(
        '/api/auth/token',
        options: Options(headers: {'X-API-Key': apiKey}),
        data: TokenRequest(
          boundDeviceId: boundDeviceId,
          appVersion: appVersion,
        ).toJson(),
      );

      if (response.statusCode == 200) {
        if (response.data is! Map<String, dynamic>) {
          throw const FormatException('Invalid token response');
        }
        final tokenResponse = TokenResponse.fromJson(
          response.data as Map<String, dynamic>,
        );

        debugPrint('[AuthDebug] Authenticate successful. Saving tokens...');
        await _storageLock.synchronized(() async {
          if (_sessionEpoch != epochAtStart) {
            return;
          }
          // Save API Key only if authentication succeeds
          await _storage.saveApiKey(apiKey);
          await _storage.saveTokens(
            tokenResponse.accessToken,
            tokenResponse.refreshToken,
          );
          _authNotifier.setState(AuthRouteState.authenticated);
        });
      } else {
        // 409 (conflito de dispositivo) e demais 4xx entregues pelo
        // validateStatus: o setup não pode marcar sucesso.
        if (ApiAuthError.isCredentialRejected(response)) {
          await _storageLock.synchronized(() async {
            if (_sessionEpoch == epochAtStart) {
              try {
                await _storage.clearProvisioning();
              } finally {
                _authNotifier.setState(AuthRouteState.needsSetup);
              }
            }
          });
        }
        throw requisitionExceptionFromResponse(response);
      }
    } on DioException catch (e) {
      authDebugLog('Authenticate failed', error: e);
      if (e.response?.statusCode == 401 ||
          ApiAuthError.isCredentialRejected(e.response)) {
        await _storageLock.synchronized(() async {
          if (_sessionEpoch == epochAtStart) {
            try {
              await _storage.clearProvisioning();
            } finally {
              _authNotifier.setState(AuthRouteState.needsSetup);
            }
          }
        });
      } else {
        await _storageLock.synchronized(() async {
          if (_sessionEpoch == epochAtStart) {
            try {
              await _storage.clearSession();
            } catch (_) {}
          }
        });
      }
      rethrow;
    } on RequisitionException {
      rethrow;
    } catch (e) {
      authDebugLog('Authenticate failed', error: e);
      // If initial auth fails, ensure session is cleared but preserve boundDeviceId
      await _storageLock.synchronized(() async {
        if (_sessionEpoch == epochAtStart) {
          try {
            await _storage.clearSession();
          } catch (_) {}
        }
      });
      rethrow;
    }
  }

  Future<SessionRestoreResult> restoreSessionFromStoredApiKey() async {
    final apiKey = await _storage.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return SessionRestoreResult.noApiKey;
    }

    if (await hasSession) {
      return SessionRestoreResult.restored;
    }

    try {
      await authenticate(apiKey);
      return SessionRestoreResult.restored;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 ||
          ApiAuthError.isCredentialRejected(e.response)) {
        return SessionRestoreResult.invalidCredentials;
      }
      return SessionRestoreResult.transientError;
    } on RequisitionException catch (e) {
      if (e.code == ApiAuthError.invalidApiKey ||
          e.code == ApiAuthError.invalidToken ||
          e.code == '409' ||
          e.code == 'DEVICE_BOUND') {
        await _clearProvisioningAndResetState();
        return SessionRestoreResult.invalidCredentials;
      }
      return SessionRestoreResult.transientError;
    } on FormatException {
      return SessionRestoreResult.transientError;
    }
  }

  /// Performs silent Access Token refresh.
  Future<RefreshResult> refreshToken() async {
    debugPrint('[AuthDebug] Starting refreshToken flow...');
    final epochAtStart = _sessionEpoch;
    final String? currentRefreshToken;
    try {
      currentRefreshToken = await _storage.getRefreshToken();
    } catch (e) {
      authDebugLog('Failed reading refresh token', error: e);
      return RefreshTransientFailure(
        errorType: DioExceptionType.unknown,
        error: e,
      );
    }

    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      debugPrint('[AuthDebug] No refresh token found.');
      return const RefreshSessionExpired();
    }

    if (_sessionEpoch != epochAtStart) {
      debugPrint('[AuthDebug] Session epoch changed before refresh request.');
      return const RefreshSessionExpired();
    }

    final blockedUntil = _refreshBlockedUntil;
    if (blockedUntil != null) {
      if (_now().isBefore(blockedUntil)) {
        debugPrint(
          '[AuthDebug] Refresh rate limited until $blockedUntil. Skipping request.',
        );
        return RefreshTransientFailure(
          errorType: DioExceptionType.badResponse,
          response: _refreshRateLimitResponse,
          error: 'Refresh suspenso por rate limit (429) até $blockedUntil',
        );
      }
      _refreshBlockedUntil = null;
      _refreshRateLimitResponse = null;
    }

    try {
      final response = await _dio.post<dynamic>(
        '/api/auth/refresh',
        data: {'refreshToken': currentRefreshToken},
        options: Options(extra: {'silent': true}),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode != 200 && statusCode != 201) {
        debugPrint('[AuthDebug] Unexpected refresh status: $statusCode');
        return await _handleRefreshRejection(
          response,
          epochAtStart: epochAtStart,
        );
      }

      if (response.data is! Map<String, dynamic>) {
        debugPrint('[AuthDebug] Invalid refresh payload format.');
        if (_sessionEpoch == epochAtStart) {
          await logout();
        }
        return const RefreshSessionExpired();
      }

      final payload = response.data as Map<String, dynamic>;
      final newAccessToken = payload['accessToken'] as String?;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        debugPrint('[AuthDebug] Invalid refresh payload: missing accessToken.');
        if (_sessionEpoch == epochAtStart) {
          await logout();
        }
        return const RefreshSessionExpired();
      }

      final newRefreshToken = payload['refreshToken'] as String?;

      return await _storageLock.synchronized(() async {
        if (_sessionEpoch != epochAtStart) {
          debugPrint(
            '[AuthDebug] Session epoch changed while refresh was in flight. Discarding token.',
          );
          return const RefreshSessionExpired();
        }

        try {
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            debugPrint(
              '[AuthDebug] Refresh successful. Rotating access and refresh tokens.',
            );
            await _storage.saveTokens(newAccessToken, newRefreshToken);
          } else {
            debugPrint(
              '[AuthDebug] Refresh successful. Saving new access token.',
            );
            await _storage.saveAccessToken(newAccessToken);
          }
          return RefreshSuccess(newAccessToken);
        } catch (e) {
          authDebugLog('Failed saving refreshed token', error: e);
          return RefreshTransientFailure(
            errorType: DioExceptionType.unknown,
            error: e,
          );
        }
      });
    } on DioException catch (e) {
      debugPrint(
        '[AuthDebug] Refresh failed with status ${e.response?.statusCode}',
      );
      if (e.response?.statusCode == 401 ||
          ApiAuthError.isCredentialRejected(e.response)) {
        return await _handleRefreshRejection(
          e.response,
          epochAtStart: epochAtStart,
        );
      }
      _suspendRefreshIfRateLimited(e.response);
      return RefreshTransientFailure(
        errorType: e.type,
        response: e.response,
        error: e.error ?? e,
      );
    } catch (e) {
      authDebugLog('Unexpected error on refresh', error: e);
      return RefreshTransientFailure(
        errorType: DioExceptionType.unknown,
        error: e,
      );
    }
  }

  /// Decide se a falha do refresh encerra a sessão.
  ///
  /// A API responde 401 (`auth.invalid.token`) para refresh token inválido,
  /// revogado, expirado ou API key inativa. 400/403 sem código de credencial
  /// (gateway "Invalid Host Header", WAF) e falhas de rede são transitórios:
  /// mantêm a sessão para a próxima tentativa.
  Future<RefreshResult> _handleRefreshRejection(
    Response<dynamic>? response, {
    required int epochAtStart,
  }) async {
    if (response?.statusCode == 401) {
      // Refresh token recusado: preserva API key para facilitar re-login.
      return await _storageLock.synchronized(() async {
        if (_sessionEpoch != epochAtStart) {
          return const RefreshSessionExpired();
        }
        debugPrint(
          '[AuthDebug] Refresh token rejected. Clearing session only.',
        );
        try {
          await _storage.clearSession();
        } finally {
          _authNotifier.setState(AuthRouteState.needsSetup);
        }
        return const RefreshSessionExpired();
      });
    } else if (ApiAuthError.isCredentialRejected(response)) {
      if (_sessionEpoch != epochAtStart) {
        return const RefreshSessionExpired();
      }
      debugPrint('[AuthDebug] Credential rejected on refresh. Logging out...');
      await forceLogout();
      return const RefreshSessionExpired();
    } else {
      debugPrint(
        '[AuthDebug] Transient refresh failure (${response?.statusCode}). Keeping session.',
      );
      _suspendRefreshIfRateLimited(response);
      return RefreshTransientFailure(
        errorType: DioExceptionType.badResponse,
        response: response,
      );
    }
  }

  /// Após `429` no refresh, não tenta de novo antes do `Retry-After`
  /// (segundos; fallback [refreshRetryAfterFallback] se ausente/inválido).
  /// Sem isso o refresh proativo prolonga o bloqueio de todo o IP.
  void _suspendRefreshIfRateLimited(Response<dynamic>? response) {
    if (response?.statusCode != 429) {
      return;
    }
    final wait = _parseRetryAfter(response!.headers.value('retry-after'));
    _refreshBlockedUntil = _now().add(wait);
    _refreshRateLimitResponse = response;
    debugPrint(
      '[AuthDebug] Refresh rate limited (429). Next attempt after ${wait.inSeconds}s.',
    );
  }

  static Duration _parseRetryAfter(String? raw) {
    final seconds = int.tryParse(raw?.trim() ?? '');
    if (seconds == null || seconds < 0) {
      return refreshRetryAfterFallback;
    }
    final wait = Duration(seconds: seconds);
    return wait > refreshRetryAfterMax ? refreshRetryAfterMax : wait;
  }

  /// Revokes token on backend and clears local storage.
  Future<void> logout() async {
    debugPrint('[AuthDebug] Starting logout flow...');
    _sessionEpoch++;
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await _dio
            .post<dynamic>(
              '/api/auth/revoke',
              data: {'refreshToken': refreshToken},
              options: Options(
                extra: {'silent': true},
                sendTimeout: const Duration(seconds: 3),
                receiveTimeout: const Duration(seconds: 3),
              ),
            )
            .timeout(const Duration(seconds: 3));
        debugPrint('[AuthDebug] Token revoked on backend.');
      }
    } catch (e) {
      debugPrint('[AuthDebug] Revoke on backend failed (silent): $e');
      // Network logout failed, but proceeding with local cleanup
    } finally {
      await _clearProvisioningAndResetState();
    }
  }

  /// Clears local provisioning immediately without calling the backend.
  Future<void> forceLogout() async {
    debugPrint('[AuthDebug] Starting forceLogout flow...');
    _sessionEpoch++;
    await _clearProvisioningAndResetState();
  }

  Future<void> _clearProvisioningAndResetState() async {
    await _storageLock.synchronized(() async {
      try {
        debugPrint('[AuthDebug] Clearing local secure storage.');
        await _storage.clearProvisioning();
      } catch (e) {
        debugPrint('[AuthDebug] Failed clearing local secure storage: $e');
      } finally {
        _authNotifier.setState(AuthRouteState.needsSetup);
      }
    });
  }

  Future<AuthRouteState> initializeAuthState() async {
    try {
      final alreadyHasSession = await hasSession;
      if (alreadyHasSession) {
        _authNotifier.setState(AuthRouteState.authenticated);
        return AuthRouteState.authenticated;
      }

      final hasStoredApiKey = await hasApiKey;
      if (!hasStoredApiKey) {
        if (kDebugMode) {
          try {
            final devApiKey = Config.devApiKey;
            if (devApiKey.isNotEmpty) {
              await authenticate(devApiKey);
              _authNotifier.setState(AuthRouteState.authenticated);
              return AuthRouteState.authenticated;
            }
          } catch (_) {
            // If DEV key fails or env is unavailable, keep setup flow.
          }
        }

        _authNotifier.setState(AuthRouteState.needsSetup);
        return AuthRouteState.needsSetup;
      }

      final result = await restoreSessionFromStoredApiKey();
      switch (result) {
        case SessionRestoreResult.restored:
          final stillHasApiKey = await hasApiKey;
          final hasValidSessionAfterRestore = await hasSession;
          if (stillHasApiKey && hasValidSessionAfterRestore) {
            _authNotifier.setState(AuthRouteState.authenticated);
            return AuthRouteState.authenticated;
          }
          _authNotifier.setState(AuthRouteState.needsSetup);
          return AuthRouteState.needsSetup;
        case SessionRestoreResult.invalidCredentials:
        case SessionRestoreResult.noApiKey:
          _authNotifier.setState(AuthRouteState.needsSetup);
          return AuthRouteState.needsSetup;
        case SessionRestoreResult.transientError:
          _authNotifier.setState(AuthRouteState.offline);
          return AuthRouteState.offline;
      }
    } catch (e) {
      debugPrint('[AuthDebug] Bootstrap/storage error: $e');
      _authNotifier.setState(AuthRouteState.storageError);
      return AuthRouteState.storageError;
    }
  }
}
