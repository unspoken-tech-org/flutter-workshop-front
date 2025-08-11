import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String get baseUrl => dotenv.get('BASE_URL');
}
