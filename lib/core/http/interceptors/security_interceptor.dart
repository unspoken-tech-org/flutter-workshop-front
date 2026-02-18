import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../security/auth_notifier.dart';
import '../../security/security_storage.dart';

class SecurityInterceptor extends QueuedInterceptor {
  static const _kAuthRetryCount = 'authRetryCount';
  static const _kIsAuthRetry = 'isAuthRetry';
  static const _kRequestId = 'requestId';

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
    options.extra[_kRequestId] ??= _buildRequestId(options);
    final requestId = options.extra[_kRequestId];

    final token = await _storage.getAccessToken();
    if (token != null) {
      debugPrint(
        '[AuthDebug][$requestId] Injecting token into ${options.path}',
      );
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    options.extra[_kRequestId] ??= _buildRequestId(options);
    final requestId = options.extra[_kRequestId];

    debugPrint(
      '[AuthDebug][$requestId] Error ${err.response?.statusCode} on ${err.requestOptions.path}',
    );

    if (err.response?.statusCode == 401) {
      final retryCount = (options.extra[_kAuthRetryCount] as int?) ?? 0;

      if (retryCount >= 1) {
        debugPrint('[AuthDebug][$requestId] Retry limit reached.');
        return handler.next(err);
      }

      // If error occurred during refresh, do not retry to avoid loop
      if (options.path.contains('/api/auth/refresh')) {
        debugPrint(
          '[AuthDebug][$requestId] Refresh token failed (401). Aborting retry.',
        );
        return handler.next(err);
      }

      // Deduplication Logic: Check if token already changed in storage
      final requestedToken = options.headers['Authorization'];
      final currentToken = await _storage.getAccessToken();

      String? tokenToUse = currentToken;

      // If the request token is the same as the current storage token, nobody refreshed yet
      if (currentToken == null || requestedToken == 'Bearer $currentToken') {
        try {
          debugPrint(
            '[AuthDebug][$requestId] Access token expired. Attempting refresh...',
          );
          tokenToUse = await _onRefresh();
        } catch (e) {
          debugPrint('[AuthDebug][$requestId] Refresh failed: $e');
          // Reject with cancellation to silence subsequent UI errors during redirect
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: 'Sessão expirada',
            ),
          );
        }
      } else {
        debugPrint(
          '[AuthDebug][$requestId] Token already refreshed by another request. Reusing...',
        );
      }

      if (tokenToUse != null) {
        debugPrint(
          '[AuthDebug][$requestId] Retry ready. Retrying original request to ${options.path}',
        );
        options.headers['Authorization'] = 'Bearer $tokenToUse';
        options.extra[_kIsAuthRetry] = true;
        options.extra[_kAuthRetryCount] = retryCount + 1;

        // Retry original request with new token
        try {
          final response = await _dio.fetch(options);

          // RESOLVE with the retry response. This silences the original error for the caller.
          return handler.resolve(response);
        } on DioException catch (retryError) {
          debugPrint('[AuthDebug][$requestId] Retry failed: $retryError');
          return handler.next(retryError);
        } catch (retryError) {
          debugPrint('[AuthDebug][$requestId] Retry failed: $retryError');
          return handler.next(err);
        }
      } else {
        debugPrint(
            '[AuthDebug][$requestId] Refresh returned null. Cannot retry.');
      }
    } else if (err.response?.statusCode == 403) {
      // Forbidden: Invalid API Key or blocked user
      debugPrint(
        '[AuthDebug][$requestId] 403 Forbidden detected. Clearing session (Forced Logout).',
      );
      await _storage.clearSession();
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

  String _buildRequestId(RequestOptions options) {
    final now = DateTime.now().microsecondsSinceEpoch;
    return '$now-${options.method}-${options.path.hashCode}';
  }
}
