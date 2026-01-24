import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../core/exceptions/requisition_exception.dart';
import '../../core/config/config.dart';

import '../../core/http/custom_dio.dart';
import '../../core/security/auth_notifier.dart';
import '../../core/security/security_storage.dart';
import '../../models/auth/token_request.dart';
import '../../models/auth/token_response.dart';

class AuthService {
  final Dio _dio;
  final SecurityStorage _storage;

  AuthService({Dio? dio, SecurityStorage? storage})
      : _dio = dio ?? CustomDio.authDioInstance(),
        _storage = storage ?? SecurityStorage();

  Future<bool> get hasApiKey async => (await _storage.getApiKey()) != null;

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
        AuthNotifier().notifyAuthChange();
      } else if (response.statusCode == 409) {
        throw RequisitionException.fromJson(response.data['error']);
      }
    } on RequisitionException {
      rethrow;
    } catch (e) {
      debugPrint('[AuthDebug] Authenticate failed: $e');
      // If initial auth fails, ensure session is cleared but preserve boundDeviceId
      await _storage.clearSession();
      rethrow;
    }
  }

  /// Performs silent Access Token refresh.
  Future<String?> refreshToken() async {
    debugPrint('[AuthDebug] Starting refreshToken flow...');
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) {
      debugPrint('[AuthDebug] No refresh token found.');
      return null;
    }

    try {
      final response = await _dio.post(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      // RFC states refresh returns at least the new accessToken
      final newAccessToken = response.data['accessToken'] as String;
      debugPrint('[AuthDebug] Refresh successful. Saving new access token.');
      await _storage.saveAccessToken(newAccessToken);

      return newAccessToken;
    } on DioException catch (e) {
      debugPrint(
          '[AuthDebug] Refresh failed with status ${e.response?.statusCode}');
      // If 401 or 403 during refresh, session is invalid
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        debugPrint('[AuthDebug] Session invalid on refresh. Logging out...');
        await logout();
      }
      return null;
    } catch (e) {
      debugPrint('[AuthDebug] Unexpected error on refresh: $e');
      return null;
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
        );
        debugPrint('[AuthDebug] Token revoked on backend.');
      }
    } catch (e) {
      debugPrint('[AuthDebug] Revoke on backend failed (silent): $e');
      // Network logout failed, but proceeding with local cleanup
    } finally {
      debugPrint('[AuthDebug] Clearing local secure storage.');
      await _storage.clearSession();
      AuthNotifier().notifyAuthChange();
    }
  }
}
