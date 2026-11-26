import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_workshop_front/core/ui/ui_message.dart';

/// Global interceptor for network error handling. It publishes a [UiMessage]
/// through [onMessage]; whoever displays it is up to the UI layer.
class GlobalErrorInterceptor extends Interceptor {
  GlobalErrorInterceptor({required this.onMessage});

  final void Function(UiMessage message) onMessage;

  static const tooManyRequestsFallbackMessage =
      'Muitas requisições. Aguarde alguns instantes e tente novamente.';

  /// Mensagem do `ResponseError` (`{status, title, error: {code, message}}`)
  /// do `429`, com fallback fixo quando o corpo não é JSON da API.
  @visibleForTesting
  static String tooManyRequestsMessage(Response<dynamic>? response) {
    final data = response?.data;
    if (data is Map) {
      final error = data['error'];
      final message = error is Map ? error['message'] : null;
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
      final title = data['title'];
      if (title is String && title.trim().isNotEmpty) {
        return title;
      }
    }
    return tooManyRequestsFallbackMessage;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final extra = err.requestOptions.extra;
    debugPrint(
      '[GlobalError] ${err.requestOptions.method} ${err.requestOptions.path} '
      'status=${err.response?.statusCode} type=${err.type} '
      'requestId=${extra['requestId']} isAuthRetry=${extra['isAuthRetry']} '
      'authRetryCount=${extra['authRetryCount']} '
      'duplicateHash=${extra['duplicateRequestHash']} '
      'bypassDuplicate=${extra['bypassDuplicateCheck']}',
    );

    // 1. Ignore cancellations (usually triggered by us during logout)
    if (err.type == DioExceptionType.cancel) {
      return handler.next(err);
    }

    // 2. If auth error (401/403), SecurityInterceptor handled the logout.
    // Suppress generic UI errors during transition.
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      debugPrint(
        '[GlobalError] Auth error handled. Suppressing UI error during redirect.',
      );
      return handler.next(err);
    }

    // 3. Error Filtering: Only infrastructure, rate limit (429) and Server Errors (5xx) trigger global UI.
    // Client Errors (4xx) are passed to the Controller for business logic handling.
    bool shouldShowGlobalError = false;
    String errorMessage = 'Ocorreu um erro inesperado de conexão.';

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      errorMessage = 'Tempo de conexão esgotado. Verifique sua internet.';
      shouldShowGlobalError = true;
    } else if (err.type == DioExceptionType.connectionError) {
      errorMessage = 'Não foi possível conectar ao servidor.';
      shouldShowGlobalError = true;
    } else if (err.response?.statusCode == 429) {
      errorMessage = tooManyRequestsMessage(err.response);
      shouldShowGlobalError = true;
    } else if (err.response != null && (err.response!.statusCode ?? 0) >= 500) {
      errorMessage = 'Erro interno do servidor. Tente novamente mais tarde.';
      shouldShowGlobalError = true;
    }

    // Show global error if infrastructure-related and not silenced
    if (shouldShowGlobalError && err.requestOptions.extra['silent'] != true) {
      onMessage(UiError(errorMessage));
    }

    handler.next(err);
  }
}
