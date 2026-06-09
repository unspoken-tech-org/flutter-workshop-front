import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:synchronized/synchronized.dart';
import '../../security/auth_notifier.dart';
import '../../security/security_storage.dart';

class SecurityInterceptor extends Interceptor {
  static const _kRequestId = 'requestId';

  /// Buffer de 60s: renova o token proativamente se expira em menos de 1 minuto.
  static const _kExpiryBuffer = Duration(seconds: 60);

  final SecurityStorage _storage;

  /// Dio sem SecurityInterceptor — evita deadlock no retry.
  final Dio _retryDio;

  final Future<String?> Function() _onRefresh;
  final AuthNotifier _authNotifier;

  /// Garante que apenas um refresh ocorre por vez entre requests concorrentes.
  final Lock _lock = Lock();

  SecurityInterceptor({
    required SecurityStorage storage,
    required Dio retryDio,
    required Future<String?> Function() onRefresh,
    required AuthNotifier authNotifier,
  }) : _storage = storage,
       _retryDio = retryDio,
       _onRefresh = onRefresh,
       _authNotifier = authNotifier;

  // ── onRequest: verificação PROATIVA ──────────────────────────────────────

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
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
      final newToken = await _refreshUnderLock(requestId, knownToken: token);
      if (newToken == null) {
        debugPrint(
          '[AuthDebug][$requestId] Proactive refresh failed. Aborting request.',
        );
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: 'Sessão expirada',
          ),
        );
      }
      options.headers['Authorization'] = 'Bearer $newToken';
    } else if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    debugPrint('[AuthDebug][$requestId] Injecting token into ${options.path}');
    handler.next(options);
  }

  // ── onError: verificação REATIVA (fallback para 401 inesperado) ───────────

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
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

      final newToken = await _refreshUnderLock(
        requestId,
        knownToken: sentToken,
      );
      if (newToken == null) {
        debugPrint(
          '[AuthDebug][$requestId] Refresh returned null. Cannot retry.',
        );
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: 'Sessão expirada',
          ),
        );
      }

      debugPrint('[AuthDebug][$requestId] Retrying with new token...');
      final retryOptions = options.copyWith(
        headers: {...options.headers, 'Authorization': 'Bearer $newToken'},
      );

      try {
        // _retryDio NÃO tem SecurityInterceptor: sem deadlock de fila.
        final response = await _retryDio.fetch(retryOptions);
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        debugPrint('[AuthDebug][$requestId] Retry failed: $retryErr');
        return handler.next(retryErr);
      }
    } else if (err.response?.statusCode == 403) {
      // API Key inválida ou usuário bloqueado: logout forçado.
      debugPrint(
        '[AuthDebug][$requestId] 403 Forbidden detected. Clearing provisioning (Forced Logout).',
      );
      await _storage.clearProvisioning();
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
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  /// Executa o refresh sob lock, garantindo apenas 1 chamada ao backend por vez.
  ///
  /// Usa [knownToken] como referência: o token que este request conhecia
  /// antes de tentar adquirir o lock (lido do storage ou do header da request).
  ///
  /// Se após adquirir o lock o token no storage for diferente de [knownToken],
  /// outro request já realizou o refresh → retorna o token atual sem chamar o backend.
  Future<String?> _refreshUnderLock(String requestId, {String? knownToken}) {
    return _lock.synchronized(() async {
      final currentToken = await _storage.getAccessToken();

      // Guard: se o token no storage mudou desde que este request leu,
      // outro request concorrente já fez o refresh — reutiliza.
      if (knownToken != null &&
          currentToken != null &&
          currentToken != knownToken) {
        debugPrint(
          '[AuthDebug][$requestId] Token already refreshed by another request. Reusing...',
        );
        return currentToken;
      }

      debugPrint(
        '[AuthDebug][$requestId] Access token expired. Attempting refresh...',
      );
      try {
        return await _onRefresh().timeout(const Duration(seconds: 10));
      } on TimeoutException catch (_) {
        debugPrint('[AuthDebug][$requestId] Refresh timed out after 10s.');
        return null;
      } catch (e) {
        debugPrint('[AuthDebug][$requestId] Refresh threw: $e');
        return null;
      }
    });
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
