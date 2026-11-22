import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/security/auth_debug_log.dart';

void main() {
  group('authDebugLog', () {
    test('redacts DioException headers, tokens, and URLs', () {
      final logged = <String>[];
      final previousDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logged.add(message);
      };
      addTearDown(() => debugPrint = previousDebugPrint);

      final requestOptions = RequestOptions(
        path: '/api/auth/refresh',
        headers: {'Authorization': 'Bearer super-secret-jwt'},
        data: {'refreshToken': 'super-secret-refresh'},
      );
      final err = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );

      authDebugLog('Refresh failed', requestId: 'req-1', error: err);

      expect(logged, hasLength(1));
      expect(
        logged.single,
        '[AuthDebug][req-1] Refresh failed: DioException(type=DioExceptionType.badResponse, status=401)',
      );
      expect(logged.single, isNot(contains('super-secret')));
    });
  });
}
