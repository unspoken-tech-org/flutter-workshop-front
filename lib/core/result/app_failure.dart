/// Falha de uma chamada à API, já classificada.
///
/// O corpo de erro da API continua sendo `{ "error": { "code", "message" } }`;
/// as falhas que a API rejeitou com esse corpo ([RejectedFailure]) carregam a
/// mensagem e o código dele. As demais não têm texto próprio para o usuário:
/// o chamador informa o texto de fallback com [AppFailureMessage.messageOr].
sealed class AppFailure {
  const AppFailure();

  /// O `GlobalErrorInterceptor` já mostrou esta falha ao usuário (rede,
  /// timeout, `429`, `5xx`); o controller não publica outra mensagem por cima.
  bool get shownGlobally => false;
}

/// Sem resposta do servidor: timeout, conexão recusada ou sem internet.
final class NetworkFailure extends AppFailure {
  const NetworkFailure({this.cause, this.shownGlobally = false});

  final Object? cause;
  @override
  final bool shownGlobally;
}

/// `401` ou `403`. Quem trata sessão (logout/refresh) é o
/// `SecurityInterceptor`; um `403` pode ser também de papel ou WAF, sem
/// derrubar a sessão.
final class SessionFailure extends AppFailure {
  const SessionFailure({required this.statusCode, this.code});

  final int statusCode;
  final String? code;
}

/// `429`. [retryAfter] vem do header `Retry-After`, quando presente.
final class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure({
    this.message,
    this.retryAfter,
    this.shownGlobally = false,
  });

  final String? message;
  final Duration? retryAfter;
  @override
  final bool shownGlobally;
}

/// A API recusou a requisição com um corpo de erro (4xx, exceto sessão e
/// `429`). Leva a mensagem e o código que antes chegavam ao usuário via
/// `RequisitionException`.
sealed class RejectedFailure extends AppFailure {
  const RejectedFailure({
    required this.message,
    required this.code,
    required this.statusCode,
  });

  final String message;
  final String code;
  final int statusCode;
}

/// `400`, `422` e demais 4xx de validação/regra de negócio.
final class ValidationFailure extends RejectedFailure {
  const ValidationFailure({
    required super.message,
    required super.code,
    required super.statusCode,
  });
}

/// `404`.
final class NotFoundFailure extends RejectedFailure {
  const NotFoundFailure({
    required super.message,
    required super.code,
    required super.statusCode,
  });
}

/// `409`.
final class ConflictFailure extends RejectedFailure {
  const ConflictFailure({
    required super.message,
    required super.code,
    required super.statusCode,
  });
}

/// `5xx`.
final class ServerFailure extends AppFailure {
  const ServerFailure({
    required this.statusCode,
    this.message,
    this.shownGlobally = false,
  });

  final int statusCode;
  final String? message;
  @override
  final bool shownGlobally;
}

/// Status 2xx diferente do esperado, resposta que não decodifica
/// (corpo fora do formato), cancelamento ou erro inesperado.
final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({this.message, this.cause});

  final String? message;
  final Object? cause;
}

extension AppFailureMessage on AppFailure {
  /// A mensagem do backend quando a API recusou a requisição; senão,
  /// [fallback]. Mantém o texto que o usuário via com `RequisitionException`.
  String messageOr(String fallback) => switch (this) {
    RejectedFailure(:final message) => message,
    NetworkFailure() ||
    SessionFailure() ||
    RateLimitedFailure() ||
    ServerFailure() ||
    UnexpectedFailure() => fallback,
  };
}
