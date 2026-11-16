import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Valores de build via --dart-define(-from-file); nenhum arquivo .env entra no bundle.
class Config {
  static String get baseUrl => const String.fromEnvironment('BASE_URL');

  static String get apiKey => const String.fromEnvironment('API_KEY');

  // Só existe em debug: num build release a chave nunca entra no binário.
  static String get devApiKey =>
      kDebugMode ? const String.fromEnvironment('DEV_API_KEY') : '';

  static Future<String> get appVersion async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
