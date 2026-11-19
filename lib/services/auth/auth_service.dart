import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../core/exceptions/requisition_exception.dart';
import '../../core/config/config.dart';

import '../../core/http/api_auth_error.dart';
import '../../core/http/custom_dio.dart';
import '../../core/http/response_validation.dart';
import '../../core/security/auth_notifier.dart';
import '../../core/security/refresh_result.dart';
import '../../core/security/security_storage.dart';
import '../../models/auth/token_request.dart';
import '../../models/auth/token_response.dart';

class AuthService {
  final Dio _dio;
  final SecurityStorage _storage;
  final AuthNotifier _authNotifier;

  AuthService({
    Dio? dio,
    SecurityStorage? storage,
    required AuthNotifier authNotifier,
  }) : _authNotifier = authNotifier,
       _dio = dio ?? CustomDio.authDioInstance(),
       _storage = storage ?? SecurityStorage();

  Future<String?> get apiKey async => (await _storage.getApiKey());
  Future<bool> get hasApiKey async => (await apiKey) != null;

  Future<bool> get hasSession async {
    final accessToken = await _storage.getAccessToken();
    final refreshToken = await _storage.getRefreshToken();
    return (accessToken != null && accessToken.isNotEmpty) ||
        (refreshToken != null && refreshToken.isNotEmpty);
  }

  /// RBAC: Checks if user has ADMIN role by decoding the current JWT.
  Future<bool> get isAdmin async {
    final token = await _storage.getAccessToken();
    if (token == null || JwtDecoder.isExpired(token)) {
      debugPrint('[AuthDebug] Token null or expired. isAdmin: false');
      return false;
    }

    final decodedToken = JwtDecoder.decode(token);
    final List<dynamic> roles = decodedToken['roles'] ?? [];
    final isAdmin = roles.contains('ADMIN');
    debugPrint('[AuthDebug] Decoded roles: $roles. isAdmin: $isAdmin');
    return isAdmin;
  }

  /// Performs initial authentication exchanging API Key for JWT tokens.
  Future<void> authenticate(String apiKey) async {
    try {
      final boundDeviceId = await _storage.getBoundDeviceId();
      final appVersion = await Config.appVersion;

      final response = await _dio.post(
        '/api/auth/token',
        options: Options(headers: {'X-API-Key': apiKey}),
        data: TokenRequest(
          boundDeviceId: boundDeviceId,
          appVersion: appVersion,
        ).toJson(),
      );

      if (response.statusCode == 200) {
        final tokenResponse = TokenResponse.fromJson(response.data);

        debugPrint('[AuthDebug] Authenticate successful. Saving tokens...');
        // Save API Key only if authentication succeeds
        await _storage.saveApiKey(apiKey);
        await _storage.saveTokens(
          tokenResponse.accessToken,
          tokenResponse.refreshToken,
        );
        _authNotifier.setState(AuthRouteState.authenticated);
      } else {
        // 409 (conflito de dispositivo) e demais 4xx entregues pelo
        // validateStatus: o setup não pode marcar sucesso.
        throw requisitionExceptionFromResponse(response);
      }
    } on DioException catch (e) {
      debugPrint(
        '[AuthDebug] Authenticate failed with status ${e.response?.statusCode}: $e',
      );
      if (e.response?.statusCode == 401) {
        await _storage.clearProvisioning();
        _authNotifier.setState(AuthRouteState.needsSetup);
      } else {
        await _storage.clearSession();
      }
      rethrow;
    } on RequisitionException {
      rethrow;
    } catch (e) {
      debugPrint('[AuthDebug] Authenticate failed: $e');
      // If initial auth fails, ensure session is cleared but preserve boundDeviceId
      await _storage.clearSession();
      _authNotifier.setState(AuthRouteState.needsSetup);
      rethrow;
    }
  }

  Future<bool> restoreSessionFromStoredApiKey() async {
    final apiKey = await _storage.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return false;
    }

    if (await hasSession) {
      return true;
    }

