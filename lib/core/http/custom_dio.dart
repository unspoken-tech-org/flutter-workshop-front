import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/config/config.dart';
import 'package:flutter_workshop_front/core/http/interceptors/duplicate_request_interceptor.dart';
import 'package:flutter_workshop_front/core/http/interceptors/global_error_interceptor.dart';
import 'package:flutter_workshop_front/core/http/interceptors/security_interceptor.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/core/security/security_storage.dart';

class CustomDio {
  static SecurityStorage? _storage;
  static Future<String?> Function()? _onRefresh;
  static AuthNotifier? _authNotifier;

  /// Configures global dependencies for the security interceptor.
  static void setup(
    SecurityStorage storage,
    Future<String?> Function() onRefresh,
    AuthNotifier authNotifier,
  ) {
    _storage = storage;
    _onRefresh = onRefresh;
    _authNotifier = authNotifier;
  }

  static Dio dioInstance() {
    final dio = _baseDio();

    if (_storage != null && _onRefresh != null && _authNotifier != null) {
      dio.interceptors.add(
        SecurityInterceptor(
          storage: _storage!,
          dio: dio,
          onRefresh: _onRefresh!,
          authNotifier: _authNotifier!,
        ),
      );
    }

    // GlobalErrorInterceptor must be added last to process final errors
    dio.interceptors.add(GlobalErrorInterceptor());

    return dio;
  }

  /// Dedicated instance for authentication, avoiding interceptor loops.
  static Dio authDioInstance() {
    return _baseDio()..interceptors.add(GlobalErrorInterceptor());
  }

  static Dio _baseDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Config.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        validateStatus: (status) {
          return status! < 500 && status != 401 && status != 403;
        },
      ),
    );

    dio.interceptors.add(DuplicateRequestInterceptor());

    return dio;
  }
}
