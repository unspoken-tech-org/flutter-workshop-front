import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../security/auth_notifier.dart';
import '../../security/security_storage.dart';

class SecurityInterceptor extends QueuedInterceptor {
  final SecurityStorage _storage;
  final Dio _dio;
  final Future<String?> Function() _onRefresh;

  SecurityInterceptor({
    required SecurityStorage storage,
    required Dio dio,
    required Future<String?> Function() onRefresh,
  })  : _storage = storage,
        _dio = dio,
        _onRefresh = onRefresh;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      debugPrint('[AuthDebug] Injecting token into ${options.path}');
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint(
        '[AuthDebug] Error ${err.response?.statusCode} on ${err.requestOptions.path}');

    if (err.response?.statusCode == 401) {
      final options = err.requestOptions;

      // If error occurred during refresh, do not retry to avoid loop
      if (options.path.contains('/api/auth/refresh')) {
        debugPrint('[AuthDebug] Refresh token failed (401). Aborting retry.');
        return handler.next(err);
      }

      try {
        debugPrint('[AuthDebug] Access token expired. Attempting refresh...');

        final newToken = await _onRefresh();

        if (newToken != null) {
          debugPrint(
              '[AuthDebug] Refresh successful. Retrying original request.');
          options.headers['Authorization'] = 'Bearer $newToken';

          // Retry original request with new token
          final response = await _dio.fetch(options);
          return handler.resolve(response);
        } else {
          debugPrint('[AuthDebug] Refresh returned null. Cannot retry.');
        }
      } catch (e) {
        debugPrint('[AuthDebug] Exception during refresh flow: $e');
        return handler.next(err);
      }
    } else if (err.response?.statusCode == 403) {
      // Forbidden: Invalid API Key or blocked user
      debugPrint(
          '[AuthDebug] 403 Forbidden detected. Clearing storage (Forced Logout).');
      await _storage.clearAll();
      AuthNotifier().notifyAuthChange();

      // Reject with cancellation to silence subsequent UI errors during redirect
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          type: DioExceptionType.cancel,
          error: 'Sessão encerrada',
        ),
      );
    }
    handler.next(err);
  }
}
