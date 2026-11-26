import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef StubResponseHandler =
    Future<ResponseBody> Function(RequestOptions options);

/// [HttpClientAdapter] de teste com registro das requisições enviadas.
class StubHttpClientAdapter implements HttpClientAdapter {
  StubHttpClientAdapter(this._handler);

  factory StubHttpClientAdapter.fixed({
    int status = 200,
    String body = '{}',
    String contentType = Headers.jsonContentType,
    Map<String, List<String>> headers = const {},
  }) {
    return StubHttpClientAdapter((_) async {
      return ResponseBody.fromString(
        body,
        status,
        headers: {
          Headers.contentTypeHeader: [contentType],
          ...headers,
        },
      );
    });
  }

  factory StubHttpClientAdapter.json({
    int status = 200,
    Object? data = const <String, Object?>{},
    Map<String, List<String>> headers = const {},
  }) {
    return StubHttpClientAdapter.fixed(
      status: status,
      body: jsonEncode(data),
      headers: headers,
    );
  }

  final StubResponseHandler _handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Cria um [Dio] configurado com [adapter] para testes sem rede.
Dio testDio(
  HttpClientAdapter adapter, {
  String baseUrl = 'https://test.example.com',
  bool Function(int?)? validateStatus,
}) {
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      validateStatus:
          validateStatus ??
          (status) =>
              status != null && status < 500 && status != 401 && status != 403,
    ),
  )..httpClientAdapter = adapter;
}
