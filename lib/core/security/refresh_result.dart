import 'package:dio/dio.dart';

sealed class RefreshResult {
  const RefreshResult();
}

final class RefreshSuccess extends RefreshResult {
  final String accessToken;

  const RefreshSuccess(this.accessToken);
}

final class RefreshSessionExpired extends RefreshResult {
  const RefreshSessionExpired();
}

final class RefreshTransientFailure extends RefreshResult {
  final DioExceptionType errorType;
  final Response<dynamic>? response;
  final Object? error;

  const RefreshTransientFailure({
    required this.errorType,
    this.response,
    this.error,
  });
}
