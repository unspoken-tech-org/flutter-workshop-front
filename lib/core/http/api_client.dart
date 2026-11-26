import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/http/interceptors/global_error_interceptor.dart';
import 'package:flutter_workshop_front/core/http/response_validation.dart';
import 'package:flutter_workshop_front/core/logging/app_logger.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/core/security/refresh_result.dart';

/// Ponto único de saída das chamadas HTTP dos services.
///
/// Declara o status esperado, decodifica o corpo e converte qualquer falha
/// (status inesperado, corpo de erro da API, rede, timeout, decode) em
/// [AppFailure], sem lançar exceção.
///
/// Toda falha é registrada no [AppLogger] (arquivo + console em debug) com
/// método, path, status e `error.code` da API — nunca corpo de requisição ou
/// resposta (dados de cliente) nem tokens.
class ApiClient {
  static const _tag = 'ApiClient';

  ApiClient(this._dio);

  final Dio _dio;

  /// Executa [call] e devolve `Ok(decode(body))` se o status estiver em
  /// [expectedStatus]; do contrário, `Err` com a falha classificada.
  Future<Result<T>> send<T>(
    Future<Response<dynamic>> Function(Dio dio) call, {
    required T Function(Object? data) decode,
    Set<int> expectedStatus = const {200},
  }) async {
    final Response<dynamic> response;
    try {
      response = await call(_dio);
    } on DioException catch (e) {
      final failure = _markShownGlobally(
        _fromDioException(e),
        shown:
            e.requestOptions.extra[GlobalErrorInterceptor.shownGloballyKey] ==
            true,
      );
      _logDioFailure(e, failure);
      return Err(failure);
    } catch (e, stackTrace) {
      AppLogger.error(
        _tag,
        'Request failed before a response',
        error: e,
        stackTrace: stackTrace,
      );
      return Err(UnexpectedFailure(cause: e));
    }

    final status = response.statusCode ?? 0;
    if (!expectedStatus.contains(status)) {
      final failure = _fromStatus(response);
      AppLogger.warning(
        _tag,
        _describeFailure(
          response.requestOptions,
          failure,
          status: status,
          code: _apiErrorCode(response),
        ),
      );
      return Err(failure);
    }

    try {
      return Ok(decode(response.data));
    } catch (e, stackTrace) {
      final options = response.requestOptions;
      AppLogger.error(
        _tag,
        'Decode failed: ${options.method} ${options.uri.path} status=$status',
        error: _withoutSource(e),
        stackTrace: stackTrace,
      );
      return Err(
        UnexpectedFailure(
          message: 'Resposta fora do formato esperado.',
          cause: e,
        ),
      );
    }
  }

  void _logDioFailure(DioException e, AppFailure failure) {
    final response = e.response;
    final message = _describeFailure(
      e.requestOptions,
      failure,
      status: response?.statusCode,
      code: _apiErrorCode(response),
      type: e.type,
      cause: e.error,
    );
    if (e.type == DioExceptionType.cancel) {
      // Cancelamento é intencional (ex.: logout): não é falha a investigar.
      AppLogger.debug(_tag, message);
    } else {
      AppLogger.warning(_tag, message);
    }
  }

  /// Linha única: `GET /path -> ValidationFailure status=400 code=X`.
  String _describeFailure(
    RequestOptions options,
    AppFailure failure, {
    int? status,
    String? code,
    DioExceptionType? type,
    Object? cause,
  }) {
    final buffer = StringBuffer()
      ..write('${options.method} ${options.uri.path} -> ')
      ..write(failure.runtimeType);
    if (status != null) buffer.write(' status=$status');
    if (code != null) buffer.write(' code=$code');
    if (type != null) buffer.write(' type=${type.name}');
    if (cause != null) buffer.write(' cause=${cause.runtimeType}');
    return buffer.toString();
  }

  /// Código de erro da API (`error.code` legado ou `code` na raiz em
  /// `ProblemDetail`), se o corpo o trouxer.
  String? _apiErrorCode(Response<dynamic>? response) =>
      apiErrorCodeFromResponse(response);

  /// `FormatException.toString()` inclui o trecho de entrada (`source`), que
  /// pode ser dado de cliente; mantém só a mensagem.
  Object _withoutSource(Object error) =>
      error is FormatException ? FormatException(error.message) : error;

  AppFailure _markShownGlobally(AppFailure failure, {required bool shown}) {
    if (!shown) return failure;
    return switch (failure) {
      NetworkFailure(:final cause) => NetworkFailure(
        cause: cause,
        shownGlobally: true,
      ),
      RateLimitedFailure(:final message, :final retryAfter) =>
        RateLimitedFailure(
          message: message,
          retryAfter: retryAfter,
          shownGlobally: true,
        ),
      ServerFailure(:final statusCode, :final message) => ServerFailure(
        statusCode: statusCode,
        message: message,
        shownGlobally: true,
      ),
      _ => failure,
    };
  }

  AppFailure _fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return NetworkFailure(cause: e);
      case DioExceptionType.badResponse:
        final response = e.response;
        if (response != null) return _fromStatus(response);
        return UnexpectedFailure(cause: e);
      case DioExceptionType.cancel:
        return UnexpectedFailure(cause: e);
      case DioExceptionType.unknown:
        final error = e.error;
        if (error is SocketException ||
            error is HttpException ||
            error is SessionRefreshUnavailable) {
          return NetworkFailure(cause: e);
        }
        final response = e.response;
        if (response != null) return _fromStatus(response);
        return UnexpectedFailure(cause: e);
    }
  }

  AppFailure _fromStatus(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    final error = requisitionExceptionFromResponse(response);

    if (status == 401 || status == 403) {
      return SessionFailure(statusCode: status, code: error.code);
    }
    if (status == 429) {
      return RateLimitedFailure(
        message: error.message,
        retryAfter: _retryAfter(response),
      );
    }
    if (status >= 500) {
      return ServerFailure(statusCode: status, message: error.message);
    }
    if (status >= 400) {
      return switch (status) {
        404 => NotFoundFailure(
          message: error.message,
          code: error.code,
          statusCode: status,
        ),
        409 => ConflictFailure(
          message: error.message,
          code: error.code,
          statusCode: status,
        ),
        _ => ValidationFailure(
          message: error.message,
          code: error.code,
          statusCode: status,
        ),
      };
    }
    return UnexpectedFailure(message: 'Status inesperado ($status).');
  }

  Duration? _retryAfter(Response<dynamic> response) {
    final raw = response.headers.value('retry-after');
    final seconds = raw == null ? null : int.tryParse(raw.trim());
    return seconds == null || seconds < 0 ? null : Duration(seconds: seconds);
  }
}

/// Corpo JSON objeto; lança `TypeError` (vira `UnexpectedFailure`) se não for.
Map<String, dynamic> asJsonMap(Object? data) => data! as Map<String, dynamic>;

/// Lista JSON mapeada com [fromJson].
List<T> parseList<T>(
  Object? data,
  T Function(Map<String, dynamic> json) fromJson,
) {
  return (data! as List<dynamic>)
      .map((e) => fromJson(e as Map<String, dynamic>))
      .toList();
}
