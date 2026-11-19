import 'package:dio/dio.dart';

/// Contrato de erro de autenticação da API (`ResponseError`):
/// `{"status": ..., "error": {"code": "...", "message": "..."}}`.
///
/// A API sinaliza credencial revogada ou inválida com 401 e os códigos abaixo
/// (`GlobalExceptionHandler`). Já o 403 dela é sempre `auth.access.denied`
/// (falta de papel), e 403/400 sem esse corpo vêm do WAF ou do gateway.
/// Por isso o logout forçado depende do código, não só do status.
class ApiAuthError {
  static const invalidApiKey = 'auth.invalid.api.key';
  static const invalidToken = 'auth.invalid.token';

  static const _credentialRejectedCodes = {invalidApiKey, invalidToken};

  /// Código de erro da API, ou `null` se o corpo não seguir o contrato
  /// (HTML do WAF, texto do gateway, corpo vazio).
  static String? errorCode(Response<dynamic>? response) {
    final data = response?.data;
    if (data is! Map) return null;
    final error = data['error'];
    if (error is! Map) return null;
    final code = error['code'];
    return code is String ? code : null;
  }

  /// `true` só quando a API afirma que a API key ou o token foi recusado.
  static bool isCredentialRejected(Response<dynamic>? response) =>
      _credentialRejectedCodes.contains(errorCode(response));
}
