import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/config/config.dart';
import 'package:flutter_workshop_front/core/http/interceptors/duplicate_request_interceptor.dart';

class CustomDio {
  static Dio dioInstance() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Config.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        validateStatus: (status) => status! < 500,
      ),
    );

    dio.interceptors.add(DuplicateRequestInterceptor());

    return dio;
  }
}
