import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/core/http/response_validation.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';

/// Ponto único de saída das chamadas HTTP dos services.
///
/// Declara o status esperado, decodifica o corpo e converte qualquer falha
/// (status inesperado, corpo de erro da API, rede, timeout, decode) em
/// [AppFailure], sem lançar exceção.
class ApiClient {
  ApiClient({Dio? dio}) : _dioOverride = dio;

  final Dio? _dioOverride;

  Dio get _dio => _dioOverride ?? CustomDio.dioInstance();

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
      return Err(_fromDioException(e));
    } catch (e) {
      return Err(UnexpectedFailure(cause: e));
    }

    final status = response.statusCode ?? 0;
    if (!expectedStatus.contains(status)) {
      return Err(_fromStatus(response));
    }

    try {
      return Ok(decode(response.data));
    } catch (e) {
      return Err(
        UnexpectedFailure(
          message: 'Resposta fora do formato esperado.',
          cause: e,
        ),
      );
    }
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
        if (error is SocketException || error is HttpException) {
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
