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

  _FixedAdapter(
    this.status,
    this.body, {
    this.contentType = 'application/json',
  });

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
    )
    ..httpClientAdapter = _FixedAdapter(
      status,
      body,
      contentType: contentType ?? 'application/json',
    );
}

void main() {
  group('requisitionExceptionFromResponse', () {
    test('corpo padrão da API preserva mensagem e código', () async {
      final body = jsonEncode({
        'status': 400,
        'error': {
          'message': 'Valor do pagamento inválido',
          'code': 'BAD_REQUEST',
        },
      });
      final response = await _dioReturning(
        400,
        body,
      ).post<dynamic>('/v1/payment');

      final exception = requisitionExceptionFromResponse(response);

      expect(exception.message, 'Valor do pagamento inválido');
      expect(exception.code, 'BAD_REQUEST');
    });

    test('corpo em texto cai na mensagem genérica com o status', () async {
      final response = await _dioReturning(
        422,
        'Unprocessable',
        contentType: 'text/plain',
      ).get<dynamic>('/v1/colors');

      final exception = requisitionExceptionFromResponse(response);

      expect(exception.message, contains('422'));
      expect(exception.code, '422');
    });

    test('404 sem corpo não lança', () async {
      final response = await _dioReturning(
        404,
        '',
      ).get<dynamic>('/v1/technician');

      expect(
        requisitionExceptionFromResponse(response),
        isA<RequisitionException>(),
      );
    });
  });
}
