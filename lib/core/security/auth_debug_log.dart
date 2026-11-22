import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs auth diagnostics in debug builds only, redacting full [DioException]
/// payloads so headers, tokens, and request bodies are never dumped to console.
void authDebugLog(String message, {Object? requestId, Object? error}) {
  if (!kDebugMode) return;
  final prefix = requestId == null ? '[AuthDebug]' : '[AuthDebug][$requestId]';
  if (error == null) {
    debugPrint('$prefix $message');
    return;
  }
  final summary = switch (error) {
    DioException(:final type, :final response) =>
      'DioException(type=$type, status=${response?.statusCode})',
    _ => '${error.runtimeType}',
  };
  debugPrint('$prefix $message: $summary');
}
