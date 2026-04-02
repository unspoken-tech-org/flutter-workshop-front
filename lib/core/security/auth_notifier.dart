import 'package:flutter/foundation.dart';

enum AuthRouteState {
  restoring,
  authenticated,
  needsSetup,
}

class AuthNotifier extends ChangeNotifier {
  AuthRouteState _state;

  AuthNotifier({AuthRouteState initialState = AuthRouteState.restoring})
      : _state = initialState;

  AuthRouteState get state => _state;

  void setState(AuthRouteState state, {bool notify = true}) {
    final changed = _state != state;
    _state = state;
    if (notify && changed) {
      notifyListeners();
    }
  }
}
