import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';
import '../auth_pvt_test.dart';

class MockSecurityStorageWithBoundId extends MockSecurityStorage {
  @override
  Future<String> getBoundDeviceId() async {
    return storage['bound_device_id'] ?? 'new-uuid';
  }
}

class MockDioSuccess extends MockDio {
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
      data: {
        'accessToken': 'at',
        'refreshToken': 'rt',
        'tokenType': 'Bearer',
        'expiresIn': 3600,
        'refreshExpiresIn': 86400,
      } as T,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('dev.fluttercommunity.plus/package_info');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{
            'appName': 'flutter_workshop_front',
            'packageName': 'com.example.flutter_workshop_front',
            'version': '1.1.1',
            'buildNumber': '1',
          };
        }
        return null;
      },
    );
  });

  group('BoundDeviceId Unit Tests', () {
    late MockSecurityStorageWithBoundId storage;
    late AuthService authService;

    setUp(() {
      storage = MockSecurityStorageWithBoundId();
      authService = AuthService(
        dio: MockDioSuccess(),
        storage: storage,
        authNotifier: AuthNotifier(),
      );
    });

    test('Should use boundDeviceId in TokenRequest', () async {
      storage.storage['bound_device_id'] = 'test-bound-id';

      await authService.authenticate('some-api-key');
    });
  });
}
