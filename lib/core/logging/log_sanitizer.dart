import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Keeps secrets and customer data out of persisted logs.
///
/// Call sites should log events and codes, never payloads; this is a second
/// line of defense for free-form text such as exception messages.
abstract final class LogSanitizer {
  static const int maxErrorLength = 1000;

  static final List<(RegExp, String Function(Match))> _rules = [
    // Query strings may carry search terms (names, phones) or keys.
    (
      RegExp(r'(https?://[^\s?#]+)\?[^\s#]*'),
      (m) => '${m.group(1)}?[REDACTED]',
    ),
    (
      RegExp(r'bearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false),
      (_) => 'Bearer [REDACTED]',
    ),
    (
      RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*'),
      (_) => '[REDACTED_TOKEN]',
    ),
    (
      RegExp(
        r'''(authorization|x-api-key|api[-_]?key|refresh[-_]?token|access[-_]?token|token|password|senha)(["']?\s*[:=]\s*["']?)[^\s"',;&}\]]+''',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}${m.group(2)}[REDACTED]',
    ),
    (RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+'), (_) => '[REDACTED_EMAIL]'),
    (
      RegExp(r'(?<!\d)\d{3}\.?\d{3}\.?\d{3}-?\d{2}(?!\d)'),
      (_) => '[REDACTED_CPF]',
    ),
    (
      RegExp(r'(?<!\d)(\+?55\s?)?\(?\d{2}\)?[\s-]?9?\d{4}[\s-]?\d{4}(?!\d)'),
      (_) => '[REDACTED_PHONE]',
    ),
  ];

  /// Masks tokens, keys, URL queries, e-mails, CPFs and phone numbers.
  static String redact(String input) {
    var result = input;
    for (final (pattern, replace) in _rules) {
      result = result.replaceAllMapped(pattern, replace);
    }
    return result;
  }

  /// Short, sanitized description of [error] suitable for the log file.
  ///
  /// [DioException]s are reduced to type, status and path (never headers or
  /// bodies), mirroring `authDebugLog`.
  static String describeError(Object error) {
    final description = switch (error) {
      DioException(:final type, :final response, :final requestOptions) =>
        'DioException(type=${type.name}, status=${response?.statusCode}, '
            '${requestOptions.method} ${requestOptions.uri.path})',
      _ => '${error.runtimeType}: $error',
    };
    return truncate(redact(description), maxErrorLength);
  }

  /// Sanitized stack trace limited to [maxLines] frames.
  static String describeStack(StackTrace stackTrace, {int maxLines = 40}) {
    final lines = stackTrace.toString().trimRight().split('\n');
    final kept = lines.take(maxLines).join('\n');
    final suffix = lines.length > maxLines
        ? '\n... (${lines.length - maxLines} more frames)'
        : '';
    return redact('$kept$suffix');
  }

  @visibleForTesting
  static String truncate(String value, int maxLength) =>
      value.length <= maxLength
      ? value
      : '${value.substring(0, maxLength)}... (truncated)';
}
