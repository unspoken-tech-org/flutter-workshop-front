import 'support/memory_security_storage.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';

class MockDio implements Dio {
  @override
  Interceptors get interceptors => Interceptors();

  @override
  HttpClientAdapter get httpClientAdapter => IOHttpClientAdapter();

  @override
  BaseOptions options = BaseOptions();

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: <String, dynamic>{} as T,
    );
  }

  @override
  Future<Response<T>> fetch<T>(RequestOptions requestOptions) async {
    return Response(
      requestOptions: requestOptions,
      statusCode: 200,
      data: <String, dynamic>{} as T,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

void main() {
  group('PVT - Auth Logic Validation', () {
    late MemorySecurityStorage storage;

    late AuthService authService;

    setUp(() {
      storage = MemorySecurityStorage(boundDeviceIdFallback: 'test-bound-id');

      authService = AuthService(
        dio: MockDio(),
        storage: storage,
        authNotifier: AuthNotifier(),
      );
    });

    test(
      'AuthService: Should identify ADMIN correctly via JWT (Simulated)',
      () async {
        // Simulated Token JWT (payload base64) with ADMIN role

        // Header: {"alg":"HS256","typ":"JWT"} -> eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9

        // Payload: {"roles":["ADMIN"],"exp":9999999999} -> eyJyb2xlcyI6WyJBRE1JTiJdLCJleHAiOjk5OTk5OTk5OTl9.signature

        const adminToken =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlcyI6WyJBRE1JTiJdLCJleHAiOjk5OTk5OTk5OTl9.signature';

        await storage.saveAccessToken(adminToken);

        expect(await authService.isAdmin, isTrue);
      },
    );

    test('AuthService: Should identify standard USER correctly', () async {
      // Payload: {"roles":["USER"],"exp":9999999999}

      const userToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlcyI6WyJVU0VSIl0sImV4cCI6OTk5OTk5OTk5OX0.signature';

      await storage.saveAccessToken(userToken);

      expect(await authService.isAdmin, isFalse);
    });

    test('Logout Flow: Should clear session tokens and api key', () async {
      await storage.saveApiKey('123');

      await storage.saveTokens('abc', 'def');

      expect(await storage.getApiKey(), isNotNull);

      await authService.logout();

      expect(await storage.getApiKey(), isNull);

      expect(await storage.getAccessToken(), isNull);
    });
  });
}
