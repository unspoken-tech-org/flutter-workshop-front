import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import '../auth_pvt_test.dart';
import 'bound_device_id_test.dart';

class MockDioConflict extends MockDio {
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
      statusCode: 409,
      data: {
        'error': {
          'message': 'API Key já vinculada a outro dispositivo.',
          'code': 'DEVICE_BOUND'
        }
      } as dynamic,
    ) as Response<T>;
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
            'version': '1.1.1',
          };
        }
        return null;
      },
    );
  });

  group('Device Conflict Unit Tests', () {
    test('Should throw RequisitionException on 409 Conflict', () async {
      final authService = AuthService(
        dio: MockDioConflict(),
        storage: MockSecurityStorageWithBoundId(),
      );

      expect(
        () => authService.authenticate('some-key'),
        throwsA(isA<RequisitionException>()),
      );
    });
  });
}
