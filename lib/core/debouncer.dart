import 'dart:async';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  /// Execute the [callback] after the defined time.
  /// If the method is called again before the time expires,
  /// the previous execution will be canceled.
  void run(Function callback) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), () {
      callback();
    });
  }

  /// Cancels the debounce in progress, if any.
  void cancel() {
    _timer?.cancel();
  }

  /// Verify if there is an active debounce operation.
  bool get isActive => _timer?.isActive ?? false;
}