    try {
      await authenticate(apiKey);
      return true;
    } on DioException {
      return false;
    } on RequisitionException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Performs silent Access Token refresh.
  Future<RefreshResult> refreshToken() async {
    debugPrint('[AuthDebug] Starting refreshToken flow...');
    final String? currentRefreshToken;
    try {
      currentRefreshToken = await _storage.getRefreshToken();
    } catch (e) {
      debugPrint('[AuthDebug] Failed reading refresh token: $e');
      return RefreshTransientFailure(
        errorType: DioExceptionType.unknown,
        error: e,
      );
    }

    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      debugPrint('[AuthDebug] No refresh token found.');
      return const RefreshSessionExpired();
    }

    try {
      final response = await _dio.post(
        '/api/auth/refresh',
        data: {'refreshToken': currentRefreshToken},
        options: Options(extra: {'silent': true}),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode != 200 && statusCode != 201) {
        debugPrint('[AuthDebug] Unexpected refresh status: $statusCode');
        return await _handleRefreshRejection(response);
      }

      if (response.data is! Map<String, dynamic>) {
        debugPrint('[AuthDebug] Invalid refresh payload format.');
        await logout();
        return const RefreshSessionExpired();
      }

      final payload = response.data as Map<String, dynamic>;
      final newAccessToken = payload['accessToken'] as String?;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        debugPrint('[AuthDebug] Invalid refresh payload: missing accessToken.');
        await logout();
        return const RefreshSessionExpired();
      }

      final newRefreshToken = payload['refreshToken'] as String?;

      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        debugPrint(
          '[AuthDebug] Refresh successful. Rotating access and refresh tokens.',
        );
        await _storage.saveTokens(newAccessToken, newRefreshToken);
      } else {
        debugPrint('[AuthDebug] Refresh successful. Saving new access token.');
        await _storage.saveAccessToken(newAccessToken);
      }

      return RefreshSuccess(newAccessToken);
    } on DioException catch (e) {
      debugPrint(
        '[AuthDebug] Refresh failed with status ${e.response?.statusCode}',
      );
      if (e.response?.statusCode == 401 ||
          ApiAuthError.isCredentialRejected(e.response)) {
        return await _handleRefreshRejection(e.response);
      }
      return RefreshTransientFailure(
        errorType: e.type,
        response: e.response,
        error: e.error ?? e,
      );
    } catch (e) {
      debugPrint('[AuthDebug] Unexpected error on refresh: $e');
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
    Response<dynamic>? response,
  ) async {
    if (response?.statusCode == 401) {
      // Refresh token recusado: preserva API key para facilitar re-login.
      debugPrint('[AuthDebug] Refresh token rejected. Clearing session only.');
      await _storage.clearSession();
      _authNotifier.setState(AuthRouteState.needsSetup);
      return const RefreshSessionExpired();
    } else if (ApiAuthError.isCredentialRejected(response)) {
      debugPrint('[AuthDebug] Credential rejected on refresh. Logging out...');
      await logout();
      return const RefreshSessionExpired();
    } else {
      debugPrint(
        '[AuthDebug] Transient refresh failure (${response?.statusCode}). Keeping session.',
      );
      return RefreshTransientFailure(
        errorType: DioExceptionType.badResponse,
        response: response,
      );
    }
  }

  /// Revokes token on backend and clears local storage.
  Future<void> logout() async {
    debugPrint('[AuthDebug] Starting logout flow...');
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await _dio.post(
          '/api/auth/revoke',
          data: {'refreshToken': refreshToken},
          options: Options(extra: {'silent': true}),
        );
        debugPrint('[AuthDebug] Token revoked on backend.');
      }
    } catch (e) {
      debugPrint('[AuthDebug] Revoke on backend failed (silent): $e');
      // Network logout failed, but proceeding with local cleanup
    } finally {
      debugPrint('[AuthDebug] Clearing local secure storage.');
      await _storage.clearProvisioning();
      _authNotifier.setState(AuthRouteState.needsSetup);
    }
  }

  Future<AuthRouteState> initializeAuthState() async {
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

    final restored = await restoreSessionFromStoredApiKey();
    final stillHasApiKey = await hasApiKey;
    final hasValidSessionAfterRestore = await hasSession;

    if (restored && stillHasApiKey && hasValidSessionAfterRestore) {
      _authNotifier.setState(AuthRouteState.authenticated);
      return AuthRouteState.authenticated;
    }

    _authNotifier.setState(AuthRouteState.needsSetup);
    return AuthRouteState.needsSetup;
  }
}
