import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

/// Global interceptor for network error handling and UI feedback.
class GlobalErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 1. Ignore cancellations (usually triggered by us during logout)
    if (err.type == DioExceptionType.cancel) {
      return handler.next(err);
    }

    // 2. If auth error (401/403), SecurityInterceptor handled the logout.
    // Suppress generic UI errors during transition.
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      debugPrint(
          '[GlobalError] Auth error handled. Suppressing UI error during redirect.');
      return handler.next(err);
    }

    // 3. Error Filtering: Only infrastructure and Server Errors (5xx) trigger global UI.
    // Client Errors (4xx) are passed to the Controller for business logic handling.
    bool shouldShowGlobalError = false;
    String errorMessage = 'Ocorreu um erro inesperado de conexão.';

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Tempo de conexão esgotado. Verifique sua internet.';
      shouldShowGlobalError = true;
    } else if (err.type == DioExceptionType.connectionError) {
      errorMessage = 'Não foi possível conectar ao servidor.';
      shouldShowGlobalError = true;
    } else if (err.response != null && (err.response!.statusCode ?? 0) >= 500) {
      errorMessage = 'Erro interno do servidor. Tente novamente mais tarde.';
      shouldShowGlobalError = true;
    }

    // Show global error if infrastructure-related and not silenced
    if (shouldShowGlobalError && err.requestOptions.extra['silent'] != true) {
      SnackBarUtil().showError(errorMessage);
    }

    handler.next(err);
  }
}
