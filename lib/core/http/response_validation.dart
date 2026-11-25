import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';

/// Extrai o código de erro da resposta da API, aceitando tanto o formato
/// legado (`{ "error": { "code": "..." } }`) quanto RFC 9457 `ProblemDetail`
/// (`{ "code": "..." }`).
String? apiErrorCodeFromResponse(Response<dynamic>? response) {
  final data = response?.data;
  if (data is! Map) return null;
  final error = data['error'];
  final raw = (error is Map ? error['code'] : null) ?? data['code'];
  if (raw == null) return null;
  final code = raw.toString();
  return code.isNotEmpty ? code : null;
}

String? _nonEmptyString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

/// Converte uma resposta de erro da API em [RequisitionException], aceitando:
/// - formato legado: `{ "error": { "code": "...", "message": "..." } }`
/// - RFC 9457 `ProblemDetail`: `{ "type", "title", "status", "detail", "code" }`
///
/// Tolera corpo que não é um Map. Usada pelo `ApiClient` e pelo `AuthService`.
RequisitionException requisitionExceptionFromResponse(
  Response<dynamic> response,
) {
  final status = response.statusCode ?? 0;
  final data = response.data;
  final error = data is Map ? data['error'] : null;

  final message =
      _nonEmptyString(error is Map ? error['message'] : null) ??
      _nonEmptyString(data is Map ? data['detail'] : null) ??
      _nonEmptyString(data is Map ? data['title'] : null);
  final code = apiErrorCodeFromResponse(response) ?? '$status';

  return RequisitionException(
    message ?? 'Erro na requisição (status $status). Tente novamente.',
    code,
  );
}
