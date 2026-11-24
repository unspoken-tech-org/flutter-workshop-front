import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_workshop_front/core/http/interceptors/global_error_interceptor.dart';
import 'package:flutter_workshop_front/core/http/interceptors/security_interceptor.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/core/security/refresh_result.dart';
import 'package:flutter_workshop_front/core/security/security_storage.dart';

/// Fábrica das instâncias de [Dio] da API, sem estado global.
///
/// O `AppDependencies` cria uma de cada no boot: [createAuthDio] para o
/// `AuthService` e [createAppDio] (com [SecurityInterceptor]) para o
/// `ApiClient`. Por não haver ordem de setup, o `GlobalErrorInterceptor`
/// está presente nas duas desde a criação.
class CustomDio {
  CustomDio({
    required this.baseUri,
    @visibleForTesting HttpClientAdapter? adapter,
  }) : _adapter = adapter;

  final Uri baseUri;
  final HttpClientAdapter? _adapter;

  /// Instância dedicada à autenticação, sem [SecurityInterceptor] (evita loop
  /// de refresh).
  Dio createAuthDio() => _baseDio()..interceptors.add(GlobalErrorInterceptor());

  /// Instância das chamadas autenticadas: injeta o token, renova em 401 e
  /// repete a requisição por um `retryDio` sem [SecurityInterceptor].
  Dio createAppDio({
    required SecurityStorage storage,
    required Future<RefreshResult> Function() onRefresh,
    required AuthNotifier authNotifier,
    Future<void> Function()? onCredentialRejected,
  }) {
    // retryDio: mesmas BaseOptions, sem SecurityInterceptor → sem deadlock no retry.
    final retryDio = _baseDio()..interceptors.add(GlobalErrorInterceptor());

    return _baseDio()
      ..interceptors.addAll([
        SecurityInterceptor(
          storage: storage,
          retryDio: retryDio,
          onRefresh: onRefresh,
          authNotifier: authNotifier,
          onCredentialRejected: onCredentialRejected,
        ),
        // GlobalErrorInterceptor por último: processa o erro final.
        GlobalErrorInterceptor(),
      ]);
  }

  Dio _baseDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUri.toString(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        // 401/403/429 viram DioException: Security/GlobalErrorInterceptor
        // tratam sessão e rate limit em vez de o chamador ver "sucesso".
        validateStatus: (status) {
          return status! < 500 &&
              status != 401 &&
              status != 403 &&
              status != 429;
        },
      ),
    );
    final adapter = _adapter;
    if (adapter != null) dio.httpClientAdapter = adapter;
    return dio;
  }
}
