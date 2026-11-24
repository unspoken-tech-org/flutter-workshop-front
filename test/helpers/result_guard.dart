import 'dart:async';

import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';

/// Converte um callback de teste que retorna o valor ou lança em [Result]:
/// [RequisitionException] vira [ValidationFailure] (mantendo mensagem e
/// código) e qualquer outra exceção vira [UnexpectedFailure].
Future<Result<T>> guardResult<T>(FutureOr<T> Function() body) async {
  try {
    return Ok(await body());
  } on RequisitionException catch (e) {
    return Err(
      ValidationFailure(message: e.message, code: e.code, statusCode: 400),
    );
  } catch (e) {
    return Err(UnexpectedFailure(cause: e));
  }
}
