import 'dart:convert';
import 'package:dio/dio.dart';

class DuplicateRequestInterceptor extends Interceptor {
  final int milliseconds;

  final Map<String, DateTime> _requestCache = {};

  DuplicateRequestInterceptor({this.milliseconds = 500});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requestHash = _generateRequestHash(options);

    final now = DateTime.now();
    final lastRequestTime = _requestCache[requestHash];

    if (lastRequestTime != null) {
      final timeDifference = now.difference(lastRequestTime).inMilliseconds;

      if (timeDifference < milliseconds) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: 'Requisição duplicada detectada. '
                'Aguarde ${milliseconds}ms entre requisições idênticas.',
          ),
          true,
        );
        return;
      }
    }

    _requestCache[requestHash] = now;

    _cleanOldEntries(now);

    handler.next(options);
  }

  String _generateRequestHash(RequestOptions options) {
    final buffer = StringBuffer();

    // Adiciona método HTTP
    buffer.write(options.method);
    buffer.write(':');

    // Adiciona o path completo da URL
    buffer.write(options.uri.toString());
    buffer.write(':');

    if (options.data != null) {
      try {
        final dataString = jsonEncode(options.data);
        buffer.write(dataString);
      } catch (e) {
        buffer.write(options.data.toString());
      }
    }

    return buffer.toString().hashCode.toString();
  }

  void _cleanOldEntries(DateTime now) {
    final threshold = milliseconds * 2;
    _requestCache.removeWhere((key, time) {
      final age = now.difference(time).inMilliseconds;
      return age > threshold;
    });
  }

  void clearCache() {
    _requestCache.clear();
  }
}
