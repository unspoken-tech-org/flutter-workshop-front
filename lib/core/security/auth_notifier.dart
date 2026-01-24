import 'package:flutter/foundation.dart';

class AuthNotifier extends ChangeNotifier {
  static final AuthNotifier _instance = AuthNotifier._internal();

  factory AuthNotifier() {
    return _instance;
  }

  AuthNotifier._internal();

  void notifyAuthChange() {
    notifyListeners();
  }
}
