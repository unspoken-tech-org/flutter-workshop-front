import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/config/config.dart';

class CustomDio {
  static Dio dioInstance() => Dio(
        BaseOptions(
          baseUrl: Config.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          validateStatus: (status) => status! < 500,
        ),
      );
}
