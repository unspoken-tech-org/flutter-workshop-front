import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
  static Dio? _appDio;
  static Dio? _authDio;
  static bool _securityAttached = false;

  /// Configures global dependencies for the security interceptor.
  static void setup(
    SecurityStorage storage,
    Future<String?> Function() onRefresh,
    AuthNotifier authNotifier,
  ) {
    _storage = storage;
    _onRefresh = onRefresh;
    _authNotifier = authNotifier;

    if (_appDio != null) {
      _ensureSecurityInterceptor(_appDio!);
    }
  }

  static Dio dioInstance() {
    if (_appDio == null) {
      _appDio = _baseDio();
      _ensureSecurityInterceptor(_appDio!);

      // GlobalErrorInterceptor must be added last to process final errors
      _appDio!.interceptors.add(GlobalErrorInterceptor());
    }

    return _appDio!;
  }

  /// Dedicated instance for authentication, avoiding interceptor loops.
  static Dio authDioInstance() {
    _authDio ??= _baseDio()..interceptors.add(GlobalErrorInterceptor());
    return _authDio!;
  }

  @visibleForTesting
  static void resetForTest() {
    _storage = null;
    _onRefresh = null;
    _authNotifier = null;
    _appDio = null;
    _authDio = null;
    _securityAttached = false;
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

  static void _ensureSecurityInterceptor(Dio dio) {
    if (_securityAttached) {
      return;
    }

    if (_storage == null || _onRefresh == null || _authNotifier == null) {
      return;
    }

    final securityInterceptor = SecurityInterceptor(
      storage: _storage!,
      dio: dio,
      onRefresh: _onRefresh!,
      authNotifier: _authNotifier!,
    );

    final globalErrorIndex = dio.interceptors
        .indexWhere((interceptor) => interceptor is GlobalErrorInterceptor);
    if (globalErrorIndex >= 0) {
      dio.interceptors.insert(globalErrorIndex, securityInterceptor);
    } else {
      dio.interceptors.add(securityInterceptor);
    }
    _securityAttached = true;
  }
}
