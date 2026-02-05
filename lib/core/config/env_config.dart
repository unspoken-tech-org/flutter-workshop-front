import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  EnvConfig._();

  static String get githubOwner => dotenv.env['GITHUB_OWNER'] ?? '';
  static String get githubRepo => dotenv.env['GITHUB_REPO'] ?? '';
}
