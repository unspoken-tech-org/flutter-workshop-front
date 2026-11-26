import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/state/safe_change_notifier_mixin.dart';
import 'package:flutter_workshop_front/core/ui/ui_message.dart';

import '../../support/ui_message_recorder.dart';

class _Source extends ChangeNotifier
    with SafeChangeNotifierMixin, UiMessageSource {
  void ok() => emitSuccess('feito');
  void fail() => emitError('falhou');
}

void main() {
  group('UiMessageSource', () {
    test('publica sucesso e erro na ordem, de forma síncrona', () {
      final source = _Source();
      final messages = recordMessages(source);

      source
        ..ok()
        ..fail();

      expect(messages, [isUiSuccess('feito'), isUiError('falhou')]);
    });

    test('emitir depois do dispose não lança', () {
      final source = _Source()..dispose();

      expect(source.fail, returnsNormally);
    });
  });

  group('UiMessageBus', () {
    test('entrega a todos os ouvintes e ignora publish após dispose', () async {
      final bus = UiMessageBus();
      final a = recordMessages(bus);
      final b = recordMessages(bus);

      bus.publish(const UiError('x'));
      await bus.dispose();
      bus.publish(const UiError('y'));

      expect(a, [isUiError('x')]);
      expect(b, [isUiError('x')]);
    });
  });
}
