import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Config {
  static String get baseUrl => dotenv.get('BASE_URL');

  static String get apiKey => dotenv.get('API_KEY', fallback: '');

  static String get devApiKey => dotenv.get('DEV_API_KEY', fallback: '');

  static Future<String> get appVersion async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
