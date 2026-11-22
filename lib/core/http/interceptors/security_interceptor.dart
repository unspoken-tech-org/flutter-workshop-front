import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:synchronized/synchronized.dart';
import '../../security/auth_debug_log.dart';
import '../../security/auth_notifier.dart';
import '../../security/refresh_result.dart';
import '../api_auth_error.dart';
import '../../security/security_storage.dart';

class SecurityInterceptor extends Interceptor {
  static const _kRequestId = 'requestId';

  /// Buffer de 60s: renova o token proativamente se expira em menos de 1 minuto.
  static const _kExpiryBuffer = Duration(seconds: 60);

  final SecurityStorage _storage;

  /// Dio sem SecurityInterceptor — evita deadlock no retry.
  final Dio _retryDio;

  final Future<RefreshResult> Function() _onRefresh;
  final AuthNotifier _authNotifier;
  final Future<void> Function()? _onCredentialRejected;

  /// Garante que apenas um refresh ocorre por vez entre requests concorrentes.
  final Lock _lock = Lock();

  SecurityInterceptor({
    required SecurityStorage storage,
    required Dio retryDio,
    required Future<RefreshResult> Function() onRefresh,
    required AuthNotifier authNotifier,
    Future<void> Function()? onCredentialRejected,
  }) : _storage = storage,
       _retryDio = retryDio,
       _onRefresh = onRefresh,
       _authNotifier = authNotifier,
       _onCredentialRejected = onCredentialRejected;

  // ── onRequest: verificação PROATIVA ──────────────────────────────────────

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      options.extra[_kRequestId] ??= _buildRequestId(options);
      final requestId = options.extra[_kRequestId] as String;

      // Endpoints de autenticação não precisam de token.
      if (_isAuthPath(options.path)) return handler.next(options);

      final token = await _storage.getAccessToken();

