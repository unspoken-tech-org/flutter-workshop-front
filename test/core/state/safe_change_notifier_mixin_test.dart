import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/state/safe_change_notifier_mixin.dart';

class _TestController extends ChangeNotifier with SafeChangeNotifierMixin {
  int value = 0;

  void increment() {
    value++;
    notifyListeners();
  }
}

void main() {
  group('SafeChangeNotifierMixin', () {
    test('notifies listeners while active and ignores after dispose', () {
      final controller = _TestController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.increment();
      expect(notifications, 1);
      expect(controller.isDisposed, isFalse);

      controller.dispose();
      expect(controller.isDisposed, isTrue);

      expect(() => controller.increment(), returnsNormally);
      expect(notifications, 1);
    });
  });
}
