import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/http/api_client.dart';
import 'package:flutter_workshop_front/core/money/money.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';
import 'package:flutter_workshop_front/models/customer_device/input_payment.dart';
import 'package:flutter_workshop_front/services/payment/payment_service.dart';
import 'package:flutter_workshop_front/services/technician/technician_service.dart';

class _FixedAdapter implements HttpClientAdapter {
  _FixedAdapter(this.status, this.body);

  final int status;
  final String body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _client(_FixedAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://test.example.com',
      validateStatus: (s) => s! < 500 && s != 401 && s != 403 && s != 429,
    ),
  )..httpClientAdapter = adapter;
  return ApiClient(dio);
}

InputPayment _payment() => InputPayment(
  deviceId: 1,
  value: const Money.fromCents(1000),
  paymentType: PaymentType.pix,
  category: PaymentCategory.service,
  paymentDate: DateTime(2026),
);

void main() {
  group('PaymentService', () {
    test('201 devolve Ok e envia o corpo no endpoint de pagamento', () async {
      final adapter = _FixedAdapter(201, '{"paymentId":9}');
      final service = PaymentService(_client(adapter));

      final result = await service.createPayment(_payment());

      expect(result, isA<Ok<void>>());
      expect(adapter.last?.path, '/v1/payment');
      expect(adapter.last?.method, 'POST');
    });

    test('400 não é tratado como sucesso e preserva a mensagem', () async {
      final adapter = _FixedAdapter(
        400,
        '{"error":{"code":"payment.invalid","message":"Pagamento recusado"}}',
      );
      final service = PaymentService(_client(adapter));

      final result = await service.createPayment(_payment());

      expect(result, isA<Err<void>>());
      final failure = (result as Err<void>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(failure.messageOr('fallback'), 'Pagamento recusado');
    });
  });

  group('TechnicianService', () {
    test('decodifica a lista em caso de 200', () async {
      final adapter = _FixedAdapter(
        200,
        '[{"id":1,"name":"Ana","number":"11999999999"}]',
      );
      final service = TechnicianService(_client(adapter));

      final result = await service.getTechnicians();

      expect(result.valueOrNull?.single.name, 'Ana');
    });

    test('corpo que não é lista vira UnexpectedFailure', () async {
      final adapter = _FixedAdapter(200, '{"oops":true}');
      final service = TechnicianService(_client(adapter));

      final result = await service.getTechnicians();

      expect((result as Err).failure, isA<UnexpectedFailure>());
    });

    test('500 vira ServerFailure', () async {
      final adapter = _FixedAdapter(500, '{}');
      final service = TechnicianService(_client(adapter));

      final result = await service.getTechnicians();

      expect((result as Err).failure, isA<ServerFailure>());
    });
  });
}