      if (token != null && _isExpiredOrExpiringSoon(token)) {
        debugPrint(
          '[AuthDebug][$requestId] Token expiring soon. Proactive refresh...',
        );
        // Passa o token lido antes do lock como referência:
        // se outro request já renovou, o valor no storage será diferente.
        final result = await _refreshUnderLock(requestId, knownToken: token);
        switch (result) {
          case RefreshSuccess(:final accessToken):
            options.headers['Authorization'] = 'Bearer $accessToken';
          case RefreshSessionExpired():
            debugPrint(
              '[AuthDebug][$requestId] Proactive refresh failed. Aborting request.',
            );
            return handler.reject(
              _buildRefreshFailureException(options, result),
            );
          case RefreshTransientFailure():
            debugPrint(
              '[AuthDebug][$requestId] Proactive refresh failed transiently. Forwarding error.',
            );
            return handler.reject(
              _buildRefreshFailureException(options, result),
              true,
            );
        }
      } else if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      debugPrint(
        '[AuthDebug][$requestId] Injecting token into ${options.path}',
      );
      handler.next(options);
    } catch (e, st) {
      debugPrint('[AuthDebug] Unexpected error in onRequest: $e');
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: e,
          stackTrace: st,
        ),
      );
    }
  }

  // ── onError: verificação REATIVA (fallback para 401 inesperado) ───────────

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    try {
      options.extra[_kRequestId] ??= _buildRequestId(options);
      final requestId = options.extra[_kRequestId] as String;

      debugPrint(
        '[AuthDebug][$requestId] Error ${err.response?.statusCode} on ${options.path}',
      );

      if (err.response?.statusCode == 401) {
        // Não tenta refresh em endpoints de autenticação (evita loop infinito).
        if (_isAuthPath(options.path)) {
          debugPrint('[AuthDebug][$requestId] 401 on auth path. No retry.');
          return handler.next(err);
        }

        // Extrai o token enviado na requisição original como referência para a guard.
        // Se outro request já trocou o token no storage, o valor será diferente → reusa.
        final authHeader = options.headers['Authorization'] as String?;
        final sentToken = authHeader?.startsWith('Bearer ') == true
            ? authHeader!.substring(7)
            : null;

        final result = await _refreshUnderLock(
          requestId,
          knownToken: sentToken,
        );
        final String newToken;
        switch (result) {
          case RefreshSuccess(:final accessToken):
            newToken = accessToken;
          case RefreshSessionExpired():
            debugPrint('[AuthDebug][$requestId] Refresh failed. Cannot retry.');
            return handler.reject(
              _buildRefreshFailureException(options, result),
            );
          case RefreshTransientFailure():
            debugPrint(
              '[AuthDebug][$requestId] Refresh failed transiently. Forwarding error.',
            );
            return handler.next(_buildRefreshFailureException(options, result));
        }

        debugPrint('[AuthDebug][$requestId] Retrying with new token...');
        final retryOptions = options.copyWith(
          headers: {...options.headers, 'Authorization': 'Bearer $newToken'},
        );

        try {
          // _retryDio NÃO tem SecurityInterceptor: sem deadlock de fila.
          final response = await _retryDio.fetch<dynamic>(retryOptions);
          return handler.resolve(response);
        } on DioException catch (retryErr) {
          authDebugLog('[AuthDebug][$requestId] Retry failed', error: retryErr);
          return handler.next(retryErr);
        } catch (retryErr, st) {
          authDebugLog(
            '[AuthDebug][$requestId] Retry failed unexpectedly',
            error: retryErr,
          );
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.unknown,
              error: retryErr,
              stackTrace: st,
            ),
          );
        }
      } else if (ApiAuthError.isCredentialRejected(err.response)) {
        // Só a API diz que a credencial foi revogada/é inválida: logout forçado.
        // 403 genérico (papel, WAF da Cloudflare) segue para o chamador.
        debugPrint(
          '[AuthDebug][$requestId] Credential rejected by API. Clearing provisioning (Forced Logout).',
        );
        try {
          if (_onCredentialRejected != null) {
            await _onCredentialRejected();
          }
        } catch (e) {
          authDebugLog(
            '[AuthDebug][$requestId] Failed clearing provisioning on forced logout',
            error: e,
          );
        }
        _authNotifier.setState(AuthRouteState.needsSetup);

        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            type: DioExceptionType.cancel,
            error: 'Sessão encerrada',
          ),
        );
      }

      handler.next(err);
    } catch (e, st) {
      authDebugLog('[AuthDebug] Unexpected error in onError', error: e);
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: e,
          stackTrace: st,
        ),
      );
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  /// Executa o refresh sob lock, garantindo apenas 1 chamada ao backend por vez.
  ///
  /// Usa [knownToken] como referência: o token que este request conhecia
  /// antes de tentar adquirir o lock (lido do storage ou do header da request).
  ///
  /// Se após adquirir o lock o token no storage for diferente de [knownToken],
  /// outro request já realizou o refresh → retorna o token atual sem chamar o backend.
  Future<RefreshResult> _refreshUnderLock(
    String requestId, {
    String? knownToken,
  }) {
    return _lock.synchronized(() async {
      final String? currentToken;
      try {
        currentToken = await _storage.getAccessToken();
      } catch (e) {
        debugPrint(
          '[AuthDebug][$requestId] Failed reading access token under lock: $e',
        );
        return RefreshTransientFailure(
          errorType: DioExceptionType.unknown,
          error: e,
        );
      }

      // Guard: se o token no storage mudou desde que este request leu,
      // outro request concorrente já fez o refresh — reutiliza.
      if (knownToken != null &&
          currentToken != null &&
          currentToken != knownToken) {
        debugPrint(
          '[AuthDebug][$requestId] Token already refreshed by another request. Reusing...',
        );
        return RefreshSuccess(currentToken);
      }

      debugPrint(
        '[AuthDebug][$requestId] Access token expired. Attempting refresh...',
      );
      try {
        return await _onRefresh().timeout(const Duration(seconds: 10));
      } on TimeoutException catch (e) {
        debugPrint('[AuthDebug][$requestId] Refresh timed out after 10s.');
        return RefreshTransientFailure(
          errorType: DioExceptionType.connectionTimeout,
          error: e,
        );
      } catch (e) {
        debugPrint('[AuthDebug][$requestId] Refresh threw: $e');
        return RefreshTransientFailure(
          errorType: DioExceptionType.unknown,
          error: e,
        );
      }
    });
  }

  DioException _buildRefreshFailureException(
    RequestOptions options,
    RefreshResult result,
  ) {
    return switch (result) {
      RefreshSessionExpired() => DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
        error: 'Sessão expirada',
      ),
      RefreshTransientFailure(
        :final errorType,
        :final response,
        :final error,
      ) =>
        DioException(
          requestOptions: options,
          type: errorType,
          response: response,
          error: error,
        ),
      RefreshSuccess() => throw StateError(
        'Unexpected RefreshSuccess when building failure exception',
      ),
    };
  }

  bool _isExpiredOrExpiringSoon(String token) {
    try {
      final exp = JwtDecoder.getExpirationDate(token);
      return DateTime.now().isAfter(exp.subtract(_kExpiryBuffer));
    } catch (_) {
      // Token malformado: tratar como expirado.
      return true;
    }
  }

  bool _isAuthPath(String path) =>
      path.contains('/api/auth/refresh') || path.contains('/api/auth/token');

  String _buildRequestId(RequestOptions options) {
    final now = DateTime.now().microsecondsSinceEpoch;
    return '$now-${options.method}-${options.path.hashCode}';
  }
}
