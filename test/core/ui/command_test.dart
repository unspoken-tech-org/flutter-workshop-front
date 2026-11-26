import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/core/ui/command.dart';

void main() {
  group('Command', () {
    test('começa ociosa, sem resultado e sem erro', () {
      final command = Command<int, int>((n) async => Ok(n));

      expect(command.running, isFalse);
      expect(command.result, isNull);
      expect(command.error, isNull);
    });

    test('running fica true durante a ação e o resultado é guardado', () async {
      final blocker = Completer<Result<int>>();
      final command = Command<int, int>((_) => blocker.future);
      final states = <bool>[];
      command.addListener(() => states.add(command.running));

      final pending = command.execute(1);
      expect(command.running, isTrue);

      blocker.complete(const Ok(7));
      final result = await pending;

      expect(result, isA<Ok<int>>());
      expect((command.result as Ok<int>).value, 7);
      expect(command.running, isFalse);
      expect(states, [true, false]);
    });

    test('falha fica em result/error e limpa na próxima execução', () async {
      var fail = true;
      final blocker = Completer<Result<int>>();
      final command = Command<int, int>(
        (_) =>
            fail ? Future.value(const Err(NetworkFailure())) : blocker.future,
      );

      await command.execute(0);
      expect(command.error, isA<NetworkFailure>());

      fail = false;
      final pending = command.execute(0);
      expect(command.result, isNull);
      expect(command.error, isNull);
      blocker.complete(const Ok(1));
      await pending;
    });

    test('segunda execução durante a primeira é ignorada', () async {
      final blocker = Completer<Result<int>>();
      var calls = 0;
      final command = Command<int, int>((_) {
        calls++;
        return blocker.future;
      });

      final first = command.execute(0);
      final second = await command.execute(0);

      expect(second, isNull);
      expect(calls, 1);
      blocker.complete(const Ok(1));
      await first;
    });

    test('running volta a false mesmo quando a ação lança', () async {
      final command = Command<int, int>((_) => throw StateError('boom'));

      await expectLater(command.execute(0), throwsStateError);

      expect(command.running, isFalse);
    });
  });
}
