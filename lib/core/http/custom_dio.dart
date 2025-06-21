import 'package:dio/dio.dart';

class CustomDio {
  static Dio dioInstance() => Dio(
        BaseOptions(
          baseUrl: 'http://localhost:8080',
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          validateStatus: (status) => status! < 500,
        ),
      );
}
