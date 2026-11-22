import 'package:flutter/foundation.dart';

/// Prevents `notifyListeners()` from throwing when async work completes after
/// the controller has been disposed.
mixin SafeChangeNotifierMixin on ChangeNotifier {
  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
