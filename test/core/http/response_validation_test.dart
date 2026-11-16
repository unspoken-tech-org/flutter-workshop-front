import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/core/http/response_validation.dart';

/// Adapter que devolve sempre a mesma resposta, sem rede.
class _FixedAdapter implements HttpClientAdapter {
  final int status;
  final String body;
  final String contentType;

  _FixedAdapter(this.status, this.body, {this.contentType = 'application/json'});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Mesmo validateStatus do CustomDio: 4xx (exceto 401/403) chega como sucesso.
Dio _dioReturning(int status, String body, {String? contentType}) {
  return Dio(
    BaseOptions(
      baseUrl: 'https://test.example.com',
      validateStatus: (status) =>
          status! < 500 && status != 401 && status != 403,
    ),
  )..httpClientAdapter = _FixedAdapter(
      status,
      body,
      contentType: contentType ?? 'application/json',
    );
}

void main() {
  group('ResponseValidation.ensureSuccess', () {
    test('retorna a resposta em 2xx', () async {
      final response = await _dioReturning(201, '{"id": 1}').post('/x');

      expect(response.ensureSuccess(), same(response));
    });

    test('4xx com corpo padrão da API lança RequisitionException com a mensagem',
        () async {
      final body = jsonEncode({
        'status': 400,
        'error': {'message': 'Valor do pagamento inválido', 'code': 'BAD_REQUEST'},
      });
      final response = await _dioReturning(400, body).post('/v1/payment');

      expect(
        () => response.ensureSuccess(),
        throwsA(
          isA<RequisitionException>()
              .having((e) => e.message, 'message', 'Valor do pagamento inválido')
              .having((e) => e.code, 'code', 'BAD_REQUEST'),
        ),
      );
    });

    test('429 com corpo em texto lança RequisitionException genérica', () async {
      final response = await _dioReturning(
        429,
        'Too Many Requests',
        contentType: 'text/plain',
      ).get('/v1/colors');

      expect(
        () => response.ensureSuccess(),
        throwsA(
          isA<RequisitionException>()
              .having((e) => e.message, 'message', contains('429'))
              .having((e) => e.code, 'code', '429'),
        ),
      );
    });

    test('404 sem corpo lança RequisitionException', () async {
      final response = await _dioReturning(404, '').get('/v1/technician');

      expect(() => response.ensureSuccess(), throwsA(isA<RequisitionException>()));
    });
  });
}
