import 'package:flutter_workshop_front/core/result/app_failure.dart';

/// Resultado de uma operação que pode falhar sem lançar exceção.
///
/// Consuma com `switch` exaustivo:
///
/// ```dart
/// switch (await service.load()) {
///   case Ok(:final value):
///     ...
///   case Err(:final failure):
///     emitError(failure.messageOr('Erro ao carregar'));
/// }
/// ```
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// O valor em caso de sucesso; `null` em caso de falha.
  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// Transforma o valor de sucesso e preserva a falha.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Err(:final failure) => Err(failure),
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final AppFailure failure;
}
