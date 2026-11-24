import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';

/// Converte uma resposta de erro da API (`{ "error": { code, message } }`)
/// em [RequisitionException], tolerando corpo que não é um Map.
///
/// Usada pelo `ApiClient` e pelo `AuthService`.
RequisitionException requisitionExceptionFromResponse(
  Response<dynamic> response,
) {
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
