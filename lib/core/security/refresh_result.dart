import 'package:dio/dio.dart';

sealed class RefreshResult {
  const RefreshResult();
}

final class RefreshSuccess extends RefreshResult {
  final String accessToken;

  const RefreshSuccess(this.accessToken);
}

final class RefreshSessionExpired extends RefreshResult {
  const RefreshSessionExpired();
}

final class RefreshTransientFailure extends RefreshResult {
  final DioExceptionType errorType;
  final Response<dynamic>? response;
  final Object? error;

  const RefreshTransientFailure({
    required this.errorType,
    this.response,
    this.error,
  });
}

/// `DioException.error` de uma requisição cujo refresh falhou de forma
/// transitória com uma resposta 4xx (ex.: `400` do gateway). A resposta do
/// refresh não é repassada: ela viraria uma `ValidationFailure` da requisição
/// original. A sessão continua; o `GlobalErrorInterceptor` mostra
/// [message] e o `ApiClient` classifica como `NetworkFailure`.
final class SessionRefreshUnavailable implements Exception {
  const SessionRefreshUnavailable({this.statusCode});

  /// Status da resposta do refresh, só para log.
  final int? statusCode;

  static const message =
      'Não foi possível renovar a sessão agora. Tente novamente.';

  @override
  String toString() => 'SessionRefreshUnavailable(status: $statusCode)';
}
