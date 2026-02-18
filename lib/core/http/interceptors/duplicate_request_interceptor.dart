import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

class DuplicateRequestInterceptor extends Interceptor {
  final int milliseconds;
  static const _kIsAuthRetry = 'isAuthRetry';
  static const _kBypassDuplicateCheck = 'bypassDuplicateCheck';
  static const _kRequestHash = 'duplicateRequestHash';
  static const _kRequestCompleter = 'duplicateRequestCompleter';

  final Map<String, _InFlightRequest> _inFlightRequests = {};
  final Map<String, _RecentResponse> _recentResponses = {};

  DuplicateRequestInterceptor({this.milliseconds = 500});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final shouldBypass = options.extra[_kIsAuthRetry] == true ||
        options.extra[_kBypassDuplicateCheck] == true;

    if (shouldBypass) {
      handler.next(options);
      return;
    }

    final requestHash = _generateRequestHash(options);
    final now = DateTime.now();
    final inFlight = _inFlightRequests[requestHash];

    if (inFlight != null &&
        now.difference(inFlight.startedAt).inMilliseconds < milliseconds) {
      inFlight.waiters += 1;
      try {
        final response = await inFlight.completer.future;
        handler.resolve(_cloneResponseForRequest(response, options));
      } on DioException catch (e) {
        handler.reject(_cloneDioExceptionForRequest(e, options));
      } catch (e) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.unknown,
            error: e,
          ),
        );
      }
      return;
    }

    final recentResponse = _recentResponses[requestHash];
    if (recentResponse != null &&
        now.difference(recentResponse.completedAt).inMilliseconds <
            milliseconds) {
      handler
          .resolve(_cloneResponseForRequest(recentResponse.response, options));
      return;
    }

    final completer = Completer<Response<dynamic>>();
    _inFlightRequests[requestHash] = _InFlightRequest(
      startedAt: now,
      completer: completer,
    );

    options.extra[_kRequestHash] = requestHash;
    options.extra[_kRequestCompleter] = completer;

    _cleanOldEntries(now);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final requestHash = response.requestOptions.extra[_kRequestHash] as String?;
    final completer = response.requestOptions.extra[_kRequestCompleter]
        as Completer<Response<dynamic>>?;

    if (completer != null && !completer.isCompleted) {
      completer.complete(response);
    }

    if (requestHash != null) {
      final inFlight = _inFlightRequests[requestHash];
      if (inFlight != null && identical(inFlight.completer, completer)) {
        _inFlightRequests.remove(requestHash);
      }

      _recentResponses[requestHash] = _RecentResponse(
        completedAt: DateTime.now(),
        response: _cloneResponseForRequest(response, response.requestOptions),
      );
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestHash = err.requestOptions.extra[_kRequestHash] as String?;
    final completer = err.requestOptions.extra[_kRequestCompleter]
        as Completer<Response<dynamic>>?;

    if (completer != null && !completer.isCompleted) {
      final inFlight =
          requestHash == null ? null : _inFlightRequests[requestHash];
      if (inFlight != null && inFlight.waiters > 0) {
        completer.completeError(err);
      }
    }

    if (requestHash != null) {
      final inFlight = _inFlightRequests[requestHash];
      if (inFlight != null && identical(inFlight.completer, completer)) {
        _inFlightRequests.remove(requestHash);
      }
    }

    handler.next(err);
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
    _inFlightRequests.removeWhere((_, value) {
      final age = now.difference(value.startedAt).inMilliseconds;
      return age > threshold && value.completer.isCompleted;
    });

    _recentResponses.removeWhere((_, value) {
      final age = now.difference(value.completedAt).inMilliseconds;
      return age > threshold;
    });
  }

  Response<dynamic> _cloneResponseForRequest(
    Response<dynamic> source,
    RequestOptions requestOptions,
  ) {
    return Response<dynamic>(
      requestOptions: requestOptions,
      data: source.data,
      headers: source.headers,
      isRedirect: source.isRedirect,
      redirects: source.redirects,
      statusCode: source.statusCode,
      statusMessage: source.statusMessage,
      extra: Map<String, dynamic>.from(source.extra),
    );
  }

  DioException _cloneDioExceptionForRequest(
    DioException source,
    RequestOptions requestOptions,
  ) {
    return DioException(
      requestOptions: requestOptions,
      response: source.response == null
          ? null
          : _cloneResponseForRequest(source.response!, requestOptions),
      type: source.type,
      error: source.error,
      stackTrace: source.stackTrace,
      message: source.message,
    );
  }

  void clearCache() {
    _inFlightRequests.clear();
    _recentResponses.clear();
  }
}

class _InFlightRequest {
  final DateTime startedAt;
  final Completer<Response<dynamic>> completer;
  int waiters = 0;

  _InFlightRequest({
    required this.startedAt,
    required this.completer,
  });
}

class _RecentResponse {
  final DateTime completedAt;
  final Response<dynamic> response;

  _RecentResponse({
    required this.completedAt,
    required this.response,
  });
}
