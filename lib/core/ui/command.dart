import 'package:flutter/foundation.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/core/state/safe_change_notifier_mixin.dart';

/// Uma ação assíncrona de tela com flag própria ([running]) e último
/// [result], no lugar do esqueleto "guarda, flag, notify, try/finally".
///
/// Uma segunda chamada enquanto [running] é ignorada (retorna `null`).
class Command<A, T> extends ChangeNotifier with SafeChangeNotifierMixin {
  Command(this._action);

  final Future<Result<T>> Function(A argument) _action;

  bool _running = false;
  Result<T>? _result;

  bool get running => _running;

  /// Resultado da última execução concluída; `null` antes dela e enquanto
  /// uma nova execução está em andamento.
  Result<T>? get result => _result;

  /// Falha da última execução, ou `null` se ela teve sucesso ou não terminou.
  AppFailure? get error => switch (_result) {
    Err(:final failure) => failure,
    _ => null,
  };

  /// Executa a ação e devolve o resultado, ou `null` se já estava rodando.
  Future<Result<T>?> execute(A argument) async {
    if (_running) return null;
    _running = true;
    _result = null;
    notifyListeners();
    try {
      return _result = await _action(argument);
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}
