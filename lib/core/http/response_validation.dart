import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';

/// O `validateStatus` do [CustomDio] entrega respostas 4xx (exceto 401/403)
/// como sucesso. Esta extensão centraliza a regra que transforma essas
/// respostas em [RequisitionException], para os controllers exibirem a
/// mensagem do backend em vez de tratar o erro como sucesso.
extension ResponseValidation<T> on Response<T> {
  Response<T> ensureSuccess() {
    final status = statusCode ?? 0;
    if (status >= 200 && status < 300) {
      return this;
    }

    throw requisitionExceptionFromResponse(this);
  }
}

RequisitionException requisitionExceptionFromResponse(Response response) {
  final status = response.statusCode ?? 0;
  final data = response.data;
  final error = data is Map ? data['error'] : null;

  final message = error is Map ? error['message'] : null;
  final code = error is Map ? error['code'] : null;

  return RequisitionException(
    message is String && message.isNotEmpty
        ? message
        : 'Erro na requisição (status $status). Tente novamente.',
    code?.toString() ?? '$status',
  );
}
